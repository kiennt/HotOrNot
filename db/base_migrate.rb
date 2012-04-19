require 'redis'

module Migrate
  class BaseClass
    def initialize
      @redis = Redis.new
    end

    def get_usage_memory
      @redis.info()["used_memory_human"]
    end
  end
end
