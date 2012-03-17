require 'rubygems'
require 'sinatra'
require 'erb'
require 'redis'
require 'json'
require './models.rb'

## CONTROLLER ACTIONS
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
    response.headers["Server"] = 'ASP Server'
  end

  # create redis client and title 
  before do
    @redis = Redis.new
    @title = 'Hot or Not'
  end

  error 404 do
    erb :notfound
  end 

  # get user information from mysql db
  def get_users_from_mysql(sex, page)
    User.all(:sex => sex, :limit => @pics_per_page, :offset => (page - 1) * @pics_per_page)
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

  def get_random_userid(sex, idx = nil)
    setname = sex == 'boys' ? 'zusers0' : 'zusers1' 
    usercount = @redis.zcard setname
    while true do
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

  get '/vote.json/:sex/:win/:lose' do
    win = params[:win]    
    lose = params[:lose]    
    content_type :json
    idx1, @userid = get_random_userid(params[:sex], win) 
    {:id => @userid, :pic => @redis.get("#{@userid}:pic_big")}.to_json
  end
end
