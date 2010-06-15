require 'rubygems'
require 'rake'

require 'spec'
require 'spec/rake/spectask'

desc 'Default: run unit tests.'
task :default => :spec

desc 'Test the saucelabs-adapter plugin.'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib'
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "saucelabs-adapter"
    gem.summary = %Q{Adapter for running Selenium tests using SauceLabs.com}
    gem.description = %Q{This gem augments Test::Unit and Polonium/Webrat to run Selenium tests in the cloud. }
    gem.email = "pair+kelly+sam@pivotallabs.com"
    gem.homepage = "http://github.com/pivotal/saucelabs-adapter"
    gem.authors = ["Kelly Felkins, Chad Woolley, Sam Pierson, Nate Clark"]
    gem.files = [
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/saucelabs_adapter.rb",
     "lib/saucelabs-adapter.rb",
     "lib/saucelabs_adapter/utilities.rb",
     "lib/saucelabs_adapter/run_utils.rb",
     "lib/saucelabs_adapter/tunnel.rb",
     "lib/saucelabs_adapter/tunnels/sauce_tunnel.rb",
     "lib/saucelabs_adapter/tunnels/ssh_tunnel.rb",
     "lib/saucelabs_adapter/tunnels/other_tunnel.rb",
     "lib/saucelabs_adapter/selenium_config.rb",
     "lib/saucelabs_adapter/test_unit_adapter.rb",
     "lib/saucelabs_adapter/jsunit_selenium_support.rb",
     "lib/saucerest-ruby/saucerest.rb",
     "lib/saucerest-ruby/gateway.rb",
     "lib/saucerest-python/tunnel.py",
     "lib/saucerest-python/daemon.py",
     "lib/saucerest-python/saucerest.py",
     "lib/saucerest-python/sshtunnel.py",
     "lib/tasks/jsunit.rake",
     "generators/saucelabs_adapter/saucelabs_adapter_generator.rb",
     "generators/saucelabs_adapter/templates/selenium.yml",
     "generators/saucelabs_adapter/templates/saucelabs_adapter.rake",
     "generators/saucelabs_adapter/templates/jsunit.rake",
     "generators/saucelabs_adapter/templates/jsunit_suite_example.rb"
  ]
    gem.add_dependency 'rest-client', '>= 1.2.0'
    gem.add_dependency 'net-ssh', '>= 2.0.12'
    gem.add_dependency 'net-ssh-gateway', '>= 1.0.1'
    gem.add_dependency 'selenium-client', '>= 1.2.17'
    gem.add_dependency 'lsof', '>= 0.3.0'
    # gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

#task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "saucelabs-adapter #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

def run(command)
  puts command
  puts `#{command}`
end

desc "Push gem to gemcutter.org"
task :deploy => :build do
  gem = `ls pkg/*|tail -1`.strip
  puts "Deploying #{gem}:"
  run "gem push #{gem}"
end
