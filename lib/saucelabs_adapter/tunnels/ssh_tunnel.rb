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
      @host_and_port = @gateway.open_remote(@se_config.tunnel_to_localhost_port.to_i, "127.0.0.1", @se_config.application_port.to_i, "0.0.0.0")
    end

    def shutdown
      # We have experienced problems with the tunnel shutdown hanging.
      # Previously the method was a no-op and we just exited the process which had the effect of closing the tunnel.
      # However we are now running multiple tunnels in one process (sequentially), so we need to actually do a shutdown.
      # So let's add a timeout.
      if @gateway
        begin
          Timeout::timeout(15) do
            say "Shutting down ssh reverse tunnel"
            @gateway.close_remote(*@host_and_port) if @host_and_port
            @gateway.shutdown! if @gateway
          end
        rescue Timeout::Error
          say "tunnel shutdown timed out"
        end
      end
    end
  end
end