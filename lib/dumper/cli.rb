require 'dumper'
require 'optparse'
require 'ostruct'
module Dumper
  class CLI
    PROG_NAME = File.basename($0)

    def self.execute
      # default options
      options = {}
      options[:dumpdir] = Dir.pwd
      options[:driver] = :mysql
      options[:gzip] = true

      
      # parse ARGV options
      OptionParser.new do |opts|

        opts.banner = <<-ENDSTR
Usage: #{PROG_NAME} [options]
EXPORTING
  #{PROG_NAME} --user youruser --password yourpass --db yourdb --dumpfile yourdb.sql --destination server2:/data/backups
IMPORTING
  #{PROG_NAME} --user youruser --password yourpass --db yourdb --dumpfile /data/backups/yourdb.sql

DON'T FORGET TO SET UP YOUR .ssh/config so you won't be prompted for ssh passwords for file transfers

OPTIONS:

ENDSTR

        opts.on("-t", "--type [TYPE]", "Database type.  (mysql is the default) ") do |val|
          options[:driver] = val
        end

        opts.on("-i", "--import", "Import dump file.  Default behavior is to dump and export to --destination") do |val|
          options[:import] = val
        end

        opts.on("--all-databases", "dump/import ALL databases") do |val|
          options[:all_databases] = val
        end
        
        opts.on("--db DATABASE", "--database DATABASE", "Database to dump/import") do |val|
          options[:database] = val
        end

        # TODO: Add support to Driver for this
        opts.on("--databases [x,y,z]", Array, "dump/import multiple databases") do |val|
          options[:databases] = val
        end

        opts.on("--tables [t1,t2,t3]", Array, "dump certain tables, to be used on conjuction with a single --database") do |val|
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
          options[:host] = val
        end
                                
        opts.on("--dumpfile [DUMPFILE]", "Name of dump file.  If relative, dumpdir") do |val|
          options[:dumpfile] = val
        end
        
        opts.on("--destination [DESTINATION]", "Destination for dump. Can be a relative, as well as remote path in the format host:path") do |val|
          options[:destination] = val
        end

        opts.on("--dumpdir", "Default directory for dumpfiles. Default is working directory") do |val|
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

        opts.on("--log-file [LOGFILE]", "Log file.  Default is stdout.") do |val|
          options[:log_file] = val
        end

        opts.on("--force", "Overwrite dumpfile if it exists already.") do |val|
          options[:force] = val
        end

        opts.on_tail("-h", "--help", "Show this message") do
         puts opts
         exit
        end

        opts.on_tail("-v", "--version", "Show version") do
          puts Dumper::Version
          exit
        end

      end.parse!


      # do it
      if options[:import]
        Dumper.import(options[:driver], options)
      else
        Dumper.export(options[:driver], options)
      end
      
    end

  end
end
