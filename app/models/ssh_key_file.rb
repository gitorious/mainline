# FIXME: this class acts too much like a singleton: read the file contents on
# initialize and mark it as dirty and reload only when needed.
class SshKeyFile
  def initialize(path=nil)
    @path = path || default_authorized_keys_path
  end
  attr_accessor :path
  
  def contents
    File.read(@path)
  end
  
  def add_key(key)
    File.open(@path, "a") do |file|
      file << key
    end
  end
  
  def delete_key(key)
    data = File.read(@path)
    return true unless data.include?(key)
    new_data = data.gsub(key, "")
    File.open(@path, "w") do |file|
      file.puts new_data
    end
  end
  
  protected
    def default_authorized_keys_path
      File.join(File.expand_path("~"), ".ssh", "authorized_keys")
    end
end