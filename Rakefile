require 'rake'

namespace :server do
  task :restart do
    `thin stop -C /etc/thin/fbhot_dev.yml`
    `thin start -C /etc/thin/fbhot_dev.yml`
  end
end
