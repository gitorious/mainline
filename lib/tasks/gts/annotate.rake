# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

namespace :gts do
  desc 'Annotates files with the license header'
  task :annotate do
    Dir[Rails.root.join('app/**/*.*'), Rails.root.join('lib/**/*.*')].each do |path|
      content = File.read(path)

      next if content.include?('Copyright (C)')

      annotated =
        if path =~ /\.rb$/ || path =~ /\.rake$/
          [LICENSE_HEADER, content].join("\n")
        elsif path =~ /\.erb$/
          ['<%', LICENSE_HEADER.strip, '%>', content].join("\n")
        end

      File.write(path, annotated) if annotated
    end
  end
end
