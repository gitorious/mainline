# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2008 Peter Dalmaris <peter.dalmaris@gmail.com>
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

module CommentsHelper
  include DiffHelper
  def comment_block(comment, &block)
    block_options = {:class => "comment", :"gts:comment-id" => comment.to_param}
    if comment.applies_to_line_numbers?
      block_options[:class] << " inline"
      block_options[:"data-diff-path"] = comment.path
      block_options[:"data-last-line-in-diff"] = comment.last_line_number
      block_options[:"data-sha-range"] = comment.sha1
      block_options[:"data-merge-request-version"] = comment.target.version if comment.target.respond_to?(:version)
    end
    content_tag(:div, capture(&block), block_options)
  end
end
