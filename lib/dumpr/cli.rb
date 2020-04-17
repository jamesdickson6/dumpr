require 'dumpr'
require 'optparse'
require 'ostruct'
# command line functions for bin/dumpr
module Dumpr
  class CLI
    PROG_NAME = File.basename($0)


    def self.dump(args)
      # default options
      options = {}
      options[:dumpdir] = Dir.pwd
      options[:driver] = :mysql
      options[:gzip] = true


      op = OptionParser.new do |opts|

        opts.banner = <<-ENDSTR
#{PROG_NAME} #{Dumpr::Version}

usage: #{PROG_NAME} [options] [file]

       #{PROG_NAME} --user root --db test_database test_database_dump.sql.gz

The [file] argument is required and can be passed as --file instead.

Generate a database dumpfile. 
By default the file is compressed with gzip and give a .gz extension.
Use --no-gzip to skip compression.
Setup .ssh/config to avoid being prompted for ssh passwords during file transfers.

options:

ENDSTR

        opts.on("-t", "--type TYPE", "Database type: mysql or postgres. Default is mysql.") do |val|
          options[:driver] = val
        end

        opts.on("--all-databases", "Dump ALL databases") do |val|
          options[:all_databases] = val
        end

        opts.on("--db DATABASE", "--database DATABASE", "Dump a single database") do |val|
          options[:database] = val
        end

        # TODO: Add support to Driver for this
        opts.on("--databases x,y,z", Array, "Dump multiple databases") do |val|
          options[:databases] = val
        end

        opts.on("--tables z,y,z", Array, "Dump certain tables, to be used on conjuction with a single --database") do |val|
          options[:tables] = val
        end

        opts.on("-u USER", "--user USER", "Database user") do |val|
          options[:user] = val
        end

        opts.on("-p PASS", "--password PASS", "--password=pass", "Database password") do |val|
          options[:password] = val
        end

        opts.on("-h HOST", "--host HOST", "Database host") do |val|
          options[:host] = val
        end

        opts.on("-P PORT", "--port PORT", "Database port") do |val|
          options[:port] = val
        end

        opts.on("--file FILENAME", "Filename of dump to create.") do |val|
          options[:dumpfile] = val
        end

        opts.on("--dumpfile FILENAME", "Alias for --file") do |val|
          options[:dumpfile] = val
        end

        opts.on("--destination DESTINATION", "Destination for dumpfile. This can be a remote host:path.") do |val|
          options[:destination] = val
        end

        opts.on("--dumpdir DIRECTORY", "Default directory for dumpfiles. Default is working directory") do |val|
          options[:dumpdir] = val
        end

        opts.on("--dump-options=[DUMPOPTIONS]", "Extra options to be included in dump command") do |val|
          options[:dump_options] = val
        end

        opts.on("--no-gzip", "Don't use gzip") do |val|
          options[:gzip] = false
        end

        opts.on("--gzip-options=[GZIPOPTIONS]", "gzip compression options.  Default is -9 (slowest /max compression)") do |val|
          options[:gzip_options] = val
        end

        opts.on("--log-file LOGFILE", "Log file.  Default is stdout.") do |val|
          options[:log_file] = val
        end

        opts.on("--force", "Overwrite dumpfile if it exists already.") do |val|
          options[:force] = val
        end

        opts.on("-h", "--help", "Show this message") do
         puts opts
         print "\n"
         exit
        end

        opts.on("-v", "--version", "Show version") do
          puts Dumpr::Version
          exit
        end

      end

      begin
        op.parse!(args)
        if args.count == 0 && options[:dumpfile].nil?
          raise OptionParser::InvalidOption.new("[file] or --file is required.")
        elsif args.count == 1
          options[:dumpfile] = args[0]
        else
          raise OptionParser::NeedlessArgument.new("wrong number of arguments, expected 0-1 and got (#{args.count}) #{args.join(', ')}")
        end
      rescue => e
        case (e)
        when OptionParser::InvalidOption, OptionParser::AmbiguousOption, OptionParser::MissingArgument, OptionParser::InvalidArgument, OptionParser::NeedlessArgument
          # todo: write to stderr instead
          puts "invalid arguments. #{e.message}" # stderr plz
          print "\n"
          puts "Try -h for help with this command."
          exit 1
        else
          raise e
        end
      end


      # do it
      begin
        Dumpr.export(options[:driver], options)
      rescue Dumpr::MissingDriver => e
        puts "#{e.message}."
        exit 1
      rescue Dumpr::BadConfig => e
        puts "bad arguments: #{e.message}.\n See --help"
        exit 1
      rescue Dumpr::DumpFileExists => e
        puts "#{e.message}\nIt looks like this dump exists already. You should move it, or use --force to overwrite it"
        exit 1
      rescue Dumpr::BusyDumping => e
        puts "#{e.message}\n See --help"
        exit 1
      rescue Dumpr::CommandFailure => e
        puts e.message
        exit 1
      end

      exit 0

    end


    def self.import(args)
      # default options
      options = {}
      options[:dumpdir] = Dir.pwd
      options[:driver] = :mysql
      options[:gzip] = true


      op = OptionParser.new do |opts|

        opts.banner = <<-ENDSTR
#{PROG_NAME} #{Dumpr::Version}

usage: #{PROG_NAME} [options] [file]

       #{PROG_NAME} --user root --db test_database test_database_dump.sql.gz

Import a dumpfile.
Setup .ssh/config to avoid being prompted for ssh passwords during file transfers.

args:

      [file] is required. This is the filename to import.
                          May be a remote location eg. server:/path/to/file
options:

ENDSTR

        opts.on("-t", "--type TYPE", "Database type: mysql or postgres. Default is mysql.") do |val|
          options[:driver] = val
        end

        opts.on("--all-databases", "Import ALL databases") do |val|
          options[:all_databases] = val
        end

        opts.on("--db DATABASE", "--database DATABASE", "Import to a single database") do |val|
          options[:database] = val
        end

        # TODO: add support to Driver for --databases and --tables
        #      import probably does not need these/
        opts.on("--databases x,y,z", Array, "Import multiple databases") do |val|
          options[:databases] = val
        end

        # opts.on("--tables x,y,z", Array, "Import only certain tables, to be used on conjuction with a single --database") do |val|
        #   options[:tables] = val
        # end

        opts.on("-u USER", "--user USER", "Database user") do |val|
          options[:user] = val
        end

        opts.on("-p PASS", "--password PASS", "--password=pass", "Database password") do |val|
          options[:password] = val
        end

        opts.on("-h HOST", "--host HOST", "Database host") do |val|
          options[:host] = val
        end

        opts.on("-P PORT", "--port PORT", "Database port") do |val|
          options[:port] = val
        end

        opts.on("--file FILENAME", "Filename of dump to import") do |val|
          options[:dumpfile] = val
        end

        opts.on("--dumpfile FILENAME", "Alias for --file") do |val|
          options[:dumpfile] = val
        end

        opts.on("--destination DESTINATION", "Destination for dumpfile. This can be a remote host:path.") do |val|
          options[:destination] = val
        end

        opts.on("--dumpdir DIRECTORY", "Default directory for dumpfiles. Default is working directory") do |val|
          options[:dumpdir] = val
        end

        opts.on("--import-options=[IMPORTOPTIONS]", "Extra options to be included in dump command") do |val|
          options[:import_options] = val.to_s
        end

        opts.on("--no-gzip", "Don't use gzip") do |val|
          options[:gzip] = false
        end

        opts.on("--gzip-options=[GZIPOPTIONS]", "gzip compression options.  Default is -9 (slowest /max compression)") do |val|
          options[:gzip_options] = val
        end

        opts.on("--log-file LOGFILE", "Log file.  Default is stdout.") do |val|
          options[:log_file] = val
        end

        opts.on("--force", "Overwrite dumpfile if it exists already.") do |val|
          options[:force] = val
        end

        opts.on("-h", "--help", "Show this message") do
         puts opts
         exit
        end

        opts.on("-v", "--version", "Show version") do
          puts Dumpr::Version
          exit
        end

      end

      begin
        op.parse!(args)
        if args.count == 0 && options[:dumpfile].nil?
          raise OptionParser::InvalidOption.new("[file] or --file is required.")
        elsif args.count == 1
          options[:dumpfile] = args[0]
        else
          raise OptionParser::NeedlessArgument.new("wrong number of arguments, expected 0-1 and got (#{args.count}) #{args.join(', ')}")
        end
      rescue => e
        case (e)
        when OptionParser::InvalidOption, OptionParser::AmbiguousOption, OptionParser::MissingArgument, OptionParser::InvalidArgument, OptionParser::NeedlessArgument
          # todo: write to stderr instead
          puts "invalid arguments. #{e.message}" # stderr plz
          print "\n"
          puts "Try -h for help with this command."
          exit 1
        else
          raise e
        end
      end


      # do it
      begin
        Dumpr.import(options[:driver], options)
      rescue Dumpr::MissingDriver => e
        puts "#{e.message}."
        exit 1
      rescue Dumpr::BadConfig => e
        puts "bad arguments: #{e.message}.\n See --help"
        exit 1
      rescue Dumpr::DumpFileExists => e
        puts "#{e.message}\nIt looks like this dump exists already. You should move it, or use --force to overwrite it"
        exit 1
      rescue Dumpr::BusyDumping => e
        puts "#{e.message}\n See --help"
        exit 1
      rescue Dumpr::CommandFailure => e
        puts e.message
        exit 1
      end

      exit 0

    end

  end
end
