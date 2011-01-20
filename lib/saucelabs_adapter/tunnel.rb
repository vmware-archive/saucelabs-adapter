module SaucelabsAdapter

  class Tunnel

    def self.factory(selenium_config)
      tunnels = {
        :saucetunnel => SauceTunnel,
        :sauceconnecttunnel => SauceConnectTunnel,
        :sshtunnel => SshTunnel,
        :othertunnel => OtherTunnel
      }
      raise_with_message "Unknown tunnel type #{selenium_config.tunnel_method}" unless tunnels[selenium_config.tunnel_method.to_sym]

      return tunnels[selenium_config.tunnel_method].new(selenium_config)
    end

    def initialize(se_config)
      raise "#{self.class.name}.new requires a SeleniumConfig argument" unless se_config.is_a?(SeleniumConfig)
      @se_config = se_config
    end

    def start_tunnel
      raise "You need to override this method"
    end

    def shutdown
      raise "You need to override this method"
    end
  end
end