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
class Site < ActiveRecord::Base
  has_many :projects
   
  validates_presence_of :title
  HTTP_CLONING_SUBDOMAIN = 'git'
  validates_exclusion_of :subdomain, :in => [HTTP_CLONING_SUBDOMAIN]

  attr_protected :subdomain
  attr_protected :wiki_git_path

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
    repo_name = Site.wiki_repo_name(self.id, self.title)
    Repository.full_path_from_partial_path(repo_name)
  end

  # TODO kill singleton method, update push/pull/config stuff
  def self.wiki_repo_name(site_id, site_title)
    "#{site_id}-#{site_title}-site-wiki.git"
  end
  
  def wiki
    if(!self.wiki_git_path) then init_wiki_git_path end
    if(!File.exist? wiki_git_path)
      FileUtils.mkdir_p(wiki_git_path, :mode => 0755)
      repo_name = File.basename(wiki_git_path)
      Repository.create_git_repository(repo_name)
    end
    Grit::Repo.new(wiki_git_path)
  end
  
end
