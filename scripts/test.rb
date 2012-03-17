#!/usr/bin/env ruby
require 'redis'

r = Redis.new
f = File.new('log', 'w')
users = r.smembers "users"
count = 0
users.each do |user|
  pic = r.get "#{user}:pic"
  pic_small = r.get "#{user}:pic_small"
  pic_big = r.get "#{user}:pic_big"
  pic_square = r.get "#{user}:pic"
  sex = r.get "#{user}:sex"
  name = r.get "#{user}:name"
  username = r.get "#{user}:username"
  birthday = r.get "#{user}:birthday"
  email = r.get "#{user}:email"   
  
  if pic != nil and pic.end_with?('.jpg') and 
     pic_small.end_with?('.jpg') and 
     pic_big.end_with?('.jpg') and 
     pic_square.end_with?('.jpg') and
     (sex == "male" or sex == "female") then
    count += 1
  else
    f.write("#{user} #{pic}\n")
    r.del "#{user}:pic"
    r.del "#{user}:pic_big"
    r.del "#{user}:pic_small"
    r.del "#{user}:pic_square"
    r.del "#{user}:sex"
    r.del "#{user}:name"
    r.del "#{user}:username"
    r.del "#{user}:birthday"
    r.del "#{user}:email"
    r.srem "users", user
  end
end

f.close()

puts count
