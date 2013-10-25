class EventPresenter

  class AddFavoriteEvent < self
    attr_reader :favorite
    private :favorite

    def initialize(*)
      super
      favorite_class = event.body.constantize
      @favorite = favorite_class.find(data)
    end

    def action
      action_for_event(:event_added_favorite) { view.link_to_watchable(favorite) }
    end

    def category
      'favorite'
    end

  end

end
