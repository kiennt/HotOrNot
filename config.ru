require 'rubygems'
require 'bundler'

Bundler.require

require './app'
run FBHot::App
require 'newrelic_rpm'
NewRelic::Agent.manual_start :app_name => 'FBHot', :agent_enabled => true
