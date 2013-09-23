require 'socket'
require 'thin'
require 'posix-spawn'

require 'thinicorn/backend'

class Thinicorn
  autoload :TcpServer,  'thinicorn/backends/tcp_server'
  autoload :UnixServer, 'thinicorn/backends/unix_server'

  def self.new(host, port, _ = nil)
    if unix_socket?(host)
      UnixServer.new(host)
    else
      TcpServer.new(host, port)
    end
  end

  def self.unix_socket?(path)
    path =~ %r{/}
  end
end
