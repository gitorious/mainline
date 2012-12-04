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

require "libdolt"
require "tiltout"
base = File.join(File.expand_path(File.dirname(__FILE__)), "../..")
require File.join(base, "app/racks/repository_browser.rb")

module Gitorious
  class DoltRepository < Dolt::Git::Repository
    attr_reader :meta

    def initialize(meta)
      @meta = meta
      super(meta.full_repository_path)
    end
  end

  class DoltRepositoryResolver
    def resolve(repo)
      repository = Repository.find_by_path(repo)
      raise ActiveRecord::RecordNotFound.new if repository.nil?
      DoltRepository.new(repository)
    end
  end
end

view = Tiltout.new(Dolt.template_dir, {
  :cache => Rails.env.production?,
  :layout => { :file => Rails.root + "app/views/ui3/layouts/layout.html.erb" }
})

view.helper(Dolt::View::MultiRepository)
view.helper(Dolt::View::Object)
view.helper(Dolt::View::Urls)
view.helper(Dolt::View::Blob)
view.helper(Dolt::View::Blame)
view.helper(Dolt::View::Breadcrumb)
view.helper(Dolt::View::Tree)
view.helper(Dolt::View::Commit)
view.helper(Dolt::View::Gravatar)
Dolt::View::TabWidth.tab_width = 4
view.helper(Dolt::View::TabWidth)
view.helper(Dolt::View::BinaryBlobEmbedder)

# Configure blob rendering module

# Attempt to syntax highlight every blob
# view.helper(Dolt::View::SyntaxHighlight)

# Attempt to render every blob as markup
# view.helper(Dolt::View::Markup)

# Render supported formats as markup, syntax highlight the rest
view.helper(Dolt::View::SmartBlobRenderer)
view.helper(:maxdepth => 3)

actions = Dolt::RepoActions.new(Gitorious::DoltRepositoryResolver.new)
Gitorious::RepositoryBrowser.instance = Gitorious::RepositoryBrowser.new(actions, view)
