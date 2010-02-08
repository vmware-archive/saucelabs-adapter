require 'saucerest-ruby/saucerest'

module SaucelabsAdapter
  class SauceTunnel
    DEFAULT_TUNNEL_STARTUP_TIMEOUT = 240

    def initialize(se_config)
      raise "SauceTunnel.new requires a SeleniumConfig argument" unless se_config.is_a?(SeleniumConfig)
      @se_config = se_config
      connect_to_rest_api
      start_tunnel
    end

    def start_tunnel
      boot_tunnel_machine
      Timeout::timeout(tunnel_startup_timeout) do
        while !tunnel_is_up?
          sleep 10
        end
        @tunnel_id = tunnel_info['_id']
      end
      STDOUT.puts "[saucelabs-adapter] Tunnel ID #{@tunnel_id} for #{@se_config[:application_address]} is up."
    rescue Timeout::Error
        raise "Tunnel did not come up within #{tunnel_startup_timeout} seconds."
    end

    def tunnel_startup_timeout
      (@se_config[:tunnel_startup_timeout] || DEFAULT_TUNNEL_STARTUP_TIMEOUT).to_i
    end

    def shutdown
      STDOUT << "[saucelabs-adapter] Shutting down tunnel to Saucelabs..."
      shutdown_tunnel_machine
      STDOUT.puts "[saucelabs-adapter] done."
    end

    private

    def connect_to_rest_api
      sauce_api_url = "https://#{@se_config[:username]}:#{@se_config['access-key']}@saucelabs.com/rest/#{@se_config[:username]}/"
      # puts "[saucelabs-adapter] Connecting to Sauce API at #{sauce_api_url}"
      @sauce_api_endpoint = SauceREST::Client.new sauce_api_url
    end

    def boot_tunnel_machine
      puts "[saucelabs-adapter] Setting up tunnel from Saucelabs (#{@se_config[:application_address]}:#{@se_config[:application_port]}) to localhost:#{@se_config[:localhost_app_server_port]} - waiting #{tunnel_startup_timeout} seconds for tunnel to start..."
      tunnel_script = File.join(File.dirname(__FILE__), '..', 'saucerest-python', 'tunnel.py')
      if !File.exist?(tunnel_script)
        raise "#{tunnel_script} is missing, have you installed saucerest-python?"
      end
      tunnel_command = "python #{tunnel_script} --shutdown #{@se_config[:username]} #{@se_config[:'access-key']} " +
                       "localhost #{@se_config[:localhost_app_server_port]}:#{@se_config[:application_port]} #{@se_config[:application_address]} &"
      # puts tunnel_command
      system(tunnel_command)
    end

    def tunnel_is_up?
      info = tunnel_info
      info && info['Status'] == 'running'
    end

    def tunnel_info
      tunnels = @sauce_api_endpoint.list(:tunnel)
      tunnels.detect { |t| t['DomainNames'].include?(@se_config[:application_address]) }
    end

    def shutdown_tunnel_machine
      Timeout::timeout(120) do
        @sauce_api_endpoint.delete :tunnel, @tunnel_id
        while tunnel_info
          sleep 10
         end
      end
    rescue Timeout::Error
      # Do not raise here, or else you give false negatives from test runs
      STDERR.puts "*" * 80
      STDERR.puts "Sauce Tunnel failed to shut down! Go visit http://saucelabs.com/tunnels and shut down the tunnel for #{@se_config[:application_address]}"
      STDERR.puts "*" * 80
    end
  end
end