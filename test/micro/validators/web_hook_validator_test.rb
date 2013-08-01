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
require "fast_test_helper"
require "validators/web_hook_validator"

class WebHookValidatorTest < MiniTest::Spec
  it "validates presence of user and url" do
    result = WebHookValidator.call(WebHook.new)

    refute result.valid?
    assert result.errors[:user]
    assert result.errors[:url]
  end

  it "requires repository for regular users" do
    result = WebHookValidator.call(WebHook.new(:user => User.new))

    refute result.valid?
    assert result.errors[:repository]
  end

  it "does not require repository for site admins" do
    Gitorious::App.stubs(:site_admin?).returns(true)
    result = WebHookValidator.call(WebHook.new(:user => User.new, :url => "http://somewhere.com"))

    assert result.valid?
  end

  it "requires valid http (or https) URL" do
    refute WebHookValidator.call(web_hook("http")).valid?
    refute WebHookValidator.call(web_hook("http://")).valid?
    assert WebHookValidator.call(web_hook("https://somewhere.com")).valid?
    assert WebHookValidator.call(web_hook("http://somewhere.com")).valid?
    assert WebHookValidator.call(web_hook("http://somewhere.com:897/somehere")).valid?
  end

  def web_hook(url)
    WebHook.new(:user => User.new, :repository => Repository.new, :url => url)
  end
end
