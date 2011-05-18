# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
require "fileutils"

# This is required because ActiveMessaging actually forcefully loads
# all processors before initializers are run. Hopefully this can go away
# when the vendored ActiveMessaging plugin is removed.
require File.join(Rails.root, "config/initializers/messaging")

class RepositoryArchivingProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousRepositoryArchiving"

  def on_message(message)
    return if File.exist?(message["output_path"])
    
    Dir.chdir(message["full_repository_path"]) do
      case message["format"]
      when "tar.gz"
        run("git archive --format=tar --prefix=#{e(message['name'] || message['commit_sha'])}/ " +
          "#{e(message['commit_sha'])} | gzip > #{e(message['work_path'])}")
      end
    end
    
    if run_successful?
      FileUtils.mv(message["work_path"], message["output_path"])
    end
  end
  
  def run_successful?
    $? && $?.success?
  end
  
  def run(cmd)
    `#{cmd}`
  end
  
  protected
    def e(string)
      string.gsub("'", '').gsub('"', '')
    end
end
