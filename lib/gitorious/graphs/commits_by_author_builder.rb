# encoding: utf-8
#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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
  module Graphs
    
    class CommitsByAuthorBuilder < Gitorious::Graphs::Builder
      def self.generate_for(repository)
        if repository.has_commits?
          repository.git.heads.each do |head|
            branch = head.name
            if !File.exist?(self.status_file(repository, branch))
              builder = new(repository, branch)
              builder.build
              builder.write
              FileUtils.touch(self.status_file(repository, branch))
            end
          end
        end
      end
      
      def initialize(repository, branch)
        @repository = repository
        @branch = branch
        @graph = Gruff::Mini::Pie.new(250)
        @graph.theme = self.class.sidebar_pastel_theme
        @graph.marker_font_size = 32
        @graph.legend_font_size = 32
        @graph.top_margin = 1
        @graph.bottom_margin = 1
        @graph.no_data_message = ""
      end
      
      def build
        commits_by_author = @repository.commit_graph_data_by_author(@branch)
        
        max_entries = 5
        
        sorted = commits_by_author.sort_by { |author, count| count }.reverse
        
        top = sorted
        if sorted.size > max_entries
          top = sorted[0, max_entries-1]
          
          count = 0
          sorted[max_entries-1, sorted.size].each do |v|
            count += v.last
          end
          top << ["Others", count]
        end
        
        labels = {}
        label_it = 0
        top.each do |v|
          @graph.data("#{v.first} [#{v.last}]", v.last)
          
          labels[label_it] = v.first
          label_it += 1
        end
        
        @graph.labels = labels
      end
      
      def self.filename(repository, branch)
        Builder.construct_filename(repository, branch, "commit_count_by_author")
      end
      
      def construct_filename
        CommitsByAuthorBuilder.filename(@repository, @branch)
      end
    end  
    
  end
end
