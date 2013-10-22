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
  after_create :init_wiki_git_path

  def self.default
    site = Site.where(:title => Gitorious.site_name, :subdomain => nil).first
    if site.nil?
      site = Site.new(:title => Gitorious.site_name)
      site.save
    end
    site
  end

  def init_wiki_git_path
    self.wiki_git_path = generate_wiki_git_path
    self.save!
  end

  def generate_wiki_git_path
    if(!self.id) then raise "Refusing to generate a git path without a site id" end
    RepositoryRoot.expand(wiki_repo_name).to_s
  end

  def wiki_repo_name
    "#{self.id}-#{self.title}-site-wiki.git"
  end

  def wiki
    init_wiki_git_path if !self.wiki_git_path

    if !File.exist?(wiki_git_path)
      FileUtils.mkdir_p(wiki_git_path, :mode => 0755)
      GitBackend.create(RepositoryRoot.expand(wiki_git_path).to_s)
      setup_minimal_hooks
    end
    Grit::Repo.new(wiki_git_path)
  end

  def ready?
    !wiki.nil?
  end

  def wiki?
    true
  end

  def wiki_permissions
    []
  end

  # Cutting out post push events etc for site wiki since it's a
  # special case. Only need the bare minimum: no hooks, only empty executable
  # pre-receive so that we can push.
  def setup_minimal_hooks
    FileUtils.rm(wiki_git_path+"/hooks", :force => true);
    FileUtils.mkdir(wiki_git_path+"/hooks");
    FileUtils.touch(wiki_git_path+"/hooks/pre-receive");
    FileUtils.chmod(0755, wiki_git_path+"/hooks/pre-receive");
  end
end
