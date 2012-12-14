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
require "racks/repository_browser"
require "gitorious"
require "gitorious/view/repository_helper"
require "gitorious/view/project_helper"
require "gitorious/view/ui_helper"
require "gitorious/view/dolt_url_helper"
require "gitorious/dolt/repository_resolver"

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

actions = Dolt::RepoActions.new(Gitorious::Dolt::RepositoryResolver.new)
Gitorious::RepositoryBrowser.instance = Gitorious::RepositoryBrowser.new(actions, view)
