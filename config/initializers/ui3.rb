# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
require "gitorious/view"

def cached(file)
  ctime = (Rails.root + "public" + file).ctime.to_i
  "/#{file}?#{ctime}"
end

def add_prod_assets
  Gitorious::View.javascripts << cached("dist/js/gitorious3.min.js")
  Gitorious::View.stylesheets.concat([
      cached("dist/bootstrap/css/bootstrap.min.css"),
      cached("dist/bootstrap/css/bootstrap-responsive.min.css"),
      cached("dist/css/gitorious3.min.css")
    ])
end

if Rails.env.production? || Rails.env.test?
  add_prod_assets
else
  if !File.exists?(Rails.root + "public/ui3/js/lib/bane/package.json")
    $stderr.puts("UI3 asset submodules are not initialized, using production build instead")
    $stderr.puts("To load development files for the Gitorious 3 UI, run")
    $stderr.puts("    git submodule update --init --recursive\n")
    add_prod_assets
  else
    Gitorious::View.javascripts.concat([
        "/ui3/js/lib/console/console.js",
        "/ui3/js/lib/es5-shim/es5-shim.js",
        "/ui3/js/lib/es5-shim/es5-sham.js",
        "/ui3/js/lib/jquery/jquery-1.10.2.min.js",
        "/ui3/js/lib/jquery/jquery.migrate.js",
        "/ui3/js/lib/jquery/jquery.ujs.js",
        "/ui3/js/lib/jquery/jquery.pjax.js",
        "/ui3/js/lib/shims/jquery.html5-placeholder-shim.js",
        "/ui3/lib/bootstrap/js/bootstrap.min.js",
        "/ui3/js/lib/jquery-ui/ui/jquery.ui.core.js",
        "/ui3/js/lib/jquery-ui/ui/jquery.ui.widget.js",
        "/ui3/js/lib/jquery-ui/ui/jquery.ui.mouse.js",
        "/ui3/js/lib/jquery-ui/ui/jquery.ui.selectable.js",
        "/ui3/js/lib/culljs/lib/cull.js",
        "/ui3/js/lib/dome/lib/dome.js",
        "/ui3/js/lib/dome/lib/event.js",
        "/ui3/js/lib/spin.js/spin.js",
        "/ui3/js/lib/when/when.js",
        "/ui3/js/lib/bane/lib/bane.js",
        "/ui3/js/lib/reqwest/reqwest.js",
        "/ui3/js/lib/uinit/lib/uinit.js",
        "/ui3/js/lib/showdown/src/showdown.js",
        "/ui3/js/lib/timeago/timeago.js",
        "/ui3/js/src/app.js",
        "/ui3/js/src/cache.js",
        "/ui3/js/src/json-request.js",
        "/ui3/js/src/components/dropdown.js",
        "/ui3/js/src/components/abbrev.js",
        "/ui3/js/src/components/url.js",
        "/ui3/js/src/components/ref-selector.js",
        "/ui3/js/src/components/tree-history.js",
        "/ui3/js/src/components/commit-linker.js",
        "/ui3/js/src/components/profile-menu.js",
        "/ui3/js/src/components/clone-url-selection.js",
        "/ui3/js/src/components/blob.js",
        "/ui3/js/src/components/live-markdown-preview.js",
        "/ui3/js/src/components/timeago.js",
        "/ui3/js/src/components/collapse.js",
        "/ui3/js/src/components/admin-menu.js",
        "/ui3/js/src/components/project.js",
        "/ui3/js/src/components/repository.js",
        "/ui3/js/src/components/rails-links.js",
        "/ui3/js/src/components/clone-name-suggestion.js",
        "/ui3/js/src/components/loading.js",
        "/ui3/js/src/components/oid-ref-interpolator.js",
        "/ui3/js/src/components/slugify.js",
        "/ui3/js/src/components/select-details.js",
        "/ui3/js/src/components/login-button.js",
        "/ui3/js/src/components/comments.js",
        "/ui3/js/src/components/commit-range-selector.js",
        "/ui3/js/src/components/watched-filter.js",
        "/ui3/js/src/components/pjax.js",
        "/ui3/js/src/gitorious.js",
      ])
    Gitorious::View.stylesheets.concat([
        "/ui3/lib/bootstrap/css/bootstrap.min.css",
        "/ui3/lib/bootstrap/css/bootstrap-responsive.min.css",
        "/ui3/css/gitorious.css"
      ])
  end

  Gitorious::View.javascripts << "/dist/js/logger.js"
end
