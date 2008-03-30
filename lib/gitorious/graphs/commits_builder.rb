module Gitorious
  module Graphs
    
    class CommitsBuilder < Gitorious::Graphs::Builder
      def self.generate_for(repository)
        if repository.has_commits?
          builder = new(repository, repository.head_candidate.name)
          builder.build
          builder.write
        end
      end
      
      def initialize(repository, branch)
        @repository = repository
        @branch = branch
        @graph = Gruff::Area.new("650x150")
        @graph.title = "Commits by week (24 week period)" 
        #@graph.x_axis_label = 'Commits by week (24 week period)'
        #@graph.y_axis_label = "Commits"
        @graph.theme = self.class.default_theme
        @graph.hide_legend = true
        @graph.title_font_size = 12.5
        @graph.marker_font_size = 12
        @graph.top_margin = 1
        @graph.bottom_margin = 1
      end
      
      def build
        week_numbers, commits_by_week = @repository.commit_graph_data(@branch)
        
        @graph.y_axis_increment = commits_by_week.max# / 3
        @graph.data("Commits", commits_by_week)
        @graph.labels = build_labels(week_numbers)
      end
      
      def construct_filename
        "#{@repository.project.slug}_#{@repository.name}_#{@branch}_commit_count.png"
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
