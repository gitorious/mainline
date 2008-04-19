class Committership < ActiveRecord::Base
  belongs_to :user
  belongs_to :repository
  has_many   :events, :as => :target, :dependent => :destroy
  
  KIND_ACCESS_NONE  = 0
  KIND_ACCESS_READ  = 1
  KIND_ACCESS_WRITE = 2
end
