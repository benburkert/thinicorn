require 'socket'
require 'thin'
require 'posix-spawn'

require 'thinicorn/backend'

class Thinicorn
  autoload :TcpServer,  'thinicorn/backends/tcp_server'
  autoload :UnixServer, 'thinicorn/backends/unix_server'

  class << self
    attr_accessor :argv, :cmd
    attr_writer   :daemonize

    def new(host, port, opts = {})
      if unix_socket?(host)
        UnixServer.new(host, opts)
      else
        TcpServer.new(host, port, opts)
      end
    end

    def unix_socket?(path)
      path =~ %r{/}
    end

    def daemonize?
      @daemonize
    end

    def command
      [@cmd, *@argv].join(' ')
    end
  end
end
