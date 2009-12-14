class AddObjectOwnersAsWatchers < ActiveRecord::Migration
  def self.up
    Favorite.class_eval do
      # Don't create events for the favorites we're gonna add here
      def event_should_be_created?
        false
      end
    end

    transaction do
      count = Repository.regular.count
      Repository.regular.each_with_index do |repo, idx|
        say_with_time("Creating favorites for #{repo.url_path} #{idx+1}/#{count}") do
          repo.committerships.map(&:members).flatten.compact.uniq.each do |user|
            user.favorites.create(:watchable => repo)
          end

          repo.merge_requests.each do |mr|
            mr.user.favorites.create(:watchable => mr)
          end
        end # say_with_time
      end
    end
  end

  def self.down
  end
end
