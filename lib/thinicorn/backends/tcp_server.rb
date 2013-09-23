class Thinicorn
  class TcpServer < Thin::Backends::TcpServer
    include Backend
  end
end
