# encoding: utf-8
#--
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
require File.dirname(__FILE__) + '/../test_helper'

class SiteTest < ActiveSupport::TestCase
  
  should_have_many :projects
  should_validate_presence_of :title
  
  should "have a default site with a nil subdomain" do
    default_site = Site.default
    assert_equal "Gitorious", default_site.title
    assert_nil default_site.subdomain
  end
  
  should 'not allow sites with http as subdomain' do
    site = Site.new
    site.subdomain = Site::HTTP_CLONING_SUBDOMAIN
    assert !site.save
    assert_not_nil site.errors.on(:subdomain)
  end

  should "derive grit location from site title and id" do
    site = Site.create(:title => "SuperSite")
    assert_equal "/tmp/git/repositories/#{site.id}-#{site.title}-site-wiki.git", site.wiki_git_path
  end

  should "persist the filepath of its wiki repo" do
    site = Site.create(:title => "BadSite")
    expected = site.wiki_git_path
    assert_equal "/tmp/git/repositories/#{site.id}-#{site.title}-site-wiki.git", expected
    site.save!
    assert_equal expected, Site.find_by_id(site.id).wiki_git_path
  end

  should "persist the default site" do
    default_site = Site.default
    assert_not_nil default_site.wiki_git_path
    assert !default_site.new_record?
  end
  
  context "wiki git creation" do
    setup do
      @site = Site.create(:title => "test-site")
      @path = @site.wiki_git_path
      FileUtils.remove_dir(@path, true)
    end
    
    should "should create new repo and return Grit obj if no repo exists" do
      Repository.git_backend.expects(:create).with(@path).returns(true)
      grit_wiki_repo = @site.wiki
      assert File.exist?(@path), 'File.exist?(path) should be true'
      assert_instance_of Grit::Repo, grit_wiki_repo
      assert_minimal_hooks_exist @path
    end

    should "should just return Grit object if repo exists" do
      FileUtils.mkdir_p(@site.wiki_git_path, :mode => 0755)
      Repository.expects(:create_git_repository).never
      grit_wiki_repo = @site.wiki
      assert_instance_of Grit::Repo, grit_wiki_repo
    end
  end

  def assert_minimal_hooks_exist(path)
    Dir.chdir(path) do
      hooks = File.join(path, "hooks")
      assert File.exist?(hooks)
      assert File.exist?(hooks+"/pre-receive")
    end
  end
  
end
