module Webrat
  module Selenium
    module ApplicationServers
      class Rails < Webrat::Selenium::ApplicationServers::Base

        def pid_file
          # the ./script/server is starting a server under
          # and it deletes that file on exit
          "#{::Rails.root}/tmp/pids/server.pid"
        end

        def start_command
          "cd #{::Rails.root} && rackup -p #{Webrat.configuration.application_port} --env #{Webrat.configuration.application_environment} --pid #{pid_file} &"
        end

        def stop_command
          "kill -9 `cat #{pid_file}`"
        end
      end

    end
  end
end
