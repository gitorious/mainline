# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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
require "ssh_key_test_helper"

class AdminKeysTest < ActionDispatch::IntegrationTest
  include CapybaraTestCase
  include SshKeyTestHelper

  def login_as(user)
    visit login_path
    fill_in 'Email or login', :with => user.email
    fill_in 'Password', :with => 'test'
    click_button 'Log in'
  end

  setup do
    admin = users(:johan)
    login_as(admin)
    @moe = users(:moe)
    visit admin_users_path

    within("#user-#{@moe.id}") do
      click_on 'Manage Ssh Keys'
    end
    page.must_have_content("Manage moe's SSH keys")
  end

  should "add new ssh key for user" do
    click_on 'Add new'
    page.must_have_content('Add new public SSH key')
    find('textarea').set(valid_key)
    click_on 'Save'
    page.must_have_content('Key added')
  end

  should "delete user's ssh key" do
    ssh_key = @moe.ssh_keys.first

    within("#ssh-key-#{ssh_key.id}") do
      click_on 'delete'
    end

    page.must_have_content('Key removed')
  end
end
