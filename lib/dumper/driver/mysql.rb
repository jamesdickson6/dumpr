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
          "mysqldump -u #{user} --password=#{password} -h #{host} -P #{port} #{dump_options} --all-databases"
        elsif @databases
          "mysqldump -u #{user} --password=#{password} -h #{host} -P #{port} #{dump_options} --databases #{databases.join(' ')}"
        else
          "mysqldump -u #{user} --password=#{password} -h #{host} -P #{port} #{dump_options} #{database} #{tables ? tables.join(' ') : ''}"
        end
      end

      def import_cmd
        "mysql -u #{user} --password=#{password} -h #{host} -P #{port} #{database} < #{dumpfile}"
      end

    end
  end
end