class EventPresenter

  class EditWikiPageEvent < self

    def action
      action_for_event(:event_updated_wiki_page) {
        link_to(h(project.slug), view.project_path(project)) + "/" +
        link_to(h(page_name), view.project_page_path(project, page_name))
      }
    end

    def category
      'wiki'
    end

    def body
      ''
    end

    private

    def page_name
      data
    end

  end

end
