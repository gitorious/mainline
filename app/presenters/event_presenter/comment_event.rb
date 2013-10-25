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
                      view.project_repository_merge_request_path(project, repo, event.target) +
                      "##{dom_id(comment)}")
          }
        else
          action_for_event(:event_commented) do
            " on " +  link_to(h(repo.url_path), [project, repo])
          end
        end
      else
        if comment.sha1.blank? # old-world repo comments
          action_for_event(:event_commented) do
            " on " +  link_to(h(repo.url_path),
                              view.project_repository_comments_path(project, repo) +
                              "##{dom_id(comment)}")
          end
        else
          action_for_event(:event_commented) do
            " on " +  link_to(h(repo.url_path + '/' + comment.sha1[0,7]),
                              view.project_repository_commit_path(project, repo, comment.sha1) +
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
