require 'rake'
require 'dm-migrations'
require './models'

namespace :db do
  task :migrate do
    DataMapper.auto_migrate!
  end
end
