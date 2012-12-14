# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS and/or its subsidiary(-ies)
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
require "dolt/sinatra/base"
require "libdolt/view/multi_repository"
require "libdolt/view/blob"
require "libdolt/view/tree"

module Gitorious
  class RepositoryBrowser < Dolt::Sinatra::Base
    include Dolt::View::MultiRepository
    include Dolt::View::Blob
    include Dolt::View::Tree

    def self.instance; @instance; end
    def self.instance=(instance); @instance = instance; end

    aget "/*/source/*:*" do
      repo, ref, path = params[:splat]
      tree_entry(repo, ref, path)
      ActiveRecord::Base.clear_reloadable_connections!
    end

    aget "/*/source/*" do
      force_ref(params[:splat], "source", "master")
    end

    aget "/*/raw/*:*" do
      repo, ref, path = params[:splat]
      raw(repo, ref, path)
    end

    aget "/*/raw/*" do
      force_ref(params[:splat], "raw", "master")
    end

    aget "/*/blame/*:*" do
      repo, ref, path = params[:splat]
      blame(repo, ref, path)
    end

    aget "/*/blame/*" do
      force_ref(params[:splat], "blame", "master")
    end

    aget "/*/history/*:*" do
      repo, ref, path = params[:splat]
      history(repo, ref, path, (params[:commit_count] || 20).to_i)
    end

    aget "/*/history/*" do
      force_ref(params[:splat], "history", "master")
    end

    aget "/*/refs" do
      refs(params[:splat].first)
    end

    aget "/*/tree_history/*:*" do
      repo, ref, path = params[:splat]
      tree_history(repo, ref, path)
      # response["Content-Type"] = "application/json"
      # body("[]")
    end

    private
    def force_ref(args, action, ref)
      redirect(args.shift + "/#{action}/#{ref}:" + args.join)
    end
  end
end
