=begin
  Made by Christian KAKESA etna_2008(paris) <christian.kakesa@gmail.com>
=end

begin
  require 'socket'
  require 'singleton'
  require 'lib/netsoul_location'
  require 'lib/netsoul_message'
rescue LoadError
  puts "Error: #{$!}"; exit!;
end

if not $DEBUG
	$log = Logger.new(STDERR)
	$log.level = Logger::WARN
else
	$log = Logger.new(STDOUT)
	$log.level = Logger::DEBUG
end

module NetSoul
  class NetSoul
    include Singleton

    attr_reader :connection_values, :authenticated
    attr_accessor :sock

    def initialize
      @main_app = nil
      @rs_config = RsConfig::instance()
      @connection_values = Hash.new
      @sock = nil
      @authenticated = false
    end

    def connect(my_main_app = nil, my_sock = nil)
    	@main_app = my_main_app if !my_main_app.nil?
    	if my_sock
    		@sock = my_sock
    	else
			  begin
				  @sock = TCPSocket.new(@rs_config.conf[:server_host].to_s, @rs_config.conf[:server_port].to_i)
        rescue => err
				  $log.warn("Unexpected ERROR (%s): %s => %s:%d\n" % [err.class, err, __FILE__, __LINE__])
				  @sock = nil
				  return false
			  end
      end
      buf = sock_get()
      cmd, socket_num, md5_hash, client_ip, client_port, server_timestamp = buf.split
      server_timestamp_diff = Time.now.to_i - server_timestamp.to_i
      @connection_values[:md5_hash] = md5_hash
      @connection_values[:client_ip] = client_ip
      @connection_values[:client_port] = client_port
      @connection_values[:login] = @rs_config.conf[:login]
      @connection_values[:socks_password] = @rs_config.conf[:socks_password]
      @connection_values[:unix_password] = @rs_config.conf[:unix_password]
      @connection_values[:state] = @rs_config.conf[:state]
      @connection_values[:location] = @rs_config.conf[:location]
      @connection_values[:user_group] = @rs_config.conf[:user_group]
      @connection_values[:system] = RUBY_PLATFORM
      @connection_values[:timestamp_diff] = server_timestamp_diff
      return auth()
    end

    def auth
      @authenticated = false
      sock_send("auth_ag ext_user none -")
      rep = sock_get()
      if not (rep.split(' ')[1] == "002")
        return false
      end

      if (@rs_config.conf[:connection_type].to_s == RsConfig::APP_CONNECTION_TYPE_KERBEROS)
        sock_send(Message.kerberos_authentication(@connection_values))
      else
        sock_send(Message.standard_authentication(@connection_values))
      end

      rep = sock_get()
      if not (rep.split(' ')[1] == "002")
        return false
      end
      @authenticated = true
      sock_send("user_cmd attach")
      sock_send( Message.set_state(@rs_config.conf[:state], get_server_timestamp()) )
      return @authenticated
    end

    def disconnect
      sock_send(Message.ns_exit())
      sock_close()
    end

    def sock_send(str)
    	begin
    		@sock.puts str.to_s
    	rescue SocketError, Errno::EPIPE, Errno::ECONNRESET, Errno::ETIMEDOUT => se
    		$log.warn("Unexpected ERROR (%s): %s => %s:%d\n" % [se.class, se, __FILE__, __LINE__])
    		@sock = nil
    		reconnection = true
			  @main_app.disconnection(reconnection) if !@main_app.nil?
			  retry
    	rescue => err
    		$log.warn("Unexpected ERROR (%s): %s => %s:%d\n" % [err.class, err, __FILE__, __LINE__])
			  @sock = nil
			  @main_app.disconnection() if !@main_app.nil?
    	end
    end

    def sock_get()
    	res = nil
    	begin
   			res = @sock.gets
    	rescue SocketError, Errno::EPIPE, Errno::ECONNRESET, Errno::ETIMEDOUT => se
    		$log.warn("Unexpected ERROR (%s): %s => %s:%d\n" % [se.class, se, __FILE__, __LINE__])
    		@sock = nil
    		reconnection = true
			  @main_app.disconnection(reconnection) if !@main_app.nil?
			  retry
    	rescue => err
    		$log.warn("Unexpected ERROR (%s): %s => %s:%d\n" % [err.class, err, __FILE__, __LINE__])
			  @sock = nil
			  @main_app.disconnection() if !@main_app.nil?
			  return nil
    	end
    	return res
    end

    def sock_close
      @sock = nil
      @authenticated = false
    end

    def get_server_timestamp
      return Time.now.to_i - @connection_values[:timestamp_diff].to_i
    end
  end
end

