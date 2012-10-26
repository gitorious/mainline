# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

require "test_helper"

class EmailTest < ActiveSupport::TestCase
  should "default to a pending state" do
    e = Email.create!(:address => "foo@bar.com", :user => users(:johan))
    assert e.pending?
    e.confirm!
    assert e.confirmed?
  end

  should "send an email confirmation on create" do
    email = Email.new(:address => "foo@bar.com", :user => users(:johan))
    Mailer.expects(:deliver_new_email_alias).with(email).returns(true)
    email.save!
  end

  should "set a confirmation_code on create" do
    email = Email.create!(:address => "foo@bar.com", :user => users(:johan))
    assert_match /^[a-z0-9]{40}$/, email.confirmation_code
  end

  should "confirm an email adress" do
    email = Email.create!(:address => "foo@bar.com", :user => users(:johan))
    email.confirm!
    assert_nil email.confirmation_code
  end

  should "find confirmed email by address" do
    email = Email.create!(:address => "foo@bar.com", :user => users(:johan))
    assert_nil Email.find_confirmed_by_address("foo@bar.com")
    email.confirm!
    assert email.reload.confirmed?
    assert_equal email, Email.find_confirmed_by_address("foo@bar.com")
  end
end
