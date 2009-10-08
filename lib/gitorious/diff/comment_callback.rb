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
        @comments = comments.map do |comment|
          SingleCommentCallback.new(comment)
        end
      end

      def count(line)
        wrap_line do
          count = comment_count_starting_on_line(line)
          if count > 0
            %Q{<a href="" class="diff-comment-count round-10 shadow-2">#{count.to_s}</a>}
          else
            ""
          end
        end
      end

      def render_for(line)
        @comments.map{|c| c.render_for(line) }.join("\n")
      end

      def wrap_line
        result = %Q{<td class="inline_comments">}
        result << yield
        result << "</td>"
      end
      
      # Total number of comments _starting_ on +line+
      def comment_count_starting_on_line(line)
        @comments.sum{|c| c.comment_starts_on_line?(line) ? 1 : 0 }
      end

      # Total number of comments on +line+
      def comment_count_for_line(line)
        @comments.sum{|c| c.commented_on_line?(line) ? 1 : 0 }
      end
    end
    class SingleCommentCallback
      def initialize(comment)
        @comment = comment
      end

      def render_for(line)
        return "" unless comment_starts_on_line?(line)
        "<p>\"" + @comment.body + "\" //" + @comment.user.login + "</p>"
      end
      
      # does this +line+ have the beginnings of a comment
      def comment_starts_on_line?(line)
        @comment.lines.begin == line.new_number
      end
      
      # does this +line+ have a comment somehow
      def commented_on_line?(line)
        @comment.lines.include?(line.new_number)
      end
    end
  end
end
