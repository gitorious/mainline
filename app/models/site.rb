# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
class Site < ActiveRecord::Base
  has_many :projects

  validates_presence_of :title
  HTTP_CLONING_SUBDOMAIN = 'git'
  validates_exclusion_of :subdomain, :in => [HTTP_CLONING_SUBDOMAIN]

  attr_accessible :title

  def self.default
    Site.find_or_create_by_title_and_subdomain(:title => GitoriousConfig["site_name"], :subdomain => nil)
  end

  def after_create
    init_wiki_git_path
  end

  def init_wiki_git_path
    self.wiki_git_path = generate_wiki_git_path
    self.save!
  end

  def generate_wiki_git_path
    if(!self.id) then raise "Refusing to generate a git path without a site id" end
    Repository.full_path_from_partial_path(wiki_repo_name)
  end

  def wiki_repo_name
    "#{self.id}-#{self.title}-site-wiki.git"
  end

  def wiki
    if(!self.wiki_git_path) then init_wiki_git_path end
    if(!File.exist? wiki_git_path)
      FileUtils.mkdir_p(wiki_git_path, :mode => 0755)
      repo_name = File.basename(wiki_git_path)
      Repository.create_git_repository(repo_name)
      setup_minimal_hooks
    end
    Grit::Repo.new(wiki_git_path)
  end

  # Cutting out post push events etc for site wiki since it's a
  # special case. Only need the bare minimum: no hooks, only empty executable
  # pre-receive so that we can push.
  def setup_minimal_hooks
    FileUtils.rm(wiki_git_path+"/hooks");
    FileUtils.mkdir(wiki_git_path+"/hooks");
    FileUtils.touch(wiki_git_path+"/hooks/pre-receive");
    FileUtils.chmod(0755, wiki_git_path+"/hooks/pre-receive");
  end


end
