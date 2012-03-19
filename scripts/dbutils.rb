#!/usr/bin/env ruby
require 'face'
require 'redis'

DEBUG = false

def detect(setqueue, redis, api_key, api_secret)
  def remove_id(redis, setname, id)
    rank = redis.zrank setname, id
    redis.zremrangebyrank setname, rank, rank
  end
  
  client = Face.get_client(:api_key => api_key, :api_secret => api_secret)
  while redis.scard(setqueue) > 0 do
    begin
      id = redis.spop setqueue
      rank1 = redis.zrank 'zusers1', id
      rank2 = redis.zrank 'zusers0', id
      if rank1 == nil and rank2 == nil then 
        continue 
      end

      url = redis.get "#{id}:pic_big"
      sex = redis.get "#{id}:sex"
      setname = sex == "male" ? "zusers0" : "zusers1"
      data = client.faces_detect(:urls => url)    
      
      if data["status"] == "failure" then
        redis.sadd setqueue, id
        puts data
        sleep 600
      else
        if data["photos"][0]["tags"].length != 1 then
          puts "%s: %s" % [sex, id] if DEBUG
          remove_id redis, setname, id
        else
          attrs = data["photos"][0]["tags"][0]["attributes"]
          if attrs["gender"] == nil or attrs["gender"]["value"] != sex then
            remove_id redis, setname, id
          end
          puts "------------- has face: %s" % [id] if DEBUG
        end
        
        if data["usage"]["remaining"].to_i == 0 then
          puts "%s: %s"  % [api_key, data["usage"]["remaining"]]
          puts data
          sleep 600
        end 
      end
    rescue
    end
  end 
end

def initdb()
  puts "Init db"
  redis = Redis.new
  redis.del 'userqueue'
  setname = 'zusers0'
  count = redis.zcard setname
  list_id = redis.zrange setname, 0, count
  list_id.each {|id| redis.sadd 'userqueue', id}
end

def main()
  redis = Redis.new
  t1 = Thread.new { detect("userqueue", redis, 'b79b43d2caba8cb16881d5cd10ee3a27', 'e52fe230843fbc1d46d054e6f04180f6') }
  t2 = Thread.new { detect("userqueue", redis, '781f0ad14b85daf7e3def8d3648d6a1c', '0251857fb3b7aa4494897068f2c73e26') }
  t3 = Thread.new { detect("userqueue", redis, '16ab49761fec780b38546bee2e27968c', '1479d22c7a7fe00ff6daea101259d532') }
  t1.join
  t2.join
  t3.join
end

puts ARGV
if ARGV.length >= 1 then
  cmd = ARGV[0]
  if cmd == 'db' then initdb() end
end
main()
