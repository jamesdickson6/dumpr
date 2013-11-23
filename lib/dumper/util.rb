#TODO: Refactor this
# Utility methods for touching/reading local and remote files
module Dumper
  module Util

    def self.file_exists?(h, fn)
      if h == "localhost"
        File.exists?(fn)
      else
        system("ssh #{h} test -f '#{fn}'")
      end
    end

    def self.dir_exists?(h, fn)
      if h == "localhost"
        File.exists?(fn)
      else
        system("ssh #{h} test -d '#{fn}'")
      end
    end

    # touch a file  and optionally overwrite it's content with msg
    def self.touch_file(h, fn, msg=nil)
      cmd = "touch #{fn}" + (msg ? " && echo '#{msg}' > #{fn}" : '')
      if h == "localhost"
        system(cmd)
      else
        system("ssh #{h} #{cmd}")
      end
    end

    # return contents of a file
    def self.cat_file(h, fn)
      cmd = "cat #{fn}"
      if h == "localhost"
        `#{cmd}`
      else
        `ssh #{h} #{cmd}`
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

    def self.process_running?(h, pid)
      cmd = "ps -p #{pid}"
      if h == "localhost"
        system(cmd)
      else
        system("ssh #{h} #{cmd}")
      end
    end

    def self.with_lockfile(h, fn, msg=nil)
      fn = fn.chomp('.dumper.lock') + '.dumper.lock'
      mylock = nil
      if file_exists?(h, fn)
        pid = cat_file(h, fn)
        mylock = Process.pid == pid
        if mylock
          # my own lock.. proceed
        elsif # process_running?(h, pid)
          raise BusyDumping.new "Lockfile #{fn} exists for another process #{pid}! If this was a previous dump that failed, you might need to remove this file before re-trying..."
        end
      end
      begin
        touch_file(h, fn, Process.pid)
        yield
        remove_file(h, fn) # maybe belongs in ensure..
      rescue => e
        raise e
      ensure

      end
    end

  end
end