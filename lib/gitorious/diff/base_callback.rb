#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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
          text.gsub('&', '&amp;').
            gsub('<', '&lt;').
            gsub('>', '&gt;').
            gsub('"', '&#34;')
        end
    end
  end
end