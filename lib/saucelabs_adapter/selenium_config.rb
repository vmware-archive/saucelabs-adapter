module SaucelabsAdapter
  class SeleniumConfig

    include Utilities

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
      :tunnel_method, :tunnel_to_localhost_port, :tunnel_startup_timeout,
      :tunnel_username, :tunnel_password, :tunnel_keyfile,
      :jsunit_polling_interval_seconds ].each do |attr|
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
          'max-duration' => saucelabs_max_duration_seconds.to_i,
          'job-name' => ENV['SAUCELABS_JOB_NAME'] || Socket.gethostname
        }.to_json
      else
        @configuration['selenium_browser_key']
      end
    end

    def application_address
      if start_tunnel? && @configuration['tunnel_method'].to_sym == :saucetunnel
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

    def create_driver(selenium_args = {})
      args = selenium_client_driver_args.merge(selenium_args)
      debug "Connecting to Selenium RC server at #{args[:host]}:#{args[:port]} (testing app at #{args[:url]})"
      debug "args = #{args.inspect}"
      driver = ::Selenium::Client::Driver.new(args)
      debug "done"
      driver
    end

    def start_tunnel?
      !tunnel_method.nil? && tunnel_method.to_sym != :othertunnel
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
                                      :when => "when selenium_server_address is saucelabs.com")
        if tunnel_method
          errors << require_attributes([:tunnel_to_localhost_port ], :when => "if tunnel_method is set")
          case tunnel_method.to_sym
            when nil, ""
            when :saucetunnel
            when :othertunnel
              errors << require_attributes([:application_address], :when => "when tunnel_method is :othertunnel")
            when :sshtunnel
              errors << require_attributes([:application_address], :when => "when tunnel_method is :sshtunnel")
              errors << require_attributes([:tunnel_password, :tunnel_keyfile],
                                           :when => "when tunnel_method is :sshtunnel",
                                           :any_or_all => :any)
              if tunnel_keyfile && !File.exist?(File.expand_path(tunnel_keyfile))
                errors << "tunnel_keyfile '#{tunnel_keyfile}' does not exist" 
              end
            else
              errors << "Unknown tunnel_method: #{tunnel_method}"
          end
        end
      else
        errors << require_attributes([:selenium_browser_key, :application_address ],
                                      :when => "unless server is saucelab.com")
      end

      errors.flatten!.compact!
      if !errors.empty?
        raise "[saucelabs-adapter] Aborting; stanza #{configuration_name} has the following errors:\n\t" + errors.join("\n\t")
      end
    end

    def require_attributes(names, options = {})
      default_options = {
        :when => "",
        :any_or_all => :all
      }
      options = default_options.merge(options)

      errors = []
      names.each do |attribute|
        errors << "#{attribute} is required #{options[:when]}" if send(attribute).nil?
      end
      errors = [] if options[:any_or_all] == :any && errors.size < names.size
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
