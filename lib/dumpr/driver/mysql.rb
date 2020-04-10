require 'dumpr/driver'
module Dumpr
  module Driver
    class Mysql < Base

      def port
        @port || 3306
      end

      def dump_options
        @dump_options || "--single-transaction --quick"
      end

      def dump_installed?
        system("which mysqldump") == true
      end

      def import_installed?
        system("which mysql") == true
      end

      def configure(opts)
        super(opts)
        if @all_databases
          # supported
        elsif @databases
          # supported
        elsif @database
          # supported
        else
          raise BadConfig.new "#{self.class} requires option --database or --databases or --all-databases"
        end
      end

      def dump_cmd
        if @all_databases
          "mysqldump -u #{user} --password=#{password} -h #{host} -P #{port} --all-databases #{dump_options}"
        elsif @databases
          "mysqldump -u #{user} --password=#{password} -h #{host} -P #{port} --databases #{databases.join(' ')} #{dump_options}"
        else
          "mysqldump -u #{user} --password=#{password} -h #{host} -P #{port} #{database} #{tables ? tables.join(' ') : ''} #{dump_options}"
        end
      end

      def import_cmd
        "mysql -u #{user} --password=#{password} -h #{host} -P #{port} #{database} < #{dumpfile}"
      end

    end
  end
end
