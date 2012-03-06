# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
class ResolverTest < ActiveSupport::TestCase
  context "Uri resolving" do

    context "~user uris" do
      should "consider one additional path component a project uri" do
        assert router("/~jane/aweful").contains_slug?
      end

      should "not consider username only a project uri" do
        assert !router("~jane").contains_slug?        
      end

      should "identify the right project" do
        assert_equal(projects(:thunderbird),
          router("~jane/thunderbird-project").project)
      end
    end

    context "+team uris" do
      should "consider one additional path component a project uri" do
        assert router("/+brogrammers/awful").contains_slug?
      end

      should "not consider team name only a project uri" do
        assert !router("/+brogrammers").contains_slug?
      end

      should "identify the correct project" do
        assert_equal(projects(:thunderbird),
          router("/+brogrammers/thunderbird-project").project)
      end
    end

    context "/project uri" do
      should "resolve when project slug exists" do
        assert router("/thunderbird-project").contains_slug?
      end

      should "not resolve when project slug doesn't exist" do
        assert !router("/fourohfour").contains_slug?
      end
    end

    context "reserved words" do
      should "not resolve login uri" do
        assert !router("/login").contains_slug?
      end
    end
  end

  context "load backend configuration" do
    setup do
      GitoriousConfig["current_server_id"] = 2
    end

    teardown do
      GitoriousConfig["current_server_id"] = nil
    end
    
    should "use default backend if project is local" do
      assert router("/thunderbird-project").use_default_backend?
    end

    should "use a remote backend if project is remote" do
      assert_not_nil Project.find_by_slug("remote")
      assert !router("/remote").use_default_backend?
    end
  end

  def router(uri)
    Gitorious::Routing::Resolver.new(uri)
  end
end
