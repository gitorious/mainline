class Credentials
  attr_accessor :username, :password
  def initialize(username=nil, password=nil)
  end

  def self.from_params(params)
    result = new
    result.username = params["username"]
    result.password = params["password"]
    result
  end
end
