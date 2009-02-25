class Email < ActiveRecord::Base
  belongs_to :user
  
  FORMAT = /^[^@\s]+@([\-a-z0-9]+\.)+[a-z]{2,}$/i
  validates_presence_of :user, :address
  validates_format_of   :address, :with => FORMAT
  validates_length_of   :address, :within => 5..255
  validates_uniqueness_of :address, :scope => "user_id", :case_sensitive => false
  
  attr_protected :aasm_state, :user_id, :confirmation_code
  
  before_create :set_confirmation_code
  after_create :send_confirmation_email
  
  include AASM
  aasm_initial_state :pending

  aasm_state :pending
  aasm_state :confirmed
  
  aasm_event :confirm, :success => proc{|e| e.confirmation_code = nil } do
    transitions :to => :confirmed, :from => [:pending]
  end
  
  protected
    def send_confirmation_email
      Mailer.deliver_new_email_alias(self)
    end
    
    def set_confirmation_code
      self.confirmation_code = Digest::SHA1.hexdigest(
        "#{user_id}:#{id}:#{Time.now.to_f}#{rand(666)}"
      )
    end
end
