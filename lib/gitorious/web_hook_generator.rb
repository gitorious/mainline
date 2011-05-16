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
  class WebHookGenerator
    include Gitorious::Messaging::Publisher
    
    def initialize(repository, spec, user)
      @repository = repository
      @spec = spec
      @user = user
    end

    def generate!
      publish_notification({
          :user => @user.login,
          :repository_id => @repository.id,
          :payload => payload})
    end

    def publish_notification(data)
      publish("/queue/GitoriousPostReceiveWebHook", data)
    end
    
    def payload
      {
        :before        => @spec.from_sha.sha,
        :after         => @spec.to_sha.sha,
        :pushed_at     => @repository.last_pushed_at.xmlschema,
        :pushed_by     => @user.login,
        :ref           => @spec.ref_name,
        :project => {
          :name => @repository.project.slug,
          :description => @repository.project.description
        },
        :repository => {
          :url => @repository.browse_url,
          :name => @repository.name,
          :description => @repository.description,
          :clones => @repository.clones.count,
          :owner => { :name => @repository.owner.title }
        },
        :commits => fetch_commits
      }
    end

    def fetch_commits
      commits = @repository.git.commits_between(@spec.from_sha.sha, @spec.to_sha.sha)
      commits.map do |c|
        {
          :author => {
            :email => c.author.email,
            :name => c.author.name
          },
          :committed_at => c.committed_date.xmlschema,
          :id => c.id,
          :message => c.message,
          :timestamp => c.authored_date.xmlschema,
          :url => commit_url(c.id)
        }
      end
    end

    def commit_url(sha)
      File.join(@repository.browse_url, "commit", sha)
    end
  end
end
