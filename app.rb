require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require './model.rb'

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
    
    ## 
    # create pagination 
    #
    # parameter
    #   * prefix_link - String the fixed part in link
    #   * current_page - int current page will show in active state
    #   * last_page - int max page of this paginate
    #
    # Link in pagination has format {link}:{page}
    # Use this function like this
    #   >>> paginate('/gallery/boys/', 10, 100)
    # This will create pagination from page 5 to page 15 
    #
    def paginate(prefix_link, current_page, last_page)
      num_of_page = 15
      max_page = [current_page + num_of_page/2, last_page].min
      min_page = [1, current_page - num_of_page/2].max
      if max_page ==  last_page then
        min_page = [max_page - num_of_page, min_page].max
      elsif min_page == 1
        max_page = [min_page + num_of_page, max_page].max
      end

      content = "<div class='pagination subnav'><ul>"
      # prev page
      link = current_page > 1 ? "#{prefix_link}/#{current_page - 1}" : "#"
      content << "<li><a href='#{link}'>&lt;&lt;</a></li>" 

      (min_page..max_page).each do |page|
        style = page == current_page ? "class='active' " : ""
        content << "<li #{style}><a href='#{prefix_link}/#{page}'>#{page}</a></li>" 
      end
      
      # next page
      link = current_page < last_page ? "#{prefix_link}/#{current_page + 1}" : "#"
      content << "<li><a href='#{link}'>&lt;&lt;</a></li>" 

      content << "</ul></div>"
    end
    alias_method :p, :paginate

  end

  # we dont want to show Server information
  # modify server header after process
  after do
    response.headers["Server"] = 'nginx'
  end

  # create redis client and title 
  before do
    @title = 'Hot or Not'
  end

  error 404 do
    erb :notfound
  end 

  get '/' do
    redirect '/gallery/girls/1'
  end 

  get '/gallery/:sex/:page' do
    if ['girls', 'boys'].include? params[:sex] then
      @sex = params[:sex]
      @page = params[:page].to_i

      if @page <= 0 then 
        redirect "/gallery/#{params[:sex]}/1"
      else

        @count = User::count @sex
        @last_page = (@count - 1)/User::item_per_page + 1
        
        @users = User::get_list_users_in_page @sex, @page
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

  ['/vote/:sex', '/vote/:sex/:id'].each do |url|
    get url do
      if ['girls', 'boys'].include? params[:sex] then
        @sex = params[:sex]
        # get user1
        if params[:id].nil? then
          @user1 = User::get_random_user(@sex) 
        else
          @user1 = User.new(params[:id])
        end
        
        # get user2
        if @user1.valid? then
          @user2 = User::get_random_user(@sex, @user1.rank)
          erb :vote 
        else
          404
        end
      else
        404
      end
    end  
  end

  get '/info.json/:id' do
    content_type :json
    @user = User.new params[:id]
    if @user.valid? then
      {:id => @user.id, :pic => @user.pic_big, :name => @user.name, 
       :win => @user.win_count, :lose => @user.lose_count}.to_json
    else
      {:error => 'key not found'}.to_json
    end
  end
  
  get '/del.json/:sex/:id' do
    content_type :json
    if ["boys", "girls"].include? params[:sex] then
      user_to_del = User.new params[:id]
      user_to_del.delete
      @user = User::get_random_user(params[:sex], user_to_del.id)
      {:id => @user.id, :pic => @user.pic_big, :name => @user.name, 
       :win => @user.win_count, :lose => @user.lose_count}.to_json
    else
      {:err => 'sex must be boys or girls'}.to_json
    end
  end

  get '/vote.json/:sex/:win/:lose' do
    content_type :json
    if ["boys", "girls"].include? params[:sex] then
      # update score
      User::update_score(params[:win], params[:lose]) 
      # find other random id 
      @user = User::get_random_user(params[:sex], params[:lose])
      {:id => @user.id, :pic => @user.pic_big, :name => @user.name, 
       :win => @user.win_count, :lose => @user.lose_count}.to_json
    else
      {:err => 'sex must be boys or girls'}.to_json
    end
  end
end
