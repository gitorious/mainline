# encoding: utf-8
#--
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

module Gitorious
  module Diff
    class CommentCallback

      def initialize(comments)
        @comments = comments.map do |c|
          SingleCommentCallback.new(c, next_css_class)
        end
      end

      # Each comment renders with a given CSS class
      def next_css_class
        @css_classes ||= %w(blue red green brown orange purple)
        @css_classes.shift
      end

      def line(line)
        wrap_line do
          @comments.map{|c| c.line(line) }.join(" ")
        end
      end

      def wrap_line
        result = "<td class=\"inline_comments\">"
        result << yield
        result << "</td>"
      end
      
    end
    class SingleCommentCallback
      def initialize(comment, css_class)
        @comment = comment
        @css_class = css_class
      end
      
      def line(line)
        %Q{<div class="#{css_classes_for(line)}">&nbsp;</div>}
      end
      
      def css_classes_for(line)
        result = ['comment']
        if !@comment.lines.include?(line.new_number)
          result << "none"
        end
        if @comment.lines.begin == line.new_number
          result << "first"
        end
        if @comment.lines.end == line.new_number
          result << "last"
        end
        result.sort.unshift(@css_class).join(" ")
      end
    end
  end
end
