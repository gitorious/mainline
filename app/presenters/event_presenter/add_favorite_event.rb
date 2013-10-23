class EventPresenter

  class AddFavoriteEvent < self

    def action
      favorite_class = event.body.constantize
      repo = favorite_class.find(event.data)
      action_for_event(:event_added_favorite) { view.link_to_watchable(repo) }
    end

    def category
      'favorite'
    end

  end

end
