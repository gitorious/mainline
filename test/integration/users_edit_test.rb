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
  include CapybaraTestCase
  js_test

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
    @user = users(:johan)
    login_as(:johan)
    visit edit_user_path(@user)
  end

  should "update user details" do
    assert_active_tab 'Account'
    fill_in 'Full name', :with => 'Johan Johanson'
    click_on 'Save'
    page.must_have_content 'Your account details were updated'
    page.must_have_selector('input[value="Johan Johanson"]')
  end

  should "show errors when trying to save invalid user details" do
    email = find('#user_email')
    email.set('')
    click_on 'Save'
    page.must_have_content 'Failed to save your details'
    page.must_have_content('E-mail is invalid')
    email.set('new_email@gitorious.test')
    click_on 'Save'
    page.must_have_content('Your account details were updated')
    page.must_have_selector('input[value="new_email@gitorious.test"]')
  end

  should "show user email aliases" do
    change_tab('Email aliases')
    page.must_have_content(@user.email_aliases.first.address)
  end

  should "allow adding new email aliases" do
    change_tab('Email aliases')
    click_on 'Add new'
    find('#email_address').set('new_alias@gitorious.test')
    click_on 'Add alias'
    page.must_have_content('You will receive an email asking you to confirm ownership of new_alias@gitorious.test')
  end

  should "show error messages when trying to add an invalid email alias" do
    change_tab('Email aliases')
    click_on 'Add new'
    find('#email_address').set('')
    click_on 'Add alias'
    page.must_have_content("Address can't be blank")
  end

  should "allow deleting email aliases" do
    email = @user.email_aliases.first
    change_tab('Email aliases')
    find("a[data-method='delete'][href='#{user_alias_path(@user, email)}']").click
    assert page.has_content?('Email alias deleted')
    refute page.has_content?(email)
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
    ssh_key = @user.ssh_keys.first

    # for some reason changing tab doesn't work so we visit the page
    visit(user_edit_ssh_keys_path(@user))

    find("a[data-method='delete'][href='#{user_key_path(@user, ssh_key)}']").click

    refute page.has_content?('foo@example.com')
    assert page.has_content?(I18n.t("keys_controller.destroy_notice"))
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
    assert page.has_selector?('.table tbody tr', :count => 0),
      'Unwatched item should be removed from the list'
  end

end
