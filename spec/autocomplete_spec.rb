require 'spec_helper'

describe "auto complete" do
  before :all do
    @ac = FBHot::AutoCompleteHelper.new("fb:index:name", 600, 3)
  end

  it "search an simple query and return info" do
    results = ["100000030357081", "100000089403730", "100000103942759"]
    ids = @ac.search(["kien"], 1) 
    ids.should == results
  end

  it "search complex query and cache result" do
    query = ["yeu", "em"]
    query_key = "#{@ac.index_name}:#{query.join("&")}"
    FBHot.redis.del query_key
    ids = @ac.search(query, 1)
    FBHot.redis.exists(query_key).should == true
    FBHot.redis.ttl(query_key).should == @ac.expire_time
    ids.should == ["100000079688032", "100000728676409", "100000885652660"]  
  end

  it "search wrap" do
    ids1 = FBHot.redis.zrange "#{@ac.index_name}:kien", 0, -1
    ids2 = FBHot.redis.zrange "#{@ac.index_name}:kie", 0, -1
    check = false
    ids1.each {|id| check ||= ids2.include? id}
    check.should == true
    ids3 = FBHot.redis.zrange "#{@ac.index_name}:ien", 0, -1
    ids1.each {|id| check ||= ids3.include? id}
    check.should == true
  end
end
