# encoding: utf-8
#--
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

class RepositoryArchivingProcessor < ApplicationProcessor
  subscribes_to :archive_repo

  def on_message(message)
    msg = ActiveSupport::JSON.decode(message)
    
    return if File.exist?(msg["output_path"])
    
    Dir.chdir(msg["full_repository_path"]) do
      case msg["format"]
      when "tar.gz"
        run("git archive --format=tar --prefix=#{e(msg['name'] || msg['commit_sha'])}/ " +
          "#{e(msg['commit_sha'])} | gzip > #{e(msg['work_path'])}")
      end
    end
    
    if run_successful?
      FileUtils.mv(msg["work_path"], msg["output_path"])
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
