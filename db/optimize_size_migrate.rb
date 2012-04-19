require './base_migrate'

module Migrate

  # Instead of using many get/set operation on redis database, 
  # we can devide our database into many bucket hashes object
  #
  # Currently, we have ~ 100.000 users, each user have informations
  # { :pic, :sex, :birthday, :pic_square, :pic_big, :pic_small, 
  #   :username, :name, :win_count, :lose_count }
  # We store it in key, value manner. With user has id `124412`, 
  # we can get user informations from `124412:<field>` while <field> is 
  # is the set of user attributes
  # This approach quite costs memory, Redis offer us another way to
  # reduce memory by using Hashes. When Hash object contains small key/value
  # it store like an O(N) data structure, so it is better for store
  # Now we store user like this way:
  # If user has id <id>, we calculate
  #   id_prefix = id / 100
  #   id_suffix = id % 100
  # All User informations will be store in `user:<id_prefix>` hash as 
  # `<id_suffix>:<field>`
  # 
  class OptimizeMemoryClass < Migrate::BaseClass
    @@user_attrs = [:pic, :sex, :birthday, :pic_square, :pic_big, :pic_small, 
      :username, :name, :win_count, :lose_count ]

    def _copy_user_to_hash
      @redis.keys("*:sex").each do |id|
        id = id[0..-5]
        unless id.start_with?("fb")
          prefix_id = id[0..-3]
          suffix_id = id[-2..-1]
          @@user_attrs.each do |attr| 
            attr = attr.to_s
            value = @redis.get "#{id}:#{attr}"
            @redis.hset "user:#{prefix_id}", "#{suffix_id}:#{attr}", value 
          end
        end
      end
    end
    
    def _remove_users
      @redis.keys("*:sex").each do |id|
        id = id[0..-5].to_i
        @@user_attrs.each { |attr| @redis.del "#{id}:#{attr.to_s}" }
      end
    end

    def up
      puts "Current memory #{get_usage_memory}"
      _copy_user_to_hash
      puts "Memory after copy #{get_usage_memory}"
      _remove_users 
      puts "Memory after delete #{get_usage_memory}"
    end

    def _copy_user_from_hash
      @redis.keys("user:*").each do |hash_key|
        prefix_id = hash_key[5..-1]
        @redis.hkeys(hash_key).each do |key|
          if key.end_with?(":name") then
            suffix_id = key[0..-6]
            id = "#{prefix_id}#{suffix_id}"
            @@user_attrs.each do |attr| 
              value = @redis.hget hash_key, "#{suffix_id}:#{attr.to_s}"
              @redis.set "#{id}:#{attr.to_s}", value
            end
          end
        end
      end 
    end

    def _remove_users_from_hash
      @redis.keys("user:*").each { |hash_key| @redis.del hash_key }
    end

    def down
      puts "Current memory #{get_usage_memory}"
      _copy_user_from_hash
      puts "Memory after copy #{get_usage_memory}"
      _remove_users_from_hash
      puts "Memory after delete #{get_usage_memory}"
    end
  end

end

if ARGV.length == 1 and ARGV[0] == "down" then
  Migrate::OptimizeMemoryClass::new().down
else
  Migrate::OptimizeMemoryClass.new().up
end
