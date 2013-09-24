class Thinicorn
  class UnixServer < Thin::Backends::UnixServer
    include Backend

    def connection_class
      Thin::UnixConnection
    end

    def create_socket
      sock = UNIXServer.open(@socket)
      sock.close_on_exec = false
      sock.listen(100)

      sock
    end

    def connect
      super

      sock    = Socket.for_fd(@fd)
      address = sock.local_address
      @socket = address.unix_path
    end

    def reexec
      @socket = nil # forget about the socket file so we don't clean it up

      super
    end

  end
end
