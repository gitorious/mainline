# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
  module Wiki
    class Commit
      attr_accessor :email, :commit_message, :added_file_names, :modified_file_names, :commit_sha

      def added_page_names
        Array(added_file_names).map { |filename| filename.split(".").first }
      end

      def modified_page_names
        Array(modified_file_names).map { |filename| filename.split(".").first }
      end
    end
  end
end
