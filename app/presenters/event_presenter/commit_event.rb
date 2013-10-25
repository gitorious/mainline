class EventPresenter

  class CommitEvent < self

    def action
      repo = event.target

      case kind
      when Repository::KIND_WIKI
        action_for_event(:event_status_push_wiki) do
          "to " + view.link_to(h(project.slug), view.project_path(project)) +
          "/" + view.link_to(h(view.t("views.layout.pages")), view.project_pages_url(project))
        end
      when 'commit'
        action_for_event(:event_status_committed) do
          view.link_to(
            data[0,8],
            view.project_repository_commit_path(project, repo, data)) +
          " to " + view.link_to(h(project.slug), project)
        end
      else
        action_for_event(:event_status_committed) do
          view.link_to(
            h(data[0,8]),
            view.project_repository_commit_path(project, repo, data)) +
          " to " + view.link_to(h(project.slug), project)
        end
      end
    end

    def body
      case kind
      when Repository::KIND_WIKI
        h(truncate(event.body, :length => 150))
      else
        view.link_to(h(truncate(event.body, :length => 150)),
                     view.project_repository_commit_path(project, target, data))
      end
    end

    def category
      case kind
      when Repository::KIND_WIKI then 'wiki'
      else
        'commit'
      end
    end

  end

end
