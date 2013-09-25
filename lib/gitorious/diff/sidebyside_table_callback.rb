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
    class SidebysideTableCallback < BaseCallback

      # Before blocks
      def before_addblock(block)
        "<tr class=\"gts-diff-add\">"
      end

      def before_remblock(block)
        "<tr class=\"gts-diff-rm\">"
      end

      def before_modblock(block)
        @modblock = true
        "<tr class=\"gts-diff-mod\">"
      end

      def before_unmodblock(block)
        "<tr class=\"gts-diff-unmod\">"
      end

      def before_sepblock(block)
        "<tr class=\"gts-diff-sep\">"
      end

      # After blocks
      def after_addblock(block)
        "</tr>"
      end

      def after_remblock(block)
        "</tr>"
      end

      def after_modblock(block)
        @modblock = false
        "</tr>"
      end

      def after_unmodblock(block)
        "</tr>"
      end

      def after_sepblock(block)
        "</tr>"
      end

      # Before lines
      def addline(line)
        added = <<-HTML
        <td class="linenum L#{line.new_number}">#{line.new_number}</td>
        <td class="gts-code"><code><ins>#{render_line(line)}</ins></code></td>
        HTML

        return added if modblock?

        <<-HTML
        <td class="linenum L#{line.old_number}">#{line.old_number}</td>
        <td class="gts-code"></td>
        #{added}
        HTML
      end

      def remline(line)
        removed = <<-HTML
        <td class="linenum L#{line.old_number}">#{line.old_number}</td>
        <td class="gts-code"><code><del>#{render_line(line)}</del></code></td>
        HTML

        return removed if modblock?

        <<-HTML
        <!-- REMLINE -->
        #{removed}
        <td class="linenum L#{line.new_number}">#{line.new_number}</td>
        <td class="gts-code"></td>
        <!-- /REMLINE -->
        HTML
      end

      def unmodline(line)
        # unmods goes on both sides
        <<-HTML
        <!-- UNMODLINE -->
        <td class="linenum L#{line.old_number}">#{line.old_number}</td>
        <td class="gts-code"><code>#{render_line(line)}</code></td>
        <td class="linenum L#{line.new_number}">#{line.new_number}</td>
        <td class="gts-code"><code>#{render_line(line)}</code></td>
        <!-- /UNMODLINE -->
        HTML
      end

      def sepline(line)
        <<-HTML
        <!-- SEPLINE -->
        <td class="linenum">&hellip;</td>
        <td class="gts-code"><code></code></td>
        <td class="linenum">&hellip;</td>
        <td class="gts-code"></td>
        <!-- /SEPLINE -->
        HTML
      end

      def nonewlineline(line)
        <<-HTML
        <!-- NONEWLINE -->
        <td class="linenum">&hellip;</td>
        <td class="gts-code"><code></code></td>
        <td class="linenum">&hellip;</td>
        <td class="gts-code"><code>#{line}</code></td>
        <!-- /NONEWLINE -->
        HTML
      end

      protected
      def modblock?
        @modblock
      end
    end
  end
end
