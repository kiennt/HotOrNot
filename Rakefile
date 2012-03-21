require 'rake'

namespace :server do
  task :restart do
    puts "Stop thin development server"
    `thin stop -C /etc/thin/fbhot_dev.yml`
    puts "Start thin development server"
    `thin start -C /etc/thin/fbhot_dev.yml`
  end
end
