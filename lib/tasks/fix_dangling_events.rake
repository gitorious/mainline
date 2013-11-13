desc 'Removes events with missing targets'
task :fix_dangling_events do
  [Project, User, Group, MergeRequest, Repository].each do |target|
    table_name = target.table_name.to_sym

    events = Event.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = events.target_id").
      where(:target_type => target.name, table_name => { :id => nil })

    Rails.logger.debug "[fix_dangling_events] removing #{events.count} events with missing target #{target.name}"

    events.find_in_batches(:batch_size => 100) do |event_batch|
      event_batch.each do |event|
        begin
          event.destroy
        rescue => e
          event.delete
        end
      end
    end
  end
end
