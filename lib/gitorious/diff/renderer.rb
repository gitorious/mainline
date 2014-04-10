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

module Gitorious
  module Diff
    class Renderer
      def initialize(app, repository, commit)
        @app = app
        @repository = repository
        @commit = commit
      end

      def render(file)
        diff = ::Diff::Display::Unified.new(file.diff)
        class_name = respond_to?(:table_class) ? " " + table_class : ""

        if binary?(file)
          render_blob(diff, file)
        else
          render_blob(diff, file) do
            <<-HTML
  <div class="gts-code-listing-wrapper">
    <table class="gts-code-listing#{class_name}">
#{diff.render(callback_class.new).force_utf8}
    </table>
  </div>
            HTML
          end
        end
      end

      def render_blob(diff, file)
        <<-HTML
<div class="gts-file">
  <ul class="breadcrumb">
    <li class="gts-diff-summary">
      <a href="#{blob_url(file)}">
        <i class="icon icon-file"></i>
        <span class="gts-path">#{a_path(file)}</span>
      </a>
      (<span class="gts-diff-add">+#{adds(diff)}</span>/<span class="gts-diff-rm">-#{rms(diff)}</span>)
    </li>
  </ul>
  #{yield if block_given?}
</div>
        HTML
      end

      def binary?(file)
        [file.a_blob, file.b_blob].compact.any?(&:binary?)
      end

      def blob_url(file)
        app.tree_entry_url(repository.slug, commit.id, file.a_path)
      end

      def adds(diff)
        diff.stats[:additions]
      end

      def rms(diff)
        diff.stats[:deletions]
      end

      def a_path(file)
        file.a_path && file.a_path.force_utf8
      end

      private
      attr_reader :app, :repository, :commit
    end
  end
end
