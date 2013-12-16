#--
#   Copyright (C) 2012-2013 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

desc 'Removes comments with missing targets'
task :fix_dangling_comments => :environment do
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
