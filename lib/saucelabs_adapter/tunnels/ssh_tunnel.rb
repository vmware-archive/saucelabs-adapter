require 'net/ssh'
require 'net/ssh/gateway'
require 'saucerest-ruby/gateway'

module SaucelabsAdapter
  class SshTunnel < Tunnel
    include Utilities

    def start_tunnel
      say "Setting up SSH reverse tunnel from #{@se_config.application_address}:#{@se_config.application_port} to localhost:#{@se_config.tunnel_to_localhost_port}"
      options = @se_config.tunnel_password ? { :password => @se_config.tunnel_password } : { :keys => @se_config.tunnel_keyfile }
      @gateway = Net::SSH::Gateway.new(@se_config.application_address, @se_config.tunnel_username, options)
      @port = @gateway.open_remote(@se_config.tunnel_to_localhost_port.to_i, "127.0.0.1", @se_config.application_port.to_i, "0.0.0.0")
    end

    def shutdown
      if @gateway
        say "Shutting down ssh reverse tunnel"
        @gateway.close(@port) if @port
        @gateway.shutdown! if @gateway
      end
    end

  end
end