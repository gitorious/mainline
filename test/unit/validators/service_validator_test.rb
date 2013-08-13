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

class ServiceValidatorTest < MiniTest::Spec
  include DataBuilderHelpers

  it "validates presence of user and url" do
    result = ServiceValidator.call(build_web_hook)

    refute result.valid?
    assert result.errors[:user]
    assert result.errors[:url]
  end

  it "requires repository for regular users" do
    result = ServiceValidator.call(build_web_hook(:user => User.new))

    refute result.valid?
    assert result.errors[:repository]
  end

  it "does not require repository for site admins" do
    Gitorious::App.stubs(:site_admin?).returns(true)
    result = ServiceValidator.call(build_web_hook(:user => User.new, :url => "http://somewhere.com"))

    assert result.valid?
  end

  def web_hook(url)
    build_web_hook(:user => User.new, :repository => Repository.new, :url => url)
  end
end
