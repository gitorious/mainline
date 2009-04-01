# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

module RecordThrottling
  class LimitReachedError < StandardError; end
  
  def self.included(base)
    base.class_eval do
      include RecordThrottlingInstanceMethods
      
      # Thottles record creation/update. 
      # Raises RecordThrottling::RecordThrottleLimitReachedError if limit is 
      # reached.
      #
      # Options:
      # +:limit+ the amount of records allowed within (eg. 5)
      # +:timeframe+ the timeframe the limit should be within (eg. 5.minutes)
      # +:counter+ A proc returning the value to compare +:limit+ against
      # +:conditions+ A proc of the counts the last created_at query should use
      # Both the +:counter+ and +:conditions+ procs will receive the record
      # as argument.
      #
      # Example usage:
      # throttle_records :create, :limit => 5,
      #   :counter => proc{|record|
      #      record.user.projects.count(:all, :conditions => ["created_at > ?", 5.minutes.ago])
      #   },
      #   :conditions => proc{|record| {:user_id => record.user.id} },
      #   :timeframe => 5.minutes
      def self.throttle_records(create_or_update, options)
        options.assert_valid_keys(:limit, :counter, :conditions, :timeframe)
        write_inheritable_attribute(:creation_throttle_options, options)
        send("before_#{create_or_update}", :check_throttle_limits)
      end
    end
  end
  
  module RecordThrottlingInstanceMethods
    def check_throttle_limits
      options = self.class.read_inheritable_attribute(:creation_throttle_options)
      if options[:counter].call(self) < options[:limit]
        return true
      end
      last_create = self.class.maximum(:created_at, 
        :conditions => options[:conditions].call(self))
      if last_create && last_create >= options[:timeframe].ago
        raise LimitReachedError
      end
    end
  end
end
