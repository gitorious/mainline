class LdapGroup < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "user_id"
  has_many(:repositories, :as => :owner, :conditions => ["kind NOT IN (?)",
                                                         Repository::KINDS_INTERNAL_REPO],
           :dependent => :destroy)

  has_many :projects, :as => :owner
  has_many :committerships, :as => :committer, :dependent => :destroy

  
  Paperclip.interpolates('group_name'){|attachment,style| attachment.instance.name}

  avatar_local_path = '/system/group_avatars/:group_name/:style/:basename.:extension'
  has_attached_file :avatar,
    :default_url  =>'/images/default_group_avatar.png',
    :styles => { :normal => "300x300>", :medium => "64x64>", :thumb => '32x32>', :icon => '16x16>' },
    :url => avatar_local_path,
    :path => ":rails_root/public#{avatar_local_path}"



  
  def members
    []
  end
  
  def to_param
    name
  end

  def breadcrumb_parent
    nil
  end
  
  def title
    name
  end

  def user_role(candidate)
    if candidate == creator
      Role.admin
    end
  end

  
end
