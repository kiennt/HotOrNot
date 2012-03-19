require 'dm-core'
#require 'mongo_adapter'
#require 'yaml'
#content = File.read('database.yml')
#settings = YAML::load content

### CONFIGURATION
#DataMapper.setup(:default, {
  #:adapter  => settings['mongod']['adapter'],
  #:host     => settings['mongod']['host'],
  #:username => settings['mongod']['username'],
  #:password => settings['mongod']['password'],
  #:database => settings['mongod']['database'],
  #:encoding => 'UTF-8'})
#DataMapper::Logger.new($stderr, :default)


### MODELS
#DataMapper::Property::String.length(255)

class User
  include DataMapper::Resource

  property :id, Integer, :key => true, :min => 0, :max => 2**64 - 1
  property :name, String
  property :username, String, :required => false
  property :birthday, String, :required => false
  property :pic, String
  property :pic_small, String
  property :pic_big, String
  property :pic_square, String
  property :sex, Boolean, :index => true
  property :email, String

  def self.get_from_redis(id, rc)
    user = User.new
    user.id = id
    user.name = rc.get "#{id}:name"
    user.username = ""
    user.birthday = ""
    user.pic= ""
    user.pic_small = ""
    user.pic_square = rc.get "#{id}:pic_square"
    user.sex = ""
    user.email = ""
    user
  end
end


#DataMapper.finalize
