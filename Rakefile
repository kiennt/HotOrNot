require 'rake'
require 'rspec/core/rake_task'

namespace :server do
  task :restart do
    puts "Stop thin development server"
    `thin stop -C /etc/thin/fbhot_dev.yml`
    puts "Start thin development server"
    `thin start -C /etc/thin/fbhot_dev.yml`
  end
end

task :reset do
  require './autocomplete'
  FBHot::AutoCompleteHelper.new.reset_index
end

task :spec do
  RSpec::Core::RakeTask.new do |t|
    t.pattern = "spec/**/*_spec.rb"
    t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
  end
end


task :default => :spec
