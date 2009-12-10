class AddObjectOwnersAsWatchers < ActiveRecord::Migration
  def self.up
    Favorite.class_eval do
      # Don't create events for the favorites we're gonna add here
      def event_should_be_created?
        false
      end
    end

    transaction do
      count = Project.count
      Project.all.each_with_index do |project, idx|
        say_with_time("Creating favorites for #{project.slug} #{idx+1}/#{count}") do
          project_watchers = []
          if project.owned_by_group?
            project.owner.members.each do |member|
              member.favorites.create!(:watchable => project)
              project_watchers << member
            end
          else
            project.owner.favorites.create!(:watchable => project)
            project_watchers << project.owner
          end

          project.repositories.clones.each do |repo|
            repo.committerships.map(&:members).flatten.compact.uniq.each do |user|
              next if project_watchers.include?(user)
              user.favorites.create!(:watchable => repo)
            end

            repo.merge_requests.each do |mr|
              mr.user.favorites.create!(:watchable => mr)
            end
          end
        end # say_with_time
      end
    end
  end

  def self.down
  end
end
