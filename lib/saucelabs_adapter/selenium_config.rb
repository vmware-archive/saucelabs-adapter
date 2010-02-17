module SaucelabsAdapter
  class SeleniumConfig
    attr_reader :configuration

    def initialize(configuration_name = nil, selenium_yml_path = nil)
      selenium_yml_path = selenium_yml_path || File.join(RAILS_ROOT, 'config', 'selenium.yml')
      SeleniumConfig.parse_yaml(selenium_yml_path)
      build_configuration(configuration_name)
    end

    def []=(attribute, value)
      @configuration[attribute.to_s] = value
    end

    [ :selenium_server_address, :selenium_server_port,
      :application_address, :application_port,
      :saucelabs_username, :saucelabs_access_key,
      :saucelabs_browser_os, :saucelabs_browser, :saucelabs_browser_version,
      :saucelabs_max_duration_seconds,
      :tunnel_method, :tunnel_to_localhost_port, :tunnel_startup_timeout ].each do |attr|
      define_method(attr) do
        @configuration[attr.to_s]
      end
    end

    def selenium_browser_key
      if selenium_server_address == 'saucelabs.com'
        # Create the JSON string that Saucelabs needs:
        { 'username' => saucelabs_username,
          'access-key' => saucelabs_access_key,
          'os' => saucelabs_browser_os,
          'browser' => saucelabs_browser,
          'browser-version' => saucelabs_browser_version,
          'max-duration' => saucelabs_max_duration_seconds,
          'job-name' => ENV['SAUCELABS_JOB_NAME'] || Socket.gethostname
        }.to_json
      else
        @configuration['selenium_browser_key']
      end
    end

    def application_address
      if start_sauce_tunnel?
        # We are using Sauce Labs and Sauce Tunnel.
        # We need to use a masquerade hostname on the EC2 end of the tunnel that will be unique within the scope of
        # this account (e.g. pivotallabs).  Therefore we mint a fairly unique hostname here.
        hostname = Socket.gethostname.split(".").first
        "#{hostname}-#{Process.pid}.com"
      else
        @configuration['application_address']
      end

    end

    # Takes a Webrat::Configuration object and configures it by calling methods on it
    def configure_webrat(webrat_configuration_object)
      {
        'selenium_server_address' => :selenium_server_address,
        'selenium_server_port'    => :selenium_server_port,
        'selenium_browser_key'    => :selenium_browser_key,
        'application_address'     => :application_address,
        'application_port'        => :application_port
      }.each do |webrat_configuration_method, our_accessor|
        webrat_configuration_object.send("#{webrat_configuration_method}=", self.send(our_accessor).to_s)
      end
    end

    # Takes a Polonium::Configuration object and configures it by calling methods on it
    def configure_polonium(polonium_configuration_object)
      {
        'selenium_server_host'      => :selenium_server_address,
        'selenium_server_port'      => :selenium_server_port,
        'browser'                   => :selenium_browser_key,
        'external_app_server_host'  => :application_address,
        'external_app_server_port'  => :application_port
      }.each do |polonium_configuration_method, our_accessor|
        polonium_configuration_object.send("#{polonium_configuration_method}=", self.send(our_accessor).to_s)
      end
    end

    def create_driver(selenium_args = {}, options = {})
      args = selenium_client_driver_args.merge(selenium_args)
      puts "[saucelabs-adapter] Connecting to Selenium RC server at #{args[:host]}:#{args[:port]} (testing app at #{args[:url]})" if options[:debug]
      puts "[saucelabs-adapter] args = #{args.inspect}" if options[:debug]
      driver = ::Selenium::Client::Driver.new(args)
      puts "[saucelabs-adapter] done" if options[:debug]
      driver
    end

    def start_sauce_tunnel?
      tunnel_method == :saucetunnel
    end

    def self.parse_yaml(selenium_yml_path)
      raise "[saucelabs-adapter] could not open #{selenium_yml_path}" unless File.exist?(selenium_yml_path)
      @@selenium_configs ||= YAML.load_file(selenium_yml_path)
    end

    private

    def build_configuration(configuration_name)
      @configuration = @@selenium_configs[configuration_name]
      raise "[saucelabs-adapter] stanza '#{configuration_name}' not found in #{@selenium_yml}" unless @configuration
      check_configuration(configuration_name)
    end

    def check_configuration(configuration_name)
      errors = []
      errors << require_attributes([:selenium_server_address, :selenium_server_port, :application_port])
      if selenium_server_address == 'saucelabs.com'
        errors << require_attributes([ :saucelabs_username, :saucelabs_access_key,
                                        :saucelabs_browser_os, :saucelabs_browser, :saucelabs_browser_version,
                                        :saucelabs_max_duration_seconds ],
                                      "when selenium_server_address is saucelabs.com")
        case tunnel_method
          when nil, ""
          when :saucetunnel, :othertunnel
            errors << require_attributes([:tunnel_to_localhost_port ],
                                          "if tunnel_method is set")
          else
            errors << "Unknown tunnel_method: #{tunnel_method}"
        end
      else
        errors << require_attributes([:selenium_browser_key, :application_address ],
                                      "unless server is saucelab.com")
      end

      errors.flatten!.compact!
      if !errors.empty?
        raise "[saucelabs-adapter] Aborting; stanza #{configuration_name} has the following errors:\n\t" + errors.join("\n\t")
      end
    end

    def require_attributes(names, under_what_circumstances = "")
      errors = []
      names.each do |attribute|
        errors << "#{attribute} is required #{under_what_circumstances}" if send(attribute).nil?
      end
      errors
    end

    def selenium_client_driver_args
      {
        :host => selenium_server_address,
        :port => selenium_server_port.to_s,
        :browser => selenium_browser_key,
        :url => "http://#{application_address}:#{application_port}",
        :timeout_in_seconds => 600
      }
    end
  end
end