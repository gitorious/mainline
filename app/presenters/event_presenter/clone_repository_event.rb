class EventPresenter

  class CloneRepositoryEvent < self

    def action
      original_repo = Repository.find_by_id(data.to_i)

      return "" unless original_repo

      project = target.project

      action_for_event(:event_status_cloned) {
        link_to(h(original_repo.url_path), [project, original_repo])
      }
    end

    def category
      'repository'
    end

    def body
      'New repository is in ' + link_to(h(target.name), [project, target])
    end

  end

end
