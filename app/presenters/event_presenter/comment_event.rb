#--
#   Copyright (C) 2012-2014 Gitorious AS
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

class EventPresenter

  class CommentEvent < self
    attr_reader :comment
    private :comment

    def initialize(*)
      super
      @comment = Comment.find(data)
    end

    def action
      if event.body == "MergeRequest"
        repo = event.target.target_repository
        project = repo.project
      else
        project = event.target.project
        repo = event.target
      end

      if comment.applies_to_merge_request? || MergeRequestVersion === comment.target
        if event.body == "MergeRequest"
          action_for_event(:event_commented) {
            " on merge request " +
              link_to(h(repo.url_path) +
                      " " + h("##{event.target.to_param}"),
                      view.project_repository_merge_request_url(project, repo, event.target) +
                      "##{dom_id(comment)}")
          }
        else
          action_for_event(:event_commented) do
            " on " +  link_to(h(repo.url_path), view.project_repository_url(project, repo))
          end
        end
      else
        if comment.sha1.blank? # old-world repo comments
          action_for_event(:event_commented) do
            " on " +  h(repo.url_path)
          end
        else
          action_for_event(:event_commented) do
            " on " +  link_to(h(repo.url_path + '/' + comment.sha1[0,7]),
                              view.project_repository_commit_url(project, repo, comment.sha1) +
                              "##{dom_id(comment)}")
          end
        end
      end
    end

    def category
      'comment'
    end

  end

end
