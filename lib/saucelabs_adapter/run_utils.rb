class RunUtils
  def self.run(command, options = {})
    default_options = {
      :raise_on_fail => true
    }
    options = default_options.merge(options)
    puts "Executing: #{command}"
    success = system(command)
    if !success && options[:raise_on_fail]
      raise "Command failed: #{command}"
    end
    success
  end
end