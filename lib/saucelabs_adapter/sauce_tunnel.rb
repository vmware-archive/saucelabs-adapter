require 'net/ssh'
require 'net/ssh/gateway'
require 'saucerest-ruby/saucerest'
require 'saucerest-ruby/gateway'

module SaucelabsAdapter
  class SauceTunnel

    include Utilities

    DEFAULT_TUNNEL_STARTUP_TIMEOUT = 240

    def initialize(se_config)
      raise "SauceTunnel.new requires a SeleniumConfig argument" unless se_config.is_a?(SeleniumConfig)
      @se_config = se_config
      connect_to_rest_api
      start_tunnel
    end

    def start_tunnel
      say "Setting up tunnel from Saucelabs (#{@se_config.application_address}:#{@se_config.application_port}) to localhost:#{@se_config.tunnel_to_localhost_port} (timeout #{tunnel_startup_timeout}s)..."
      boot_tunnel_machine
      setup_ssh_reverse_tunnel
      # WARNING: JsUnit depends upon the format of this output line:
      say "Tunnel ID #{@tunnel_id} for #{@se_config.application_address} is up."
    end

    def tunnel_startup_timeout
      (@se_config.tunnel_startup_timeout || DEFAULT_TUNNEL_STARTUP_TIMEOUT).to_i
    end

    def shutdown
      say "Shutting down tunnel to Saucelabs..."
      teardown_ssh_reverse_tunnel
      shutdown_tunnel_machine
      say "done."
    end

    private

    def connect_to_rest_api
      sauce_api_url = "https://#{@se_config.saucelabs_username}:#{@se_config.saucelabs_access_key}@saucelabs.com/rest/#{@se_config.saucelabs_username}/"
      debug "Connecting to Sauce API at #{sauce_api_url}"
      @sauce_api_endpoint = SauceREST::Client.new sauce_api_url
    end

    def boot_tunnel_machine
      debug "Booting tunnel host:"
      response = @sauce_api_endpoint.create(:tunnel, 'DomainNames' => [@se_config.application_address])
      if response.has_key? 'error'
        raise "Error booting tunnel machine: " + response['error']
      end
      @tunnel_id = response['id']
      debug "Tunnel id: %s" % @tunnel_id

      Timeout::timeout(tunnel_startup_timeout) do
        last_status = tunnel_status = nil
        begin
          sleep 5
          @tunnel_info = @sauce_api_endpoint.get :tunnel, @tunnel_id
          tunnel_status = @tunnel_info['Status']
          debug "  tunnel host is #{tunnel_status}" if tunnel_status != last_status
          last_status = tunnel_status
          case tunnel_status
            when 'new', 'booting'
              # Alrighty. Keep going.
            when 'running'
              # We're done.
            when 'terminated'
              raise "There was a problem booting the tunnel machine: it terminated (%s)" % @tunnel_info['Error']
            else
              raise "Unknown tunnel machine status: #{tunnel_status} (#{@tunnel_info.inspect})"
          end
        end while tunnel_status != 'running'
      end
    rescue Timeout::Error
      error_message = "Tunnel did not come up in #{tunnel_startup_timeout} seconds."
      say error_message
      shutdown_tunnel_machine
      raise_with_message error_message
    end

    def shutdown_tunnel_machine
      return unless @sauce_api_endpoint && @tunnel_id
      debug "Shutting down tunnel machine:"
      Timeout::timeout(120) do
        @sauce_api_endpoint.delete :tunnel, @tunnel_id
        status = nil
        begin
          sleep 5
          status = @sauce_api_endpoint.get(:tunnel, @tunnel_id)['Status']
          debug status
        end while status != 'terminated'
      end
    rescue Timeout::Error
      # Do not raise here, or else you give false negatives from test runs
      say "*" * 80
      say "Sauce Tunnel failed to shut down! Go visit http://saucelabs.com/tunnels and shut down the tunnel for #{@se_config.application_address}"
      say "*" * 80
    end

    def setup_ssh_reverse_tunnel
      debug "Starting ssh reverse tunnel"
      @gateway = Net::SSH::Gateway.new(@tunnel_info['Host'], @se_config.saucelabs_username, {:password => @se_config.saucelabs_access_key})
      @port = @gateway.open_remote(@se_config.tunnel_to_localhost_port.to_i, "127.0.0.1", @se_config.application_port.to_i, "0.0.0.0")
    end

    def teardown_ssh_reverse_tunnel
      if @gateway
        debug "Shutting down ssh reverse tunnel"
        @gateway.close(@port) if @port
        @gateway.shutdown! if @gateway
        debug "done."
      end
    end
  end
end
