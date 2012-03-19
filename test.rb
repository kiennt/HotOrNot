require 'redis'

class User
  attr_reader :id
  @@redis = Redis.new
  @@zdict = { "male" => "zusers0", "female" => "zusers1", "boys" => "zusers0", "girls" => "zusers1" } 
  @@sdict = { "male" => "sdusers0", "female" => "sdusers1" }
  @@item_per_page = 100

  def initialize(id)
    @id = id
  end

  def sex
    @sex ||= @@redis.get "#{@id}:sex"
  end
  
  def pic_square
    @pic_square ||= @@redis.get "#{@id}:pic_square"
  end

  def pic_big
    @pic_big ||= @@redis.get "#{@id}:pic_big"
  end

  def score
    @score ||= @@redis.zscore @@zdict[sex], @id
  end
  
  def rank
    @rank ||= @@redis.zrank @@zdict[sex], @id
  end
  
  def add_score(delta)
    @@redis.zincrby @@zdict[sex], delta, @id
  end

  def delete
    # add to delete set
    @@redis.sadd @@sdict[sex], @id
    # delete from sorted set 
    @@redis.zremrangebyrank @@zdict[sex], rank, rank
  end

  def valid?
    score != nil
  end 
  
  def self.count(sex)
    @@redis.zcard @@zdict[sex]
  end  

  def self.get_list_users_in_page(sex, page)
    ids = @@redis.zrange @@zdict[sex], (page - 1) * @@item_per_page, page * @@item_per_page - 1
    users = []
    ids.each {|id| users << User.new(id) }
    users
  end  
  
  def self.get_random_user(sex, other_id = nil)
    while true do
      id = rand(User::count) 
      if id != other_id then break end
    end     
    User.new(id)
  end
  
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
end
