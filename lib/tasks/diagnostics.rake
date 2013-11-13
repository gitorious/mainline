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

namespace :diagnostics do
  # Diagnostics: get either simple binary answer, or a summary of Gitorious
  # installation. Must be launched with as the gitorious_user (usually 'git')

  # EXAMPLE:
  # su git -c "bundle exec rake diagnostics:summary RAILS_ENV=production"

  desc "Check if all diagnostics tests pass (true/false). Roughly the same as the web page at /admin/diagnostics/summary."
  task :healthy do
    puts `rails runner 'include Gitorious::Diagnostics;puts everything_healthy?'`
  end

  desc "Prints out Gitorious system health summary. Roughly the same output as the web page at /admin/diagnostics"
  task :summary do
    puts `rails runner 'include Gitorious::Diagnostics;puts health_text_summary'`
  end
end
