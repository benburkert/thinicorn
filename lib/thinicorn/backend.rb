class Thinicorn
  module Backend
    include Thin::Logging

    SERVER_FD = 'THINICORN_SERVER_FD'

    def initialize(*)
      super

      @fd    = ENV[SERVER_FD].to_i unless ENV[SERVER_FD].nil?
      @klass = connection_class

      cmd = [$0, *ARGV].join(' ')

      trap(:USR2) { reexec }
    end

    def connect
      @fd = create_socket.fileno if @fd.nil?

      ENV[SERVER_FD] = @fd.to_s

      EventMachine.attach_server @fd, @klass, &method(:initialize_connection)

      @signature = EventMachine.instance_eval{@acceptors.keys.first}
    end

    def reexec
      log ">> SIGUSR2 received - starting graceful restart"

      cmd = [$0, *ARGV].join(' ')
      POSIX::Spawn::spawn(cmd)

      stop
    end

  end
end
