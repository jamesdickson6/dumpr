#TODO: Refactor this
# Utility methods for touching/reading local and remote files
module Dumpr
  module Util

    def self.file_exists?(h, fn)
      if h == "localhost"
        File.exists?(fn)
      else
        `ssh #{h} test -f '#{fn}' &> /dev/null`
        $?.success?
      end
    end

    def self.dir_exists?(h, fn)
      if h == "localhost"
        File.exists?(fn)
      else
        `ssh #{h} test -d '#{fn}' &> /dev/null`
        $?.success?
      end
    end

    # touch a file  and optionally overwrite it's content with msg
    def self.touch_file(h, fn, msg=nil)
      cmd = "touch #{fn}" + (msg ? " && echo '#{msg}' > #{fn}" : '')
      if h == "localhost"
        system(cmd)
      else
        system("ssh #{h} '#{cmd}'")
      end
    end

    # return contents of a file
    def self.cat_file(h, fn)
      cmd = "cat #{fn}"
      if h == "localhost"
        `#{cmd}`.strip
      else
        `ssh #{h} #{cmd}`.strip
      end
    end

    def self.remove_file(h, fn)
      cmd = "rm #{fn}"
      if h == "localhost"
        system(cmd)
      else
        system("ssh #{h} #{cmd}")
      end
    end

    # return the human readable size of a file like 10MB
    def self.human_file_size(h, fn)
      cmd = "du -h #{fn} | cut -f 1"
      if h == "localhost"
        `#{cmd}`.strip
      else
        `ssh #{h} #{cmd}`.strip
      end
    end

    def self.process_running?(h, pid)
      cmd = "ps -p #{pid}"
      if h == "localhost"
        system(cmd)
      else
        system("ssh #{h} #{cmd}")
      end
    end

    def self.with_lockfile(h, fn, remove_dead_locks=false)
      fn = fn.chomp('.dumpr.lock') + '.dumpr.lock'
      mylock = nil
      if file_exists?(h, fn)
        pid = cat_file(h, fn)
        mylock = Process.pid == pid
        if mylock
          # my own lock.. proceed
        elsif process_running?(h, pid)
          raise BusyDumping.new "Lockfile '#{fn}' exists for another process (#{pid})!"
        else
          if remove_dead_locks
            puts "Removing lockfile '#{fn}' for dead process (#{pid})"
            remove_file(h, fn)
          else
            raise BusyDumping.new "Lockfile '#{fn}' exists for dead process (#{pid}) ! You may want to investigate the reason why, or use --force"
          end
        end
      end
      begin
        touch_file(h, fn, Process.pid)
        yield
      rescue => e
        raise e
      ensure
        remove_file(h, fn)
      end
    end

  end
end
