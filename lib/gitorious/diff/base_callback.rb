# encoding: utf-8
#--
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
    class BaseCallback < ::Diff::Renderer::Base
      def headerline(line); end
      def new_line; end
      
      protected
        def escape(text)
          text.to_s.gsub('&', '&amp;').
            gsub('<', '&lt;').
            gsub('>', '&gt;').
            gsub('"', '&#34;')
        end
        
        def render_line(line)
          if line.inline_changes?
            prefix, changed, postfix = line.segments.map{|segment| escape(segment) }
            %Q{#{prefix}<span class="idiff">#{changed}</span>#{postfix}}
          else
            escape(line)
          end
        end
    end
  end
end