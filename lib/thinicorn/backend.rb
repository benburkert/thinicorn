module Thinicorn
  class Backend < Thin::Backends::Base

    attr_accessor :server_fd, :control_fd

    def initialize(host, port, options = {})
      @host, @port, @options = host, port, options

      if fd = options.fetch(:server_fd, ENV['THINICORN_SERVER_FD'])
        @server_fd = fd.to_i
      end

      super()
    end

    def connect
      @socket = build_socket
    end

    def build_socket
      if @host =~ %r{/}
        UNIXServer.open(@host)
      else
        TCPServer.open(@host, @port)
      end
    end

    def disconnect
      @socket.close
    end

  end
end
