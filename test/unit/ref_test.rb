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

class RefTest < ActiveSupport::TestCase

  should "recognize action as :create when old sha is null" do
    assert_equal :create, Ref.action("0000000000000000000000000000000000000000", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "")
  end

  should "recognize action as :delete when new sha is null" do
    assert_equal :delete, Ref.action("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "0000000000000000000000000000000000000000", "")
  end

  should "recognize action as :update when merge base is equal to old sha" do
    assert_equal :update, Ref.action("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
  end

  should "recognize action as :force_update when merge base isn't equal to old sha" do
    assert_equal :force_update, Ref.action("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", "cccccccccccccccccccccccccccccccccccccccc")
  end

  should "return merge request when valid merge request sequence number given" do
    mr = merge_requests(:moes_to_johans)
    ref = Ref.new(repositories(:johans), "refs/merge-requests/11")

    assert_equal mr, ref.merge_request
  end

  should "return new, unsaved merge request when invalid merge request sequence number given" do
    ref = Ref.new(repositories(:johans), "refs/merge-requests/999999")

    mr = ref.merge_request

    assert_equal 999999, mr.sequence_number
    assert mr.new_record?
  end

  should "return nil when branch refname given" do
    ref = Ref.new(repositories(:johans), "refs/heads/master")

    assert_equal nil, ref.merge_request
  end

end
