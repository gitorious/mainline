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
    class CommitParser
      # Expects the output of git log --pretty=short --name-status
      def parse(git_output)
        current_commit_output = []
        lines = git_output.split("\n")

        commits = []

        while line = lines.shift
          if line =~ /^commit.*/ && !current_commit_output.blank?
            commits << parse_commit(current_commit_output)
            current_commit_output.clear
          end

          current_commit_output << line
        end
        commits << parse_commit(current_commit_output)
        commits
      end

      def parse_commit(lines)
        sha_line = lines.first
        author_line = lines[1]
        message_line = lines[3]

        result = Commit.new

        result.commit_sha = extract_sha_from_line(sha_line)

        result.email = extract_email_from_line(author_line)
        result.commit_message = extract_commit_message_from_line(message_line)

        file_listing = lines.drop(4).join("\n")
        
        result.added_file_names = extract_added_files_from_git_output(file_listing)
        result.modified_file_names = extract_modified_files_from_git_output(file_listing)
        result
      end

      def fetch_from_git(repository, spec)
        from = spec.from_sha.sha
        to = spec.to_sha.sha
        output = repository.git.git.log({:pretty => "short", :"name-status" => true}, [from, to].join(".."))
        parse(output)
      end

      def extract_email_from_line(author_line)
        author_line.scan(/Author:.*<(.*)>$/).flatten.first
      end

      def extract_sha_from_line(sha_line)
        sha_line.scan(/^commit\s([a-f0-9]*)$/).flatten.first
      end

      def extract_commit_message_from_line(message_line)
        message_line.strip
      end

      def extract_added_files_from_git_output(git_output)
        extract_filename_from_file_list("A", git_output)
      end

      def extract_modified_files_from_git_output(git_output)
        extract_filename_from_file_list("M", git_output)
      end

      private
      def extract_filename_from_file_list(flag, git_output)
        git_output.scan(/^#{flag}\s*([A-Z][a-z\.A-Z]+)$/).flatten
      end
    end
  end
end
