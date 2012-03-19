require 'rubygems'
require 'sinatra'
require 'erb'
require 'redis'
require 'json'
require './models.rb'

class App < Sinatra::Base
  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    def url_path(*path_parts)
      [path_prefix, path_parts].join("/").squeeze('/')
    end
    alias_method :u, :url_path

    def path_prefix
      request.env['SCRIPT_NAME']
    end
  end

  # we dont want to show Server information
  # modify server header after process
  after do
    response.headers["Server"] = 'nginx'
  end

  # create redis client and title 
  before do
    @redis = Redis.new
    @title = 'Hot or Not'
  end

  error 404 do
    erb :notfound
  end 

  # get user information form redis server
  def get_users_from_redis(sex, page)
    set_name = sex == "boys" ? "zusers0" : "zusers1"
    user_ids = @redis.zrange set_name, (page - 1) * @pics_per_page, (page * @pics_per_page - 1) 
    users = []
    user_ids.each do |userid|
      users << User::get_from_redis(userid, @redis) 
    end
    users
  end

  get '/' do
    #erb :static
    redirect '/gallery/girls/1'
  end 

  get '/gallery/:sex/:page' do
    if ['girls', 'boys'].include? params[:sex] then
      @sex = params[:sex]
      @page = params[:page].to_i
      if @page <= 0 then 
        redirect "/gallery/#{params[:sex]}/1"
      else
        setname = @sex == 'boys' ? 'zusers0' : 'zusers1'
        @count = @redis.zcard setname
        @pics_per_page = 100
        @users = get_users_from_redis(@sex, @page)
        if @users.length > 0 then
          erb :gallery
        else
          redirect "/gallery/#{params[:sex]}/1"
        end
      end
    else
      404
    end
  end

  def min(x, y) 
    x > y ? y : x
  end

  def max(x, y)
    x > y ? x : y
  end

  def get_random_userid(sex, idx = nil)
    idx = idx.to_i if idx != nil
    setname = sex == 'boys' ? 'zusers0' : 'zusers1' 
    usercount = @redis.zcard setname
    min_idx = idx == nil ? 0 : idx - 50 
    minx_idx = max(min_idx, 0)
    max_idx = idx == nil ? usercount : idx + 50 
    max_idx = min(max_idx, usercount)
    while true do
      #id = rand(min_idx..max_idx)  
      id = rand(usercount)
      if id != idx then break end
    end
    [id, @redis.zrange(setname, id, id)[0]]
  end

  get '/vote/:sex' do
    if ['girls', 'boys'].include? params[:sex] then
      @sex = params[:sex]
      idx1, @userid1 = get_random_userid(@sex)
      idx1, @userid2 = get_random_userid(@sex, idx1)
      erb :vote 
    else
      404
    end
  end

  get '/vote/:sex/:id' do
    if ['girls', 'boys'].include? params[:sex] then
      @sex = params[:sex]
      zset = @sex == 'boys' ? 'zusers0' : 'zusers1'
      @userid1 = params[:id]
      if @redis.zrank(zset, @userid1) != nil then
        idx1 = @redis.zrank(@sex, @userid1)
        idx1, @userid2 = get_random_userid(@sex, idx1)
        erb :vote 
      else
        404
      end
    else
      404
    end
  end

  get '/info.json/:userid' do
    content_type :json
    @id = params[:userid]
    if @redis.sismember('users', @id) then
      @pic = @redis.get "#{@id}:pic_big"
      {:id => @id.to_s, :pic => @pic}.to_json
    else
      {:error => 'key not found'}.to_json
    end
  end
  
  get '/del.json/:sex/:id' do
    content_type :json
    if ["boys", "girls"].include? params[:sex] then
      id = params[:id]
      
      # add in set delete
      setname = params[:sex] == 'boys' ? 'sdusers0' : 'sdusers1'
      @redis.sadd setname, id
      
      # delete in sorted set
      setname1 = params[:sex] == 'boys' ? 'zusers0' : 'zusers1'
      rank = @redis.zrank setname1, id
      p = @redis.zremrangebyrank setname1, rank, rank

      # find other random id 
      idx1, @userid = get_random_userid(params[:sex], id) 
      {:id => @userid, :pic => @redis.get("#{@userid}:pic_big")}.to_json
    else
      {:err => 'sex must be boys or girls'}.to_json
    end
  end

  get '/vote.json/:sex/:win/:lose' do
    content_type :json
    if ["boys", "girls"].include? params[:sex] then
      setname = params[:sex] == "boys" ? "zusers0" : "zusers1"
      
      # implement elo ranking
      win_id = params[:win]    
      r_win = @redis.zscore(setname, win_id).to_i 
      k_win = r_win < 2400 ? 15 : 10
      q_win = 10 ** (r_win/400)

      lose_id = params[:lose]
      r_lose = @redis.zscore(setname, lose_id).to_i
      k_lose = r_lose < 2400 ? 15 : 10
      q_lose = 10 ** (r_lose/400)

      e_win = q_win * 1.0/(q_win + q_lose)
      e_lose = q_lose * 1.0/(q_win + q_lose)
      del_win = (k_win * (1 - e_win)).to_i
      del_lose = (k_lose * (0 - e_lose)).to_i
      @redis.zincrby setname, del_win, win_id 
      @redis.zincrby setname, del_lose, lose_id 
          
      # find other random id 
      idx1, @userid = get_random_userid(params[:sex], win_id) 
      {:id => @userid, :pic => @redis.get("#{@userid}:pic_big")}.to_json
    else
      {:err => 'sex must be boys or girls'}.to_json
    end
  end
end
