require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "saucelabs-adapter"
    gem.summary = %Q{Adapter for running Selenium tests using SauceLabs.com}
    gem.description = %Q{This gem augments Test::Unit and Polonium/Webrat to run Selenium tests in the cloud. }
    gem.email = "pair+kelly+sam@pivotallabs.com"
    gem.homepage = "http://github.com/pivotal/saucelabs-adapter"
    gem.authors = ["Kelly Felkins, Chad Woolley & Sam Pierson"]
    gem.files = [
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/sauce_tunnel.rb",
     "lib/saucelabs_adapter.rb",
     "lib/saucelabs-adapter.rb",
     "lib/selenium_config.rb",
     "lib/run_utils.rb",
     "lib/jsunit_selenium_support.rb",
     "lib/saucerest-ruby/saucerest.rb",
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
    gem.add_dependency 'rest-client', '>= 1.0.3'
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

task :default => :test

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

desc "Push gem to gems.pivotallabs.com"
task :deploy => :build do
  gem = `ls pkg/*|tail -1`.strip
  puts "Deploying #{gem}:"
  run "scp #{gem} gems.pivotallabs.com:gems"
  run "ssh gems.pivotallabs.com 'gem generate_index --directory=/var/www/nginx-default >> /home/pivotal/gem_generate_index.log 2>&1'"
end