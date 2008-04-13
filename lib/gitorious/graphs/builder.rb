require "gruff"

silence_warnings do
  Gruff::Base::TITLE_MARGIN = 2.0
end

module Gitorious
  module Graphs    
    class Builder
      def self.generate_all_for(repository)
        generators = [CommitsBuilder, CommitsByAuthorBuilder]
        generators.each do |generator|
          generator.generate_for(repository)
        end
      end
      
      def self.graph_dir
        File.join(RAILS_ROOT, "public/images/graphs/")
      end
      
      def self.construct_filename(repository, branch, name)
        "#{repository.project.slug}_#{repository.name}_#{branch}_#{name}.png"
      end
      
      def self.status_file(repository, branch = "master")
        File.join(RAILS_ROOT, "tmp", "graph_generator",
             "#{repository.project.slug}_#{repository.name}_#{repository.git.commit_count(branch)}_#{self.name}.status")
      end

      def self.default_theme
        {
          :colors => [
              '#acd64f',
              '#bcde71',
              '#cce692',
              '#dceeb4',
              '#ecf6d6',
            ],
          :marker_color => '#aea9a9', # Grey
          :font_color => 'black',
          :background_colors => 'white'
        }
      end
      
      def write
        dest = File.join(self.class.graph_dir, construct_filename)
        @graph.write(dest)
      end
    end
  end
end
