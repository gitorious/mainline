# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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
    class InlineTableCallback < BaseCallback
      def addline(line)
        <<-HTML
          <tr class="gts-diff-add">
            <td class="linenum"></td>
            <td class="linenum L#{line.new_number}">#{line.new_number}</td>
            <td class="gts-code"><code>#{render_line(line)}</code></td>
          </tr>
        HTML
      end

      def remline(line)
        <<-HTML
          <tr class="gts-diff-rm">
            <td class="linenum L#{line.old_number}">#{line.old_number}</td>
            <td class="linenum"></td>
            <td class="gts-code"><code>#{render_line(line)}</code></td>
          </tr>
        HTML
      end

      def modline(line)
        <<-HTML
          <tr class="gts-diff-mod">
            <td class="linenum L#{line.old_number}">#{line.old_number}</td>
            <td class="linenum L#{line.new_number}">#{line.new_number}</td>
            <td class="gts-code"><code>#{render_line(line)}</code></td>
          </tr>
        HTML
      end

      def unmodline(line)
        <<-HTML
          <tr class="gts-diff-unmod">
            <td class="linenum L#{line.old_number}">#{line.old_number}</td>
            <td class="linenum L#{line.new_number}">#{line.new_number}</td>
            <td class="gts-code"><code>#{render_line(line)}</code></td>
          </tr>
        HTML
      end

      def sepline(line)
        <<-HTML
          <tr class="gts-diff-sepline">
            <td class="linenum>&hellip;</td>
            <td class="linenum>&hellip;</td>
            <td class="gts-code"></td>
          </tr>
        HTML
      end

      def nonewlineline(line)
        <<-HTML
          <tr class="gts-diff-no-newline">
            <td class="linenum L#{line.old_number}">#{line.old_number}</td>
            <td class="linenum L#{line.new_number}">#{line.new_number}</td>
            <td class="gts-code"><code>#{render_line(line)}</code></td>
          </tr>
        HTML
      end
    end
  end
end
