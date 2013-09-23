class Thinicorn
  class TcpServer < Thin::Backends::TcpServer
    include Backend

    def connection_class
      Thin::Connection
    end

    def create_socket
      TCPServer.open(@host, @port)
    end
  end
end
