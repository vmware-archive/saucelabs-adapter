require "rubygems"
require "bundler"
Bundler.setup
Bundler.require :default
require 'active_support'
require 'spec'
require "spec/autorun"
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))