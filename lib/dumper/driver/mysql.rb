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
        "mysqldump -u #{user} --password=#{password} -h #{host} -P #{port} #{dump_options} #{database} #{tables.join(' ')}"
      end

      def import_cmd
        "mysql -u #{user} --password=#{password} -h #{host} -P #{port} #{database} < #{dumpfile}"
      end

    end
  end
end