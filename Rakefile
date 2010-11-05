require "rubygems"
require "bundler"
Bundler.setup
Bundler.require :default

require 'spec'
require 'spec/rake/spectask'

desc 'Default: run unit tests.'
task :default => :spec

desc 'Test the saucelabs_adapter plugin.'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib'
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "saucelabs_adapter"
    gem.summary = %Q{Adapter for running Selenium tests using SauceLabs.com}
    gem.description = %Q{This gem augments Test::Unit and Polonium/Webrat to run Selenium tests in the cloud. }
    gem.email = "pair+kelly+sam@pivotallabs.com"
    gem.homepage = "http://github.com/pivotal/saucelabs_adapter"
    gem.authors = ["Kelly Felkins, Chad Woolley, Sam Pierson, Nate Clark"]
    gem.files = [
      "LICENSE",
      "README.rdoc",
      "Rakefile",
      "VERSION",
      Dir['lib/**/*.*'],
      Dir['generators/**/*.*'],
    ].flatten
    gem.add_dependency 'rest-client', '>= 1.5.0'
    gem.add_dependency 'net-ssh', '>= 2.0.12'
    gem.add_dependency 'net-ssh-gateway', '>= 1.0.1'
    gem.add_dependency 'selenium-client', '>= 1.2.17'
    gem.add_dependency 'lsof', '>= 0.3.0'
    gem.add_dependency 'json', '>= 1.4.3'
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
  rdoc.title = "saucelabs_adapter #{version}"
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
