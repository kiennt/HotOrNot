# ecoding: utf-8
################################################################################
# Copyright 2012 Kien Nguyen Trung
# Filename: autocomplete.rb
# Create: 2012/03/22
# Author: Nguyen Trung Kien (kiennt)
#
# Purpose:
# Create autocomplemte database for redis
#
# Build database to store autocomplete data
# In case we want to build autocomple for name of User
# With each User which has id and name, we make a list of prefix
# for name, and make sorted set to store user id related to it
# Ex: User { :id => 12512, :name => "Kien" }
# We make 4 sorted se
#   fbhot:index:name:k (12512)
#   fbhot:index:name:ki (12512)
#   fbhot:index:name:kie (12512)
#   fbhot:index:name:kien (12512)
#
# When we want to list of 10 user id for name `xxx`, we can get by using
#   zrange fbhot:index:name:xxx 0, 10
# When we want to list of 10 user id for name `xxx` and `yyy' we using 
# First we build a cache for that query, and set it expire in some minutes
#   zinterstore fbhot:index:name:xxx|yyy fbhot:index:name:xxx fbhot:index:name:yyy
# And get number of id by zrange again
#
# More details can found at
#   `http://patshaughnessy.net/2011/11/29/two-ways-of-using-redis-to-build-a-nosql-autocomplete-search-index`
################################################################################
require 'redis'
require './model'

#if RUBY_VERSION =~ /1.9/
  #Encoding.default_external = Encoding::UTF_8
  #Encoding.default_internal = Encoding::UTF_8
#end

module FBHot
  class AutoCompleteHelper
    attr_reader :index_name, :expire_time
   
    # constructor
    # index_name - String prefix of all keys contains index
    # expire_time - int time in second cache query will be expire
    # item_per_query - int number of return item per query
    def initialize(index_name = "fb:index:name", expire_time = 600, item_per_query = 15)
      @index_name = index_name
      @expire_time = expire_time
      @item_per_query = item_per_query
    end
    
    # This function convert vietnamese character to corresponding 
    # english character 
    # name - String contain vietnamese character
    # return - String dont contain vietnamese character
    def _convert_vietnamese_to_english(name)
      if name == nil then return end
      name = name.downcase.strip  
      name = name.gsub /[áàảãạâấầẩẫậăắằẳẵặAÀÁẢÃẠÂẤẦẨẪẬĂẮẰẲẴẶ]/, 'a' 
      name = name.gsub /[éèẻẽẹêềếểễệEÉÈẺẼẸÊẾỀỂỄỆ]/, 'e' 
      name = name.gsub /[íìỉĩịIÍÌỈĨỊ]/, 'i' 
      name = name.gsub /[óòỏõọôốồổỗộơớờởỡợOÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢ]/, 'o' 
      name = name.gsub /[úùủũụưứừửữựÚÙỦŨỤƯỨỪỬỮỰ]/, 'u' 
      name = name.gsub /[ýỳỷỹỵÝỲỶỸỴ]/, 'y' 
      name = name.gsub /[Đđ]/, 'd' 
      name = name.gsub /[^a-zA-Z0-9 ]/, ""
      name
    end

    # add index for user with userid and sex
    #
    # userid - String id of user
    # sex - String in ['male', 'female']
    #
    # This function convert user 's name to english name 
    # And then build index for all token of new name
    def add_user_to_index(userid)
      name = FBHot.redis.get "#{userid}:name"
      name = _convert_vietnamese_to_english name
      if name == nil then return end
      name.strip!
      name.split.each do  |token|
        if token.length > 0 then
          # if a token is 'kien' => we make index for 
          # ['ki', 'kie', 'kien', 'ie', 'ien', 'en']
          (0..token.length - 3).each do |i|
            ((i + 1)..token.length - 1).each do |j|
              FBHot.redis.zadd("#{@index_name}:#{token[i..j]}", 0, userid)
            end
          end
        end
      end
    end

    # build index for female 's name database
    # 
    # This function was called at very begining of program
    # After that, everytime we add new users to dabase, only 
    # call `add_user_to_index` to add user 's name to index
    def reset_index
      # delete old database
      FBHot.redis.keys(@index_name).each {|key| FBHot.redis.del key}

      # create new database
      ids = FBHot.redis.zrange 'zusers1', 0, User::count('girls') - 1
      ids.each {|id| add_user_to_index(id)}
    end

    def search(names, page)
      if names.length == 0 then return end
      name_query = names.join '&'
      index_key = "#{@index_name}:#{name_query}"
      # create query cache
      if names.length > 1 and ! FBHot.redis.exists(index_key) then
        FBHot.redis.zinterstore index_key, names.map {|name| "#{@index_name}:#{name}"}
        # set expire time
        FBHot.redis.expire index_key, @expire_time
      end
      
      # return result
      FBHot.redis.zrange index_key, (page - 1) * @item_per_query, page * @item_per_query - 1
    end

  end # end class AutoCompleteHelper
end # end module FBHot

#FBHot::AutoCompleteHelper.new.reset_index
