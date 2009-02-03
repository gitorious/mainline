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
        #"#{repository.project.slug}_#{repository.name}_#{branch}_#{name}.png"
        "#{repository.hashed_path}_#{branch}_#{name}.png"
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
      
      def self.sidebar_pastel_theme
        {
          :colors => [
            '#a9dada', # blue
            '#aedaa9', # green
            '#daaea9', # peach
            '#dadaa9', # yellow
            '#a9a9da', # dk purple
            '#daaeda', # purple
            '#dadada' # grey
            ],
          :marker_color => '#aea9a9', # Grey
          :font_color => 'black',
          :background_colors => '#EEF2F5'
        }
      end
      
      def write
        dest = File.join(self.class.graph_dir, construct_filename)
        @graph.write(dest)
      end
    end
  end
end
