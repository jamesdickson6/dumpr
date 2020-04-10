require 'dumpr/driver'
module Dumpr
  module Driver
    class Postgres < Base

      def port
        @port || 5432
      end

      def dump_options
        @dump_options || "-Fc" #"-Fc -v"
      end

      def dump_installed?
        system("which pg_dump") == true
      end

      def import_installed?
        system("which pg_restore") == true
      end

      def configure(opts)
        super(opts)
        if @all_databases
          raise BadConfig.new "#{self.class} does not support --all-databases"
        elsif @databases
          raise BadConfig.new "#{self.class} does not support multiple --databases"
        elsif @database.nil?
          #raise BadConfig.new "#{self.class} requires option --database"
        end
      end

      def dump_cmd
        if @all_databases
          "pg_dump -h #{host} -p #{port} -U #{user} --password #{password} #{dump_options}"
        elsif @databases
          # not supported
        else
          "pg_dump -h #{host} -p #{port} -U #{user} --password #{password} #{dump_options} #{database}"
        end
      end

      def import_cmd
        "pg_restore -h #{host} -p #{port} -U #{user} --password #{password} --verbose --clean --no-owner --no-acl #{database} #{dumpfile}"
      end

    end
  end
end
