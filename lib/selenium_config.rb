class SeleniumConfig
  attr_reader :configuration
  attr_reader :localhost_app_server_port

  def initialize(configuration_name = nil, selenium_yml_path = nil)
    selenium_yml_path = selenium_yml_path || File.join(RAILS_ROOT, 'config', 'selenium.yml')
    SeleniumConfig.parse_yaml(selenium_yml_path)
    @start_sauce_tunnel = false
    build_configuration(configuration_name)
  end

  # TODO: why is this class a hash and also has attr_readers?
  def [](attribute)
    case attribute
    when :username, 'username', :'access-key', 'access-key', :os, 'os', :browser, 'browser', :'browser-version', 'browser_version'
      ::JSON.parse(configuration['selenium_browser_key'])[attribute.to_s]
    else
      configuration[attribute]
    end
  end

  def []=(attribute, value)
    configuration[attribute] = value
  end

  # Takes a Webrat::Configuration and configures it
  def configure_webrat(webrat_configuration_object)
    configuration.each do |method, value|
      webrat_configuration_object.send("#{method}=", value)
    end
  end

  # Map Webrat::Configuration to Polonium::Configuration methods
  WEBRAT_TO_POLONIUM_CONFIG_METHODS = {
    'application_framework'   => 'app_server_engine',
    'selenium_server_address' => 'selenium_server_host',
    'selenium_browser_key'    => 'browser',
    'application_address'     => 'external_app_server_host',
    'application_port'        => 'external_app_server_port'
  } unless defined?(WEBRAT_TO_POLONIUM_CONFIG_METHODS)

  # Takes a Polonium::Configuration and configures it
  def configure_polonium(polonium_configuration_object)
    configuration.each do |method, value|
      config_method = WEBRAT_TO_POLONIUM_CONFIG_METHODS[method] || method
      polonium_configuration_object.send("#{config_method}=", value)
    end
  end

  def create_driver(selenium_args = {})
    args = selenium_client_driver_args.merge(selenium_args)
    puts "Connecting to Selenium RC server at #{args[:host]}:#{args[:port]} (testing app at #{args[:url]})"
    return ::Selenium::Client::Driver.new(args)
  end

  def using_tunnel?
    ! %w{ localhost 127.0.0.1 }.include?(configuration['selenium_server_address'])
  end

  def use_sauce_tunnel?
    configuration['selenium_server_address'] == 'saucelabs.com' && !configuration['application_address']
  end

  def start_tunnel?
    @start_sauce_tunnel
  end

  def self.parse_yaml(selenium_yml_path)
    raise "[saucelabs-adapter] could not open #{selenium_yml_path}" unless File.exist?(selenium_yml_path)
    @@selenium_configs ||= YAML.load_file(selenium_yml_path)
  end

  private

  def build_configuration(configuration_name)
    selenium_config = @@selenium_configs[configuration_name]
    raise "[saucelabs-adapter] stanza '#{configuration_name}' not found in #{@selenium_yml}" unless selenium_config
    @configuration = selenium_config.reject {|k,v| k == 'localhost_app_server_port'}
    @localhost_app_server_port = selenium_config['localhost_app_server_port']
    if using_tunnel? && use_sauce_tunnel?
      raise "localhost_app_server_port is required if we are starting a tunnel (selenium_server_address is 'saucelabs.com' and application_address is not set)" unless @localhost_app_server_port
      @start_sauce_tunnel = true
      # We are using Sauce Labs and therefore the Sauce Tunnel.
      # We need to use a masquerade hostname on the EC2 end of the tunnel that will be unique within the scope of
      # this account (e.g. pivotallabs).  Therefore we mint a fairly unique hostname here.
      hostname = Socket.gethostname.split(".").first
      @configuration['application_address'] = "#{hostname}-#{Process.pid}.com"
    end
  end

  def selenium_client_driver_args
    {
      :host => self['selenium_server_address'],
      :port => self['selenium_server_port'],
      :browser => self['selenium_browser_key'],
      :url => "http://#{self['application_address']}:#{self['application_port']}",
      :timeout_in_seconds => 60
    }
  end
end
