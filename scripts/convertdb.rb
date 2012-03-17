#!/usr/bin/env ruby
require 'redis'

def create_mysql_db()
  DataMapper.finalize

  redis = Redis.new
  list_users = redis.smembers "users"
  count = 0

  list_users.each do |user_id|
    name = redis.get("#{user_id}:name")
    if !name or name == 'None' then name = user_id else name = name.force_encoding("utf-8") end

    username = redis.get("#{user_id}:username")
    if !username or username == 'None' then username = user_id else username = username.force_encoding("utf-8") end

    birthday = redis.get("#{user_id}:birthday")
    if !birthday or birthday == 'None' then birthday = '' end

    sex = redis.get("#{user_id}:sex")
    if sex == 'male' then sex = 0 else sex = 1 end
    
    pic = redis.get("#{user_id}:pic") 
    pic_small = redis.get("#{user_id}:pic_small") 
    pic_big = redis.get("#{user_id}:pic_big") 
    pic_square = redis.get("#{user_id}:pic_square") 
    
    if pic.end_with?('.jpg') and pic_small.end_with?('.jpg') and
       pic_big.end_with?('.jpg') and pic_square.end_with?('.jpg') then
      user = User.create(
        :id => user_id,
        :name => name, 
        :username => username,
        :birthday => birthday,
        :pic => pic,
        :pic_small => pic_small,
        :pic_big => pic_big,
        :pic_square => pic_square,
        :sex => sex,
        :email => '')

      if user.saved? then 
        count += 1
        if count % 10000 == 0 then puts count end
      else
        while true
          puts "`%s` `%s` `%s` `%s` `%s` `%s` %s %s %s" % [user_id, name, username, birthday, sex, pic, pic_small, pic_big, pic_square]
          if user.save then break end
          sleep(1)
        end
      end

    end
  end
end

def create_redis_db()
  redis = Redis.new
  user_ids = redis.smembers "users"
  user_ids.each do |userid|
    sex = redis.get "#{userid}:sex"
    if sex == 'male' then
      redis.zadd 'zusers0', 0, userid
    else
      redis.zadd 'zusers1', 0, userid
    end
  end
end


create_redis_db()
