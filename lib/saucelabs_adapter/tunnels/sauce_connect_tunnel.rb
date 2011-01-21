require 'sauce'

module SaucelabsAdapter
  class SauceConnectTunnel < Tunnel

    include Utilities

    def start_tunnel
      say "Setting up sauce connect tunnel from Saucelabs..."
      # sauce connect --user=<saucelabs_username> --api-key=<saucelabs_access_key> --host=localhost --port=8080 --domain='<local hostname>-<pid>.com'
      # --logfile=/tmp/sauce_connect.log --debug-ssh

      sauce_connect_args = {
        :user => @se_config.saucelabs_username,
        :'api-key' => @se_config.saucelabs_access_key,
        :host => 'localhost',
        :port => @se_config.application_port,
        :tunnel_port => @se_config.tunnel_to_localhost_port,
        :domain => @se_config.application_address,
        :logfile => '/tmp/sauce_connect.log',
        :'debug-ssh' => true
      }

      say "Setting up sauce connect tunnel from Saucelabs: #{sauce_connect_args.inspect}"
      @sauce_tunnel = Sauce::Connect.new(sauce_connect_args)
      say "Waiting for sauce connect tunnel to be ready..."
      @sauce_tunnel.wait_until_ready
      sleep 2
      say "Sauce connect tunnel ready."
    end

    def shutdown
      say "Shutdown for Sauce Connect Tunnel..."
      @sauce_tunnel.disconnect
    end
  end
end
