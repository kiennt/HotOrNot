require 'redis'
require 'json'

module FBHot
  @@redis = Redis.new
  
  def self.redis
    return @@redis
  end

  class User
    attr_reader :id
    @@zdict = { "male" => "zusers0", "female" => "zusers1", "boys" => "zusers0", "girls" => "zusers1" } 
    @@sdict = { "male" => "sdusers0", "female" => "sdusers1" }
    @@item_per_page = 100

    def initialize(id) @id = id end
    
    def sex 
      @sex ||= FBHot.redis.get("#{@id}:sex") 
    end
    
    def pic_square 
      @pic_square ||= FBHot.redis.get("#{@id}:pic_square") 
    end

    def pic_big 
      @pic_big ||= FBHot.redis.get("#{@id}:pic_big") 
    end
    
    def name 
      @name ||= FBHot.redis.get("#{@id}:name").force_encoding("utf-8") 
    end

    def score 
      @score ||= FBHot.redis.zscore(@@zdict[sex], @id) 
    end
    
    def rank 
      @rank ||= FBHot.redis.zrank(@@zdict[sex], @id) 
    end
    
    def win_count 
      @win_count ||= FBHot.redis.get("#{@id}:win_count") 
    end

    def lose_count 
      @lose_count ||= FBHot.redis.get "#{@id}:lose_count" 
    end

    def add_score(delta)
      FBHot.redis.zincrby @@zdict[sex], delta, @id
      if delta > 0 then
        FBHot.redis.incr "#{@id}:win_count" 
      elsif delta < 0  then
        FBHot.redis.incr "#{@id}:lose_count" 
      end
    end

    def delete
      # add to delete set
      FBHot.redis.sadd @@sdict[sex], @id
      # delete from sorted set 
      FBHot.redis.zremrangebyrank @@zdict[sex], rank, rank
    end
    
    def to_json
        {:id => self.id, :pic => self.pic_big, :name => self.name, 
         :win => self.win_count, :lose => self.lose_count}.to_json
    end

    def valid? 
      score != nil 
    end 
   
    def self.item_per_page  
      @@item_per_page 
    end 

    def self.count(sex) 
      FBHot.redis.zcard(@@zdict[sex]) 
    end  

    def self.get_list_users_by_ids(ids)
      users = []
      ids.each {|id| users << User.new(id) }
      users
    end

    def self.get_list_users_in_page(sex, page)
      ids = FBHot.redis.zrange @@zdict[sex], (page - 1) * @@item_per_page, page * @@item_per_page - 1
      FBHot::User::get_list_users_by_ids ids
    end  
    
    def self.get_random_user(sex, other_rank = nil)
      while true do
        rank = rand(User::count sex) 
        if rank != other_rank then break end
      end     
      id = FBHot.redis.zrange(@@zdict[sex], rank, rank)[0] 
      User.new id
    end
  
    # Update score of 2 user by Elo ranking system
    #
    # win_id: String id of winner
    # lose_id: String id of loser
    def self.update_score(win_id, lose_id)
      win = User.new(win_id)
      win_K = win.rank < 2400 ? 15 : 10
      win_Q = 10 ** (win.rank / 400)

      lose = User.new(lose_id)
      lose_K = lose.rank < 2400 ? 15 : 10
      lose_Q = 10 ** (win.rank / 400)
    
      win_E = win_Q * 1.0 / (win_Q + lose_Q)
      win_D = win_K * (1 - win_E) 
      win.add_score win_D.to_i 
      
      lose_E = lose_Q * 1.0 / (win_Q + lose_Q)
      lose_D = lose_K * (0 - lose_E)
      lose.add_score lose_D.to_i
    end
  end # end class
end # end module
