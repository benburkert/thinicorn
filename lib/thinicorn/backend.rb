class Thinicorn
  module Backend

    SERVER_FD = 'THINICORN_SERVER_FD'

    def initialize(*)
      super

      setup
    end

    def setup
      @fd    = ENV[SERVER_FD].to_i unless ENV[SERVER_FD].nil?
      @klass = connection_class

      trap(:USR2) { reexec }
    end

    def connect
      @fd = create_socket.fileno if @fd.nil?

      EventMachine.attach_server @fd, @klass, &method(:initialize_connection)

      @signature = EventMachine.instance_eval{@acceptors.keys.first}
    end
  end
end
