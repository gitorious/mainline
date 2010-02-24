# encoding: utf-8
#--
#   Copyright (C) 2010 Marius Mathiesen <marius@shortcut.no>
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

require 'test_helper'

class HookTest < ActiveSupport::TestCase
  should_belong_to :repository
  should_validate_presence_of :user, :repository, :url

  context "URL validation" do
    should "require a valid URL" do
      hook = Hook.new(:url => "http:/gitorious.org/web-hooks")
      assert !hook.valid?
      assert_not_nil hook.errors.on(:url)
    end

    should "require http URLs" do
      hook = Hook.new(:url => "https://gitorious.org/web-hooks")
      assert !hook.valid?
      assert_not_nil hook.errors.on(:url)
    end
  end
end
