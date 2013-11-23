require 'dumper/driver'
module Dumper
  module Driver
    class Mysql < Base

      def port
        @port || 3306
      end

      def dump_options
        @dump_options || "--single-transaction --quick"
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