class Thinicorn
  class UnixServer < Thin::Backends::UnixServer
    include Backend

    def connection_class
      Thin::UnixConnection
    end

    def create_socket
      UNIXServer.open(@host)
    end
  end
end
