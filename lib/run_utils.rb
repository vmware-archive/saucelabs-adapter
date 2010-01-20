class RunUtils
  def self.run(command, options = {})
    default_options = {
      :raise_on_fail => true
    }
    options.reverse_merge!(default_options)
    puts "Executing: #{command}"
    success = system(command)
    if !success && options[:raise_on_fail]
      raise "Command failed: #{command}"
    end
  end
end