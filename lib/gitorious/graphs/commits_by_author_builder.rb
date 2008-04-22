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
        @graph.theme_pastel
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
