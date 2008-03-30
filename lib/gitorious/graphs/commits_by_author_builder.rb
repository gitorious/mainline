module Gitorious
  module Graphs
    
    class CommitsByAuthorBuilder < Gitorious::Graphs::Builder
      def self.generate_for(repository)
        if repository.has_commits?
          repository.git.heads.each do |head|
            builder = new(repository, head.name)
            builder.build
            builder.write
          end
        end
      end
      
      def initialize(repository, branch)
        @repository = repository
        @branch = branch
        @graph = Gruff::Mini::Pie.new(250)
        @graph.theme_pastel
        @graph.marker_font_size = 32
        @graph.legend_font_size = 32
        @graph.top_margin = 1
        @graph.bottom_margin = 1
      end
      
      def build
        commits_by_author = @repository.commit_graph_data_by_author(@branch)
        
        commits_by_author.each do |author, count|
          @graph.data(author, count)
        end
      end
      
      def construct_filename
        "#{@repository.project.slug}_#{@repository.name}_#{@branch}_commit_count_by_author.png"
      end
    end  
    
  end
end
