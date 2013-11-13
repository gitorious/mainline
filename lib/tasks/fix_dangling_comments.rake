desc 'Removes comments with missing targets'
task :fix_dangling_comments do
  [MergeRequest, MergeRequestVersion].each do |target|
    table_name = target.table_name.to_sym

    comments = Comment.unscoped.
      joins("LEFT OUTER JOIN #{table_name} ON #{table_name}.id = comments.target_id").
      where(:target_type => target.name, table_name => { :id => nil })

    puts "[fix_dangling_comments] removing #{comments.count} orphaned comments"

    comments.find_in_batches(:batch_size => 100) do |comment_batch|
      comment_batch.each do |comment|
        begin
          comment.destroy
        rescue => e
          comment.delete
        end
      end
    end
  end
end
