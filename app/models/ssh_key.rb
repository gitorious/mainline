class SshKey < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of :user_id, :key
  validates_format_of   :key, :with => /^ssh-[a-z0-9]{3,4} .+$/ims
  
  before_save :lint_key!
  
  def display_key(cols=72)
    key.gsub(/(.{1,#{cols}})/, "\\1\n").strip
  end
  
  
  protected
    def lint_key!
      key.gsub!(/\n+/ms, "")
    end
end
