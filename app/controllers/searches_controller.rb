# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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

class SearchesController < ApplicationController
  PER_PAGE = 30
  helper :all
  renders_in_global_context

  def show
    if params[:q].present?
      @all_results = nil  # The unfiltered search result from TS
      @results = filter_paginated(params[:page], PER_PAGE) do |page|
        begin
          @all_results = ThinkingSphinx.search(query,{
                                                :page => page,
                                                :per_page => PER_PAGE,
                                                :classes => [Project, Repository, MergeRequest],
                                                :match_mode => :extended})

          @all_results.to_a
        rescue ThinkingSphinx::QueryError, ThinkingSphinx::SyntaxError
          @all_results = NullSearchResults.new
          @all_results.to_a
        rescue ThinkingSphinx::SphinxError => e
          # silence the exception if the requested page doesn't exist
          raise e unless e.message =~ /offset out of bounds/

          @all_results = NullSearchResults.new
          @all_results.to_a
        end
      end

      unfiltered_results_length = @all_results.nil? ? 0 : @all_results.length
      filtered_results_length = @results.length
      @total_entries = @all_results.total_entries - (unfiltered_results_length - filtered_results_length)
    end

    respond_to do |format|
      format.html do
        render
      end
    end
  end

  private

  def query
    params[:q].to_s.gsub('/', ' ')
  end

  class NullSearchResults
    def total_entries; 0; end
    def length; 0; end
    def to_a; []; end
    def query_time; 0.0; end
  end
end
