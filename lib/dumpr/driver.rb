# abstract driver that does everything
require 'dumpr'
require 'dumpr/util'
require 'logger'

module Dumpr
  module Driver

    def find(driver)
      driver_file = "dumpr/driver/#{driver}"
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
      raise BadConfig, "#{klass.name} is not a type of Dumpr::Driver!" unless klass < Dumpr::Driver::Base
      return klass
    rescue LoadError
      raise BadConfig, "failed to load '#{driver_file}' !'"
    end

    module_function :find

    # abstract interface for all drivers
    class Base
      attr_reader :opts
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
        @user = opts[:user] or raise BadConfig.new "user is required"
        @password = (opts[:password]  || opts[:pass]) # or raise BadConfig.new "password is required"

        # dump all_databases or specific database(s)
        @all_databases = nil
        @database = nil
        @databases = nil
        @tables = nil
        if (opts[:database] || opts[:db])
          @database = (opts[:database] || opts[:db])
          @tables = [opts[:table], opts[:tables]].flatten.uniq.compact
        elsif opts[:databases]
          @databases = [opts[:databases]].flatten.uniq.compact # not used/supported yet
        elsif opts[:all_databases]
          @all_databases = true
        else
          #raise BadConfig.new "database is required"
        end

        # dump settings
        @gzip = opts[:gzip].nil? ? true : opts[:gzip]
        @gzip_options = opts[:gzip_options] || "-9"
        @dumpdir = opts[:dumpdir] || Dir.pwd #"./"
        @dumpfile = (opts[:file] || opts[:dumpfile] || opts[:filename]) or raise BadConfig.new "[file] is required"
        @dumpfile = @dumpfile.to_s.dup # this is frozen?
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

      def dump_installed?
        raise BadConfig.new "#{self.class} has not defined dump_installed?"
      end

      def import_installed?
        raise BadConfig.new "#{self.class} has not defined import_installed?"
      end

      def dump_cmd
        raise BadConfig.new "#{self.class} has not defined dump_cmd"
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
        if dump_installed? != true
          raise MissingDriver.new "#{self.class} does not appear to be installed.\nCould not find command `#{dump_cmd.to_s.split.first}`"
        end
        dumpfn = @dumpfile + (@gzip ? ".gz" : "")
        Util.with_lockfile("localhost", dumpfn, @opts[:force]) do

          logger.debug "preparing dump..."
          if !File.exist?(File.dirname(dumpfn))
            run "mkdir -p #{File.dirname(dumpfn)}"
          end

          # avoid overwriting dump files..
          if File.exist?(dumpfn)
            if @opts[:force]
              logger.warn "#{dumpfn} exists, moving it to #{dumpfn}.1"
              #run "rm -f #{dumpfn}.1;"
              run "mv #{dumpfn} #{dumpfn}.1"
            else
              logger.warn "#{dumpfn} already exists!"
              raise DumpFileExists.new "#{dumpfn} already exists!"
            end
          end

          logger.debug "dumping..."
          if @gzip
            run "#{dump_cmd} | gzip #{gzip_options} > #{dumpfn}"
          else
            run "#{dump_cmd} > #{dumpfn}"
          end
          dumpsize = Util.human_file_size("localhost", dumpfn)
          logger.info("generated #{dumpfn} (#{dumpsize})")

          if @destination
            if remote_destination?
              logger.debug "exporting to #{@destination_host}..."
              Util.with_lockfile(@destination_host, @destination_dumpfile, @opts[:force]) do
                run "scp #{dumpfn} #{@destination_host}:#{@destination_dumpfile}#{@gzip ? '.gz' : ''}"
              end
            elsif @destination_dumpfile && @destination_dumpfile+(@gzip ? '.gz' : '') != dumpfn
              logger.debug "exporting..."
              destdir = File.dirname(@destination_dumpfile)
              run "mkdir -p #{destdir}" if !Util.dir_exists?("localhost", destdir)
              Util.with_lockfile("localhost", @destination_dumpfile, @opts[:force]) do
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
        if File.exist?(@dumpfile + ".gz")
          if File.exist?(@dumpfile) && !@opts[:force]
            logger.warn "skipping decompress because #{@dumpfile} already exists."
          else
            logger.debug "decompressing..."
            run "gzip -d -f #{@dumpfile}.gz"
          end
        else
          logger.warn "decompress failed. #{@dumpfile}.gz does not exist!"
        end
      end

      def import
        if import_installed? != true
          raise MissingDriver.new "#{self.class} does not appear to be installed.\nCould not find command `#{import_cmd.to_s.split.first}`"
        end
        Util.with_lockfile("localhost", @dumpfile, @opts[:force]) do
          decompress if @gzip

          if !File.exist?(@dumpfile)
            raise "Cannot import #{@dumpfile} because it does not exist!"
          else
            dumpsize = Util.human_file_size("localhost", @dumpfile)
            logger.info("importing #{@dumpfile} (#{dumpsize})")
            run import_cmd
          end

        end # with_lockfile
      end

      protected

      def scrub_cmd(cmd)
        cmd.gsub(/password=[^\s]+/, 'password=xxxxxx')
      end

      def run(cmd)
        start_time = Time.now
        logger.info "running command: #{scrub_cmd cmd}"
        stdout = `#{cmd}`
        took_sec = (Time.now - start_time).round()
        if $?.success?
          logger.info "finished (took #{took_sec}s)"
        else
          logger.error "failed (took #{took_sec}s) status: #{$?.exitstatus}"
          raise CommandFailure.new("Aborting because the following command failed: #{scrub_cmd cmd}")
        end
      end

    end
  end
end
