# author :jdickson
# ChunkPipe
# An IO pipe that provides generic parsing / rewriting 
# of a stream of packets (or lines in a file).
# It passes chunks of packets to a block
# The return value of the block is written to the other end of the pipe
# packet delimiter is not removed from packet suffix
# 
# Silly Example that simply passes through the data: 
# ChunkPipe.open(STDIN, STDOUT, 1000, "\n") {|lines| lines.join }
#
module ChunkPipe

  MAX_CHUNK_SIZE = 1000000

  def open(reader, writer, chunk_size, packet_delim, read_timeout=3, &block)
    if chunk_size < 1 || chunk_size > MAX_CHUNK_SIZE
      raise ArgumentError.new "invalid chunk size #{chunk_size.inspect}"
    end
    chunk_idx = 0
    packet_idx = 0
    packets = []
    stopblocking = Thread.new do
      sleep read_timeout
      reader.close # this can raise IOError
      raise IOError.new "ChunkPipe read time out (#{read_timeout}s)"
    end
    while packet = reader.gets(packet_delim) do
      stopblocking.kill if stopblocking.alive?
      packets << packet
      if ((packet_idx+1) % chunk_size == 0)
        data = yield packets 
        writer << data if data
        chunk_idx+=1
        packets = []
      end
      packet_idx+=1
      #break if reader.eof?
    end
    unless packets.empty?
      data = yield packets 
      writer << data if data
    end
  ensure
    reader.close if reader && !reader.closed?
    writer.close if writer && !writer.closed?
  end

  module_function :open

end