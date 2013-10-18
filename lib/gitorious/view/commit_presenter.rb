module Gitorious
  module View

    class CommitPresenter < SimpleDelegator
      include Adamantium::Flat

      attr_reader :view

      def initialize(commit, view)
        super(commit)
        @view = view
      end

      def short_oid
        id[0, 7]
      end
      memoize :short_oid

    end
  end
end
