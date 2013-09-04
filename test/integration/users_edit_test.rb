# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class UserEditTest < ActionDispatch::IntegrationTest
  include SshKeyTestHelper

  def login_as(name)
    user = users(name)
    visit edit_user_path(@user)
    page.must_have_content('Action requires login')
    fill_in 'Email or login', :with => user.email
    fill_in 'Password', :with => 'test'
    click_button 'Log in'
  end

  def change_tab(name)
    within('.nav-tabs') { click_on(name) }
    assert_active_tab(name)
  end

  def assert_active_tab(name)
    page.must_have_selector('.active a', :text => name)
  end

  setup do
    Capybara.default_driver = :poltergeist

    @user = users(:johan)
    login_as(:johan)
    visit edit_user_path(@user)

    # FIXME: this should not be required in an integration test
    SshKeyValidator.any_instance.stubs(:valid_key_using_ssh_keygen?).returns(true)
  end

  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  should "update user details" do
    fill_in 'Full name', :with => 'Johan Johanson'
    click_on 'Save'
    page.must_have_content 'Your account details were updated'
    page.must_have_selector('input[value="Johan Johanson"]')
  end

  should "update user password" do
    change_tab('Change password')
    fill_in 'Current Password', :with => 'test'
    fill_in 'New password', :with => 'test2'
    fill_in 'Confirm password', :with => 'test2'
    within("#edit_user_#{@user.id}") { find('input[type=submit]').click }
    page.must_have_content('Your password has been changed')
  end

  should "delete ssh key" do
    change_tab('SSH keys')
    # TODO: why on earth does it fail in the test only?
    pending 'deleting keys fail in the test'
    click_on 'delete'
    page.must_have_content('Key was deleted')
  end

  should "add new ssh key" do
    change_tab('SSH keys')
    click_on 'Add new'
    page.must_have_content('Add new public SSH key')
    within('#new_ssh_key') do
      find('textarea').set(valid_key)
      click_on 'Save'
    end
    page.must_have_content('Key added')
  end

  should "turn on/off notifications for a watched project" do
    change_tab('Manage favorites')
    within('.table') do
      click_on 'off'
      page.must_have_content('on')
      click_on 'on'
      page.must_have_content('off')
      click_on 'Unwatch'
    end
    page.must_have_content('You no longer watch this repository')
  end

end
