# encoding: utf-8
#--
#   Copyright (C) 2011-2013 Gitorious AS
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
#
#   Thanks for valuable input from joernchen of Phenoelit
#
#++
require "timeout"
require "shellwords"

module Gitorious

  # Grit is too helpful with escaping the output for our somewhat special needs
  # This class lets us shell out to Git directly
  class GitShell
    def execute(command)
      Timeout.timeout(20) do
        `#{command}`
      end
    rescue Timeout::Error
      raise GitTimeout, "Execution expired"
    end

    def graph_log(git_dir, options = [], branch = nil)
      log_format = '%H§%P§%ai§%ae§%d§%s§'
      pretty_format = %Q{format:"#{log_format}"}

      command = "#{GitoriousConfig['git_binary']} --git-dir=#{git_dir} log --graph --pretty=#{pretty_format} "
      command << (options || []).join(" ")
      command << Shellwords.escape(branch) unless branch.nil?
      execute(command)
    end

    class GitTimeout < ::Timeout::Error
    end
  end
end
