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

class TreesController < ApplicationController
  include ActiveMessaging::MessageSender
  include ActionView::Helpers::NumberHelper
  include RepositoriesHelper
  include TreesHelper
  helper :all
  before_filter :find_project_and_repository
  before_filter :check_repository_for_commits
  renders_in_site_specific_context
  
  def index
    redirect_to repo_owner_path(@repository, :project_repository_tree_path, 
                  @project, @repository, branch_with_tree(@repository.head_candidate_name, []))
  end
  
  def show
    tree_objects(false)
    end

  def list_files
    tree_objects(true)
  end
  
  def archive
    @git = @repository.git
    # FIXME: update route when we've fixed rails bug #1939
    @ref = desplat_path(params[:branch])
    ext = params[:archive_format]
    unless @commit = @git.commit(@ref)
      handle_missing_tree_sha and return
    end
    
    if !@commit
      flash[:error] = I18n.t "trees_controller.archive_error"
      redirect_to project_repository_path(@project, @repository) and return
    end
    
    user_path = "#{@repository.project_or_owner.to_param}-#{@repository.to_param}-#{@ref}.#{ext}"
    disk_path = "#{@repository.hashed_path.gsub(/\//,'-')}-#{@commit.id}.#{ext}"
    if File.exist?(File.join(GitoriousConfig["archive_cache_dir"], disk_path))
      respond_to do |format|
        format.html {
          set_xsendfile_headers(disk_path, user_path)
          head(:ok) and return
        }
        format.js {
          render :partial => "archive_ready"
        }
      end
    else
      # enqueue the creation of the tarball, and send an accepted response
      if !File.exist?(File.join(GitoriousConfig["archive_work_dir"], disk_path))
        publish_archive_message(@repository, disk_path, @commit)
      end
      
      respond_to do |format|
        format.html {
          # FIXME: This doesn't fly with wget/curl/etc type clients
          render :text => "The archive is currently being generated, try again later",
            :status => :accepted, :content_type => "text/plain" and return
        }
        format.js {
          render :partial => "archive_generating"
        }
      end
    end
  end
  
  protected
    def set_xsendfile_headers(real_path, user_path, content_type = "application/x-gzip")
      response.headers["X-Sendfile"] = File.join(GitoriousConfig["archive_cache_dir"], real_path)
      response.headers["Content-Type"] = content_type
      user_path = user_path.gsub("/", "_").gsub('"', '\"')
      response.headers["Content-Disposition"] = "Content-Disposition: attachment; filename=\"#{user_path}\""
    end
    
    def publish_archive_message(repo, disk_path, commit)
      payload = {
        :full_repository_path => repo.full_repository_path,
        :output_path => File.join(GitoriousConfig["archive_cache_dir"], disk_path),
        :work_path => File.join(GitoriousConfig["archive_work_dir"], disk_path),
        :commit_sha => commit.id,
        :name => (repo.project.slug + "-" + repo.name),
        :format => "tar.gz",
      }
      publish :archive_repo, payload.to_json
    end
    
    def handle_missing_tree_sha
      flash[:error] = "No such tree SHA1 was found"
      redirect_to project_repository_tree_path(@project, @repository, 
                      branch_with_tree("HEAD", @path || []))
    end

    def helpers
      self.class.helpers
    end

    def h(*args)
      helpers.sanitize(*args)
    end

    def tree_objects(ajax_call)
      @git = @repository.git
      @ref, @path = branch_and_path(params[:branch_and_path], @git)
      unless @commit = @git.commit(@ref)
        handle_missing_tree_sha and return
      end
      if stale_conditional?(Digest::SHA1.hexdigest(@commit.id + params[:branch_and_path].join),
                            @commit.committed_date.utc)
        head = @git.get_head(@ref) || Grit::Head.new(@commit.id_abbrev, @commit)
        @root = Breadcrumb::Folder.new({:paths => @path, :head => head,
                                        :repository => @repository})
        path = @path.blank? ? [] : ["#{@path.join("/")}/"] # FIXME: meh, this sux
        @tree = @git.tree(@commit.tree.id, path)
        expires_in 30.seconds

        @tree_objects = @tree.contents.sort_by{|c| helpers.force_utf8(c.name).downcase}.collect{|node|
          name = h(node.basename)
          tree = node.is_a?(Grit::Tree)
          submodule = node.is_a?(Grit::Submodule)
          css_classes = ['node', tree ? 'folder' : (submodule ? 'submodule' :
            "file #{helpers.class_for_filename(node.name)}")].join ' '
          content = tree ? helpers.link_to("#{name}/", tree_path(@ref, node.name)) :
            (submodule ? name : # file:
             helpers.link_to(name, blob_path(@ref, node.name).gsub("%2F", "/")))
          last_commit = !submodule && !too_many_entries_for_log?(@tree) &&
            commit_for_tree_path(@repository, node.name)
          commit_message = submodule ? 'submodule: ' + h(node.url(@ref)) :
             (last_commit ? helpers.link_to(helpers.truncate(h(last_commit.message),
              :length => 75, :omission => "&hellip;"), commit_path(last_commit.id)) : '')
          [tree, node.name, %Q{<span class="#{css_classes}">#{content}</span>},
           %Q{<span class="meta">#{last_commit.committed_date.to_s(:short) if last_commit}</span>},
           %Q{<span class="meta commit_message">#{commit_message}</span>},
           (number_to_human_size(node.size) rescue nil)].compact
        }
        render :json => @tree_objects if ajax_call
      end
    end
end

