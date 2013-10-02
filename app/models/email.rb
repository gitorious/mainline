# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
require "validators/email_validator"

class Email < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user, :address
  validates_format_of :address, :with => EmailValidator::EMAIL_FORMAT
  validates_length_of :address, :within => 5..255
  validates_uniqueness_of :address, :scope => "user_id", :case_sensitive => false

  attr_accessible :address

  before_create :set_confirmation_code
  after_create :send_confirmation_email

  state_machine :aasm_state, :initial => :pending do
    after_transition :on => :confirm do |email, transition|
      email.confirmation_code = nil
    end
    state :pending
    state :confirmed
    event :confirm do
      transition :pending => :confirmed
    end
  end

  scope :in_state, lambda {|*states| {:conditions => {:aasm_state => states}}}

  def self.find_confirmed_by_address(addr)
    with_aasm_state(:confirmed).first(:conditions => {:address => addr})
  end

  protected
  def send_confirmation_email
    Mailer.new_email_alias(self).deliver
  end

  def set_confirmation_code
    confirmation = "#{user_id}:#{id}:#{Time.now.to_f}#{rand(666)}"
    self.confirmation_code = Digest::SHA1.hexdigest(confirmation)
  end
end
