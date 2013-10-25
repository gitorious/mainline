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
require "update_user"

class UpdateUserTest < ActiveSupport::TestCase
  def setup
    @user = users(:moe)
  end

  should "expire the cache when the avatar is changed" do
    @user.update_attribute(:avatar_file_name, "foo.png")
    @user.update_attribute(:avatar_updated_at, 2.days.ago)

    assert_avatars_expired(@user) do
      avatar = File.new(Rails.root + 'test/fixtures/avatars/git.png')
      outcome = UpdateUser.new(@user).execute(:avatar => avatar)

      assert outcome.success?, outcome.to_s
    end
  end

  def assert_avatars_expired(user, &block)
    user.avatar.styles.keys.each do |style|
      (user.email_aliases.map(&:address) << user.email).each do |email|
        cache_key = User.email_avatar_cache_key(email, style)
        Rails.cache.expects(:delete).with(cache_key)
      end
    end
    yield
  end
end
