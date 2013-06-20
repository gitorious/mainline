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

def cached(file)
  ctime = (Rails.root + "public" + file).ctime.to_i
  "/#{file}?#{ctime}"
end

def add_prod_assets
  Gitorious.javascripts << cached("ui3/dist/gitorious3.min.js")
  Gitorious.stylesheets.concat([
    cached("ui3/lib/bootstrap/css/bootstrap.min.css"),
    cached("ui3/lib/bootstrap/css/bootstrap-responsive.min.css"),
    cached("ui3/dist/gitorious3.min.css")
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
    Gitorious.javascripts.concat([
      "/ui3/js/lib/culljs/lib/cull.js",
      "/ui3/js/lib/dome/lib/dome.js",
      "/ui3/js/lib/dome/lib/event.js",
      "/ui3/js/lib/spin.js/spin.js",
      "/ui3/js/lib/when/when.js",
      "/ui3/js/lib/bane/lib/bane.js",
      "/ui3/js/lib/reqwest/reqwest.js",
      "/ui3/js/lib/uinit/lib/uinit.js",
      "/ui3/js/lib/showdown/src/showdown.js",
      "/ui3/js/src/app.js",
      "/ui3/js/src/components/dropdown.js",
      "/ui3/js/src/components/ganalytics.js",
      "/ui3/js/src/components/abbrev.js",
      "/ui3/js/src/components/url.js",
      "/ui3/js/src/components/ref-selector.js",
      "/ui3/js/src/components/tree-history.js",
      "/ui3/js/src/components/commit-linker.js",
      "/ui3/js/src/components/user-repo-view-state.js",
      "/ui3/js/src/components/profile-menu.js",
      "/ui3/js/src/components/clone-url-selection.js",
      "/ui3/js/src/components/blob.js",
      "/ui3/js/src/components/live-markdown-preview.js",
      "/ui3/js/src/gitorious.js",
    ])
    Gitorious.stylesheets.concat([
      "/ui3/lib/bootstrap/css/bootstrap.min.css",
      "/ui3/lib/bootstrap/css/bootstrap-responsive.min.css",
      "/ui3/css/gitorious.css"
    ])
  end

  Gitorious.javascripts << "/ui3/js/src/logger.js"
end
