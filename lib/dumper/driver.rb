# abstract driver that does everything
require 'dumper'
require 'dumper/util'
require 'logger'

module Dumper
  module Driver

    def find(driver)
      driver_file = "dumper/driver/#{driver}"
      require(driver_file)
      const_ar = driver.to_s.split("/").reject{|i| i==""}.collect {|i| i.capitalize.gsub(/_(.)/) {$1.upcase} }
      klass_str = const_ar.join('::')
      begin
        klass = const_ar.inject(self) do |mod, const_name|
          mod.const_get(const_name)
        end
      rescue NameError => e
        raise e
        raise BadConfig, "could not find `#{klass_str}' in `#{driver_file}'"
      end
      raise BadConfig, "#{klass.name} is not a type of Dumper::Driver!" unless klass < Dumper::Driver::Base
      return klass
    rescue LoadError
      raise BadConfig, "failed to load '#{driver_file}' !'"
    end

    module_function :find

    # abstract interface for all drivers
    class Base
      attr_reader :options
      attr_reader :host, :port, :user, :password, :database, :tables
      attr_reader :gzip, :gzip_options, :dumpdir, :dumpfile, :dump_options, :import_options
      attr_reader :destination, :destination_host, :destination_dumpfile

      def initialize(opts)
        self.configure(opts)
      end

      def configure(opts)
        opts = (@opts||{}).merge(opts)
        # db connection settings
        @host = opts[:host] || "localhost"
        @port = opts[:port]
        @user = opts[:user] or raise BadConfig.new ":user => <db user> is required"
        @password = (opts[:password]  || options[:pass]) or raise BadConfig.new ":pass => <db password> is required"
        # only allow dumping a single database at a time right now
        @database = (opts[:database] || opts[:db]) or raise BadConfig.new ":database => <db schema name> is required"
        @databases = [opts[:databases]].flatten.uniq.compact # not used/supported yet
        @tables = [opts[:table], opts[:tables]].flatten.uniq.compact # you can dump specific tables
        
        # dump settings
        @gzip = opts[:gzip].nil? ? true : opts[:gzip]
        @gzip_options = opts[:gzip_options] || "-9"
        @dumpdir = opts[:dumpdir] || "./"
        @dumpfile = (opts[:dumpfile] || opts[:filename]) || (@database + "_" + Time.now.to_i.to_s + ".sql")
        @dumpfile = @dumpfile[0].chr == "/" ? @dumpfile : File.join(@dumpdir, @dumpfile)
        @dumpfile.chomp!(".gz")
        # (optional) :destination is where dumps are exported to, and can be a remote host:path
        @destination = opts[:destination] || @dumpfile
        if @destination.include?(":")
          @destination_host, @destination_dumpfile = @destination.split(":")[0], @destination.split(":")[1]
        else
          @destination_host, @destination_dumpfile = "localhost", @destination
        end
        # destination might be a path only, so build the entire filepath
        if File.extname(@destination_dumpfile) == ""
          @destination_dumpfile = File.join(@destination_dumpfile, File.basename(@dumpfile))
        end
        @destination_dumpfile.chomp!(".gz")
        @dump_options = opts[:dump_options]
        @import_options = opts[:import_options]
        
        # set / update logger
        if opts[:logger]
          @logger = opts[:logger]
        elsif opts[:log_file]
          @logger = Logger.new(opts[:log_file])
        end
        @logger = Logger.new(STDOUT) if !@logger
        @logger.level = opts[:log_level] if opts[:log_level] # expects integer

        @opts = opts
      end

      def logger
        @logger
      end

      def dump_cmd
        raise BadConfig.new "#{self.class} has not defined dump_cmd!"
      end

      # DUMPING + EXPORTING

      def remote_destination?
        @destination_host && @destination_host != "localhost"
      end

      # creates @dumpfile
      # pipes :dump_cmd to gzip, rather than write the file to disk twice
      # if @destination is defined, it then moves the dump to the @destination, which can be a remote host:path
      def dump
        logger.debug("begin dump")
        dumpfn = @dumpfile + (@gzip ? ".gz" : "")
        Util.with_lockfile("localhost", dumpfn) do

          logger.debug "preparing dump..."
          if !File.exists?(File.dirname(dumpfn))
            run "mkdir -p #{File.dirname(dumpfn)}"
          end

          # avoid overwriting dump files..
          if File.exists?(dumpfn)
            if @opts[:force]
              logger.warn " #{dumpfn} exists, moving it to #{dumpfn}.1"
              run "rm -f #{dumpfn}.1; mv #{dumpfn} #{dumpfn}.1"
            else
              raise BusyDumping.new "#{dumpfn} already exists! Please move it or remove it"
            end
          end

          logger.debug "dumping..."
          if @gzip
            run "#{dump_cmd} | gzip #{gzip_options} > #{dumpfn}"
          else
            run "#{dump_cmd} > #{dumpfn}"
          end

          if @destination
            if remote_destination?
              logger.debug "exporting to #{@destination_host}..."
              Util.with_lockfile(@destination_host, @destination_dumpfile) do
                run "scp #{dumpfn} #{@destination_host}:#{@destination_dumpfile}#{@gzip ? '.gz' : ''}"
              end
            elsif @destination_dumpfile && @destination_dumpfile+(@gzip ? '.gz' : '') != dumpfn
              logger.debug "exporting..."
              destdir = File.dirname(@destination_dumpfile)
              run "mkdir -p #{destdir}" if !Util.dir_exists?("localhost", destdir)
              Util.with_lockfile("localhost", @destination_dumpfile) do
                run "mv #{dumpfn} #{@destination_dumpfile}#{@gzip ? '.gz' : ''}"
              end
            end
          end

        end # with_lockfile
        logger.debug("end dump")
      end

      # IMPORTING 

      def import_cmd
        raise BadConfig.new "#{self.class} has not defined import_cmd!"
      end

      def decompress
        if File.exists?(@dumpfile)
          logger.warn "skipping decompress because #{@dumpfile} already exists."
        elsif !File.exists?(@dumpfile + ".gz")
          raise "decompress failed. #{@dumpfile}.gz does not exist!"
        else
          logger.debug "decompressing..."
          run "gzip -d #{@dumpfile}.gz"
        end
      end

      def import
        Util.with_lockfile("localhost", @dumpfile) do
          decompress if @gzip

          logger.info "importing..."
          if !File.exists?(@dumpfile)
            raise "#{@dumpfile} does not exist! Did you export it?"
          else
            run import_cmd
          end
          
        end # with_lockfile
      end

      protected

      def run(cmd)
        start_time = Time.now
        logger.info "running command: #{cmd}"
        `#{cmd}`
        raise "Aborting because the following command failed!: #{cmd}" unless $?.success?
        logger.info "finished (took #{(Time.now - start_time).round()}s)"
      end

    end
  end
end
