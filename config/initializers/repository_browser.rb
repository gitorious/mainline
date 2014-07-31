# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "libdolt/git/archiver"
require "tiltout"
require "racks/repository_browser"
require "gitorious"
require "gitorious/view/repository_helper"
require "gitorious/view/project_helper"
require "gitorious/view/ui_helper"
require "gitorious/view/dolt_url_helper"
require "gitorious/view/site_helper"
require "gitorious/dolt/repository_resolver"

views = Rails.root + "app/views"
view = Tiltout.new([Dolt.template_dir, views.realpath.to_s], {
  :cache => Rails.env.production?,
  :layout => { :file => (views + "layouts/application.html.erb").realpath.to_s }
})

module DoltViewHelpers
  include Gitorious::RepoHeader
  include Gitorious::View::DoltUrlHelper
  include ::Dolt::View::MultiRepository
  include ::Dolt::View::Object
  include ::Dolt::View::Blob
  include ::Dolt::View::Blame
  include ::Dolt::View::Breadcrumb
  include ::Dolt::View::Tree
  include ::Dolt::View::Commit
  include ::Dolt::View::Gravatar
  include ::Dolt::View::TabWidth
  include ::Dolt::View::BinaryBlobEmbedder
  include Gitorious::View::UIHelper
  include Gitorious::View::ProjectHelper
  include Gitorious::View::RepositoryHelper
  include Gitorious::View::SiteHelper
  include ::Dolt::View::SmartBlobRenderer
end

module DoltRailsShims
  def content_for(*args); end
end

view.helper(ERB::Util)
view.helper(Tiltout::Partials)
view.helper(Rails.application.routes.url_helpers)
view.helper(DoltViewHelpers)
view.helper(DoltRailsShims)
view.helper(:maxdepth => 3, :tab_width => 4)

::Dolt::View::SubmoduleUrl.parsers.unshift(Gitorious::SubmoduleUrlParser.new)

if archiver_url = ENV['GITORIOUS_ARCHIVER_URL']
  archiver = Gitorious::HttpArchiver.new(archiver_url)
else
  archiver = ::Dolt::Git::Archiver.new(Gitorious.archive_work_dir, Gitorious.archive_cache_dir)
end
lookup = ::Dolt::RepositoryLookup.new(Gitorious::Dolt::RepositoryResolver.new, archiver)
Gitorious::RepositoryBrowser.instance = Gitorious::RepositoryBrowser.new(lookup, view)
