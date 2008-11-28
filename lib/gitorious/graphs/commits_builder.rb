#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
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
    
    class CommitsBuilder < Gitorious::Graphs::Builder
      def self.generate_for(repository)
        head = repository.head_candidate
        return if head.nil?
        
        branch = head.name
        if !File.exist?(self.status_file(repository, branch)) && repository.has_commits?
          builder = new(repository, branch)
          builder.build
          builder.write
          FileUtils.touch(self.status_file(repository, branch))
        end
      end
      
      def initialize(repository, branch)
        @repository = repository
        @branch = branch
        @graph = Gruff::Area.new("650x100")
        @graph.title = "Commits by week (24 week period)" 
        #@graph.x_axis_label = 'Commits by week (24 week period)'
        #@graph.y_axis_label = "Commits"
        @graph.theme = self.class.default_theme
        @graph.hide_legend = true
        @graph.title_font_size = 12.5
        @graph.marker_font_size = 12
        @graph.top_margin = 1
        @graph.bottom_margin = 1
        @graph.no_data_message = " "
      end
      
      def build
        week_numbers, commits_by_week = @repository.commit_graph_data(@branch)
        
        @graph.y_axis_increment = commits_by_week.max# / 3
        @graph.data("Commits", commits_by_week)
        @graph.labels = build_labels(week_numbers)
      end
      
      def self.filename(repository, branch)
        Builder.construct_filename(repository, branch, "commit_count")
      end
      
      def construct_filename
        CommitsBuilder.filename(@repository, @branch)
      end
      
      private
        def build_labels(week_numbers)
          label_names = {}
          week_numbers.each_with_index do |week, index|
            if (index % 5) == 0
              label_names[index] = "Week #{week}"
            end
          end
          label_names[week_numbers.index(week_numbers.last)] = "Week #{week_numbers.last}" 
          label_names
        end
    end
    
  end
end
