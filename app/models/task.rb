#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
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

class Task < ActiveRecord::Base
  serialize :arguments, Array
  
  def self.find_all_pending
    find(:all, :conditions => {:performed => false})
  end
  
  def self.perform_all_pending!(log=RAILS_DEFAULT_LOGGER)
    tasks_to_perform = find_all_pending
    log.debug("Got #{tasks_to_perform.size.inspect} tasks to perform...")
    tasks_to_perform.each do |task|
      task.perform!(log)
    end
  end
  
  def perform!(log=RAILS_DEFAULT_LOGGER)
    transaction do
      log.info("Performing Task #{self.id.inspect}: #{target_class}(#{target_id.inspect})::#{command}(#{arguments.inspect}..)")
      target_class.constantize.send(command, *arguments)
      self.performed = true
      self.performed_at = Time.now
      save!
      unless target_id.blank?
        obj = target_class.constantize.find_by_id(target_id)
        if obj && obj.respond_to?(:ready)
          obj.ready = true
          obj.save!
        end
      end
    end
  end
  
end
