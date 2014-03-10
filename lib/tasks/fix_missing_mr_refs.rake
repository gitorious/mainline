#--
#   Copyright (C) 2014 Gitorious AS
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

desc 'Creates missing refs for given merge request ID'
task :fix_missing_mr_refs => :environment do
  require 'fileutils'

  project_slug = ENV['PROJECT_SLUG']
  repository_name = ENV['REPO_NAME']
  mr_number = ENV['MR_NUMBER']

  if project_slug.blank? || repository_name.blank? || mr_number.blank?
    puts "You have to set PROJECT_SLUG, REPO_NAME and MR_NUMBER env variables"
    exit 1
  end

  project = Project.find_by_slug(project_slug)
  repository = project.repositories.find_by_name(repository_name)
  mr = repository.merge_requests.find_by_sequence_number(mr_number.to_i)

  # add missing ref for MR to target repo

  ref_path = mr.target_repository.full_repository_path + "/refs/merge-requests/#{mr_number}"
  unless File.exist?(ref_path)
    puts "creating missing ref file #{ref_path} (#{mr.ending_commit}) in target repo"
    File.open(ref_path, 'w') { |f| f.puts(mr.ending_commit) }
  end

  # add missing refs for MR versions to tracking repo

  mr_refs_dir = mr.tracking_repository.full_repository_path + "/refs/merge-requests/#{mr_number}"
  unless File.exist?(mr_refs_dir)
    puts "creating missing MR refs directory #{mr_refs_dir} in tracking repo"
    FileUtils.mkdir_p(mr_refs_dir)
  end

  mr.versions.each do |version|
    ref_path = "#{mr_refs_dir}/#{version.version}"
    unless File.exist?(ref_path)
      puts "creating missing version ref file #{ref_path} (#{mr.ending_commit}) in tracking repo"
      File.open(ref_path, 'w') { |f| f.puts(mr.ending_commit) }
    end
  end
end
