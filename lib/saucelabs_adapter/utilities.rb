module SaucelabsAdapter
  module Utilities

    def diagnostics_prefix
      @diagnostics_prefix ||= '[saucelabs-adapter]'
    end

    def say(what)
      STDOUT.puts "#{diagnostics_prefix} #{what}"
    end

    def debug(what, print_if_level_ge = 0)
      if ENV['SAUCELABS_ADAPTER_DEBUG']
        actual_level = ENV['SAUCELABS_ADAPTER_DEBUG'].to_i
        STDOUT.puts "#{diagnostics_prefix}   #{what}" if print_if_level_ge >= actual_level
      end
    end

    def raise_with_message(message)
      raise "#{diagnostics_prefix} #{message}"
    end
  end
end