# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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

class BlobsController < ApplicationController
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  before_filter :find_commit, :only => [:show, :history, :blame]

  skip_session :only => [:blame, :show, :raw]

  renders_in_site_specific_context :except => [:blame, :history]

  def show
    if stale?({
          :etag => Digest::SHA1.hexdigest(@commit.id + params[:branch_and_path].join), 
          :last_modified => @commit.committed_date.utc})
      @blob = @git.tree(@commit.tree.id, ["#{@path.join("/")}"]).contents.first
      render_not_found and return unless @blob
      unless @blob.respond_to?(:data) # it's a tree
        redirect_to repo_owner_path(@repository, :project_repository_tree_path, 
          @project, @repository, params[:branch_and_path])
      end
      head = @git.get_head(@ref) || Grit::Head.new(@commit.id_abbrev, @commit)
      @root = Breadcrumb::Blob.new(:paths => @path, :head => head, 
        :repository => @repository, :name => @blob.basename)
      expire_based_on_ref_length(@ref.size)
      render :layout => !pjax_request?
    end
  end

  def blame
    @file_path = @path.join("/")
    @blame = @git.blame(@file_path, @ref)

    head = @git.get_head(@ref) || Grit::Head.new(@commit.id_abbrev, @commit)
    @root = Breadcrumb::Blob.new(:paths => @path, :head => head, 
      :repository => @repository, :name => @path.last)

    expire_based_on_ref_length(@ref.size)

    render :layout => !pjax_request?
  end

  def raw
    @git = @repository.git
    @ref, @path = branch_and_path(params[:branch_and_path], @git)
    if @git.git.cat_file({:t => true}, @ref) == 'blob'
      @blob = @git.blob(@ref)
      if @blob.size > 500.kilobytes
        flash[:error] = I18n.t "blobs_controller.raw_error", :size => @blob.size
        redirect_to project_repository_path(@project, @repository) and return
      end
      expires_in 30.minutes
#      headers["Content-Disposition"] = %[attachment]
      render :text => @blob.data, :content_type => @blob.mime_type
    else
      @commit = @git.commit(@ref)
      unless @commit
        redirect_to project_repository_raw_blob_path(@project, @repository,
                      branch_with_tree("HEAD", @path)) and return
      end
      if stale?(:etag => Digest::SHA1.hexdigest(@commit.id + params[:branch_and_path].join), :last_modified => @commit.committed_date.utc)
        @blob = @git.tree(@commit.tree.id, ["#{@path.join("/")}"]).contents.first
        render_not_found and return unless @blob
        if @blob.size > 500.kilobytes
          flash[:error] = I18n.t "blobs_controller.raw_error", :size => @blob.size
          redirect_to project_repository_path(@project, @repository) and return
        end
        expires_in 30.minutes
        headers["Content-Disposition"] = %[attachment;filename="#{@blob.name}"]
        render :text => @blob.data, :content_type => @blob.mime_type
      end
    end
  end
  
  def history
    @blob = @git.tree(@commit.tree.id, ["#{@path.join("/")}"]).contents.first
    render_not_found and return unless @blob
    unless @blob.respond_to?(:data) # it's a tree
      redirect_to repo_owner_path(@repository, :project_repository_tree_path, 
        @project, @repository, params[:branch_and_path])
    end
    
    @root = Breadcrumb::Blob.new({
      :paths => @path,
      :head => @git.get_head(@ref) || Grit::Head.new(@commit.id_abbrev, @commit),
      :repository => @repository, 
      :name => @blob.basename
    })
    @commits = @git.log(@ref, desplat_path(@path))
    expire_based_on_ref_length(@ref.size)
    respond_to do |wants|
      wants.html { render :layout => !pjax_request?}
      wants.json {render :json =>
        @commits.map{|c|{
            :author => c.author.name,
            :sha => c.id,
            :message => c.short_message,
            :committed_date => c.committed_date}
        }.to_json}
    end
  end
  
  protected
    def redirect_to_head
      redirect_to project_repository_blob_path(@project, @repository, 
                    branch_with_tree("HEAD", @path))
    end

    def find_commit
      @git = @repository.git
      @ref, @path = branch_and_path(params[:branch_and_path], @git)
      @commit = @git.commit(@ref)
      unless @commit
        redirect_to_head and return
      end
    end

    def expire_based_on_ref_length(length)
      if length == 40
        cache_forever
      else
        cache_for(1.hour)
      end
    end
end
