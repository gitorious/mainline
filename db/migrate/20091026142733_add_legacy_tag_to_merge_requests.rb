# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class AddLegacyTagToMergeRequests < ActiveRecord::Migration
  def self.up
    transaction do
      add_column :merge_requests, :legacy, :boolean, :default => false
      MergeRequest.reset_column_information
      merge_requests = MergeRequest.where("status != ? and created_at < ?",
                                          MergeRequest::STATUS_PENDING_ACCEPTANCE_OF_TERMS,
                                          1.week.ago).
        includes(:versions)
      merge_requests.reject!{|mr| !mr.versions.blank? }
      say "Marking #{merge_requests.size} merge requests as legacy"
      merge_requests.each do |mr|
        mr.update_attribute(:legacy, true)
      end
    end
  end

  def self.down
    remove_column :merge_requests, :legacy
  end
end
