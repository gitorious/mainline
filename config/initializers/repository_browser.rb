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
require File.join(base, "app/presenters/repository_presenter.rb")
require File.join(base, "lib/gitorious.rb")
require File.join(base, "lib/gitorious/view/repository_helper.rb")
require File.join(base, "lib/gitorious/view/project_helper.rb")
require File.join(base, "lib/gitorious/view/ui_helper.rb")
require File.join(base, "lib/gitorious/view/dolt_url_helper.rb")

module Gitorious
  class DoltRepository < Dolt::Git::Repository
    attr_reader :meta

    def initialize(repository)
      @meta = RepositoryPresenter.new(repository)
      super(repository.full_repository_path)
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

views = Rails.root + "app/views/ui3"
view = Tiltout.new([Dolt.template_dir, views.realpath.to_s], {
  :cache => Rails.env.production?,
  :layout => { :file => (views + "layouts/layout.html.erb").realpath.to_s }
})

view.helper(ERB::Util)
view.helper(Tiltout::Partials)
view.helper(Gitorious::View::DoltUrlHelper)
view.helper(Rails.application.routes.url_helpers)
view.helper(Dolt::View::MultiRepository)
view.helper(Dolt::View::Object)
view.helper(Dolt::View::Blob)
view.helper(Dolt::View::Blame)
view.helper(Dolt::View::Breadcrumb)
view.helper(Dolt::View::Tree)
view.helper(Dolt::View::Commit)
view.helper(Dolt::View::Gravatar)
view.helper(Dolt::View::TabWidth)
view.helper(Dolt::View::BinaryBlobEmbedder)
view.helper(Gitorious::View::UIHelper)
view.helper(Gitorious::View::ProjectHelper)
view.helper(Gitorious::View::RepositoryHelper)
view.helper(Dolt::View::SmartBlobRenderer)
view.helper(:maxdepth => 3, :tab_width => 4)

actions = Dolt::RepoActions.new(Gitorious::DoltRepositoryResolver.new)
Gitorious::RepositoryBrowser.instance = Gitorious::RepositoryBrowser.new(actions, view)
