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

      # Renders the number of comments for +line+
      def count(line)
        wrap_line do
          count = comment_count_ending_on_line(line)
          if count > 0
            %Q{<a href="" class="diff-comment-count round-10 shadow-2">#{count.to_s}</a>}
          else
            ""
          end
        end
      end

      # Render all the comments for +line+, using +template+ to render
      # partials from
      def render_for(line, template)
        @comments.map{|c| c.render_for(line, template) }.join("\n")
      end

      def wrap_line
        result = %Q{<td class="inline_comments">}
        result << yield
        result << "</td>"
      end

      # Total number of comments _starting_ on +line+
      def comment_count_starting_on_line(line)
        @comments.sum{|c| c.starts_on_line?(line) ? 1 : 0 }
      end

      # Total number of comments _starting_ on +line+
      def comment_count_ending_on_line(line)
        @comments.sum{|c| c.ends_on_line?(line) ? 1 : 0 }
      end
    end

    class SingleCommentCallback
      def initialize(comment)
        @comment = comment
      end

      # Renders this comment for the given +line+.
      # +template+ is the ActionView instance used to render a partial
      # with this comment
      def render_for(line, template)
        return "" unless ends_on_line?(line)
        result = template.render(:partial => "comments/inline_diff",
          :locals => {:comment => @comment})
        if result.respond_to?(:force_encoding)
          result = result.force_encoding(line.encoding)
        end
        result
      end

      # does this comment begin on the given +line+?
      def starts_on_line?(line)
        return false unless line.respond_to?(:offsets)
        @comment.first_line_number == line.offsets.join('-')
      end

      # Does this comment end on the given +line+?
      def ends_on_line?(line)
        return false unless line.respond_to?(:offsets)
        @comment.last_line_number == line.offsets.join('-')
      end
    end
  end
end
