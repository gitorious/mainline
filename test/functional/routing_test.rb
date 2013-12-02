# encoding: utf-8
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

require "test_helper"

class RoutingTest < ActionController::TestCase
  fixtures :all

  context "User routing" do
    should "recognize ~username" do
      assert_generates("/~zmalltalker", {
                         :controller => "users",
                         :action => "show",
                         :id => "zmalltalker"
                       })

      assert_recognizes({ :controller => "users",
                          :action => "show",
                          :id => "zmalltalker"
                        }, {
                          :path => "/~zmalltalker",
                          :method => :get
                        })
    end

    should "recognize ~username sub resource" do
      assert_generates("/~zmalltalker/license/edit", {
                         :controller => "licenses",
                         :action => "edit",
                         :user_id => "zmalltalker"
                       })

      assert_recognizes({ :controller => "licenses",
                          :action => "edit",
                          :user_id => "zmalltalker"
                        }, {
                          :path => "/~zmalltalker/license/edit",
                          :method => :get
                        })
    end

    should "not recognize controller actions as repositories" do
      assert_recognizes({ :controller => "password_resets",
                          :action => "new"
                        }, {
                          :path => "/users/forgot_password",
                          :method => :get
                        })

      assert_recognizes({ :controller => "user_activations",
                          :action => "create",
                          :activation_code => "1234"
                        }, {
                          :path => "/users/activate/1234",
                          :method => :get
                        })
    end

    context "usernames with dots" do
      should "recognize /~user.name" do
        assert_recognizes({ :controller => "users",
                            :action => "show",
                            :id => "user.name"
                          }, "/~user.name")

        assert_generates("/~user.name", {
                           :controller => "users",
                           :action => "show",
                           :id => "user.name"
                         })
      end

      should "recognize /~user.name/action" do
        assert_recognizes({ :controller => "users",
                            :action => "edit",
                            :id => "user.name"
                          }, "/~user.name/edit")

        assert_generates("/~user.name/edit", {
                           :controller => "users",
                           :action => "edit",
                           :id => "user.name"
                         })
      end
    end
  end

  context "Project routing" do
    should "recognize /projects" do
      assert_recognizes({ :controller => "projects",
                          :action => "index"
                        }, {
                          :path => "/projects",
                          :method => :get
                        })

      assert_generates("/projects", {
                         :controller => "projects",
                         :action => "index"
                       })
    end

    should "recognize /projectname" do
      assert_recognizes({ :controller => "projects",
                          :action => "show",
                          :id => "gitorious"
                        }, {
                          :path => "/gitorious",
                          :method => :get
                        })

      assert_recognizes({ :controller => "projects",
                          :action => "show",
                          :id => "gitorious"
                        }, {
                          :path => "/gitorious/",
                          :method => :get
                        })

      assert_generates("/gitorious", {
                         :controller => "projects",
                         :action => "show",
                         :id => "gitorious"
                       })
    end

    should "recognize /projectname/repositories" do
      assert_recognizes({ :controller => "repositories",
                          :action => "index",
                          :project_id => "gitorious"
                        }, {
                          :path => "/gitorious/repositories",
                          :method => :get
                        })

      assert_recognizes({ :controller => "repositories",
                          :action => "index",
                          :project_id => "gitorious"
                        }, {
                          :path => "/gitorious/repositories/",
                          :method => :get
                        })

      assert_generates("/gitorious/repositories", {
                         :controller => "repositories",
                         :action => "index",
                         :project_id => "gitorious"
                       })
    end

    should "recognize /projectname/repositories/:action" do
      assert_recognizes({ :controller => "repositories",
                          :action => "new",
                          :project_id => "gitorious"
                        }, {
                          :path => "/gitorious/repositories/new",
                          :method => :get
                        })

      assert_recognizes({ :controller => "repositories",
                          :action => "new",
                          :project_id => "gitorious"
                        }, {
                          :path => "/gitorious/repositories/new",
                          :method => :get
                        })

      assert_generates("/gitorious/repositories/new", {
                         :controller => "repositories",
                         :action => "new",
                         :project_id => "gitorious"
                       })
    end

    should "recognize projects#edit" do
      recognize_project_action(:get, "/gitorious/edit", "edit")
    end

    should "recognize projects#update" do
      recognize_project_action(:put, "/gitorious", "update")
    end

    should "recognize projects#destroy" do
      recognize_project_action(:delete, "/gitorious", "destroy")
    end

    should "recognize projects#confirm_delete" do
      recognize_project_action(:get, "/gitorious/confirm_delete", "confirm_delete")
    end

    should "recognize projects#preview" do
      recognize_project_action(:put, "/gitorious/preview", "preview")
    end

    should "recognize routes with format" do
      assert_recognizes({ :controller => "projects",
                          :action => "show",
                          :id => "gitorious",
                          :format => "xml"
                        }, {
                          :path => "/gitorious.xml",
                          :method => :get
                        })

      assert_recognizes({ :controller => "projects",
                          :action => "index",
                          :format => "xml"
                        }, {
                          :path => "/projects.xml",
                          :method => :get
                        })

      assert_generates("/projects.xml", {
                         :controller => "projects",
                         :action => "index",
                         :format => "xml"
                       })
    end
  end

  context "Repository routing" do
    context "by projects" do
      should "recognize /projectname/reponame" do
        assert_generates("/gitorious/mainline", {
                           :controller => "repositories",
                           :action => "show",
                           :project_id => "gitorious",
                           :id => "mainline",
                         })

        assert_recognizes({ :controller => "repositories",
            :action => "show",
            :project_id => "gitorious",
            :id => "mainline",
          }, {
            :path => "/gitorious/mainline",
            :method => :get
          })

        assert_recognizes({ :controller => "merge_requests",
                            :action => "index",
                            :project_id => "gitorious",
                            :repository_id => "mainline",
                          }, {
                            :path => "/gitorious/mainline/merge_requests",
                            :method => :get
                          })

        assert_recognizes({ :controller => "repository_activities",
            :action => "index",
            :project_id => "gitorious",
            :id => "mainline",
          }, {
            :path => "/gitorious/mainline/activities",
            :method => :get
          })

        assert_generates("/gitorious/mainline/activities", {
            :controller => "repository_activities",
            :action => "index",
            :project_id => "gitorious",
            :id => "mainline"
          })
      end

      should "recognize /projectname/repositories" do
        assert_recognizes({ :controller => "repositories",
                            :action => "index",
                            :project_id => "gitorious"
                          }, "/gitorious/repositories")

        assert_recognizes({ :controller => "repositories",
                            :action => "index",
                            :project_id => "gitorious"
                          }, "/gitorious/repositories/")

        assert_generates("/gitorious/repositories", {
                           :controller => "repositories",
                           :action => "index",
                           :project_id => "gitorious"
                         })
      end

      should "recognize /projectname/reponame with explicit format" do
        assert_recognizes({ :controller => "repository_activities",
                            :action => "index",
                            :project_id => "gitorious",
                            :format => "xml",
                            :id => "mainline",
                          }, "/gitorious/mainline/activities.xml")

        assert_recognizes({ :controller => "merge_requests",
                            :action => "index",
                            :format => "xml",
                            :project_id => "gitorious",
                            :repository_id => "mainline",
                          }, "/gitorious/mainline/merge_requests.xml")

        assert_generates("/gitorious/mainline/activities.xml", {
                           :controller => "repository_activities",
                           :action => "index",
                           :project_id => "gitorious",
                           :id => "mainline",
                           :format => "xml",
                         })

        assert_generates("/gitorious/mainline/merge_requests", {
                           :controller => "merge_requests",
                           :action => "index",
                           :project_id => "gitorious",
                           :repository_id => "mainline",
                         })
      end

      should "recognize /projectname/repositories with explicit format" do
        assert_recognizes({ :controller => "repositories",
                            :action => "index",
                            :format => "xml",
                            :project_id => "gitorious"
                          }, "/gitorious/repositories.xml")

        assert_generates("/gitorious/repositories.xml", {
                           :controller => "repositories",
                           :action => "index",
                           :project_id => "gitorious",
                           :format => "xml",
                         })
      end

      should "recognize clone search routing" do
        assert_recognizes({ :controller => "repository_clone_searches",
                            :action => "show",
                            :format => "json",
                            :project_id => "gitorious",
                            :id => "mainline"
                          }, "/gitorious/mainline/search_clones.json")

        assert_generates("/gitorious/mainline/search_clones.json", {
                           :controller => "repository_clone_searches",
                           :action => "show",
                           :project_id => "gitorious",
                           :id => "mainline",
                           :format => "json"
                         })
      end

      should "recognize repository ownership routing" do
        assert_recognizes({ :controller => "repository_ownerships",
            :action => "edit",
            :project_id => "gitorious",
            :id => "mainline"
          }, "/gitorious/mainline/ownership/edit")

        assert_generates("/gitorious/mainline/ownership/edit", {
            :controller => "repository_ownerships",
            :action => "edit",
            :project_id => "gitorious",
            :id => "mainline"
          })
      end
    end

    context "by users" do
      should "recognize /~username/repositories" do
        assert_recognizes({ :controller => "repositories",
                            :action => "index",
                            :user_id => "zmalltalker"
                          }, "/~zmalltalker/repositories")

        assert_generates("/~zmalltalker/repositories", {
                           :controller => "repositories",
                           :action => "index",
                           :user_id => "zmalltalker",
                         })
      end

      should "recognize /~username/repositories with explicit format" do
        assert_recognizes({ :controller => "repositories",
                            :action => "index",
                            :format => "xml",
                            :user_id => "zmalltalker"
                          }, "/~zmalltalker/repositories.xml")

        assert_generates("/~zmalltalker/repositories.xml", {
                           :controller => "repositories",
                           :action => "index",
                           :user_id => "zmalltalker",
                           :format => "xml",
                         })
      end
    end

    context "by teams" do
      should "recognize /+teamname/repositories" do
        assert_recognizes({ :controller => "repositories",
                            :action => "index",
                            :group_id => "chilimunchers"
                          }, "/+chilimunchers/repositories")

        assert_generates("/+chilimunchers/repositories", {
                           :controller => "repositories",
                           :action => "index",
                           :group_id => "chilimunchers",
                         })
      end

      should "recognize /+teamname/repositories with explicit format" do
        assert_recognizes({ :controller => "repositories",
                            :action => "index",
                            :format => "xml",
                            :group_id => "chilimunchers"
                          }, "/+chilimunchers/repositories.xml")
        assert_generates("/+chilimunchers/repositories.xml", {
                           :controller => "repositories",
                           :action => "index",
                           :group_id => "chilimunchers",
                           :format => "xml",
                         })
      end
    end
  end


  context "Commit routing" do
    setup do
      @sha = "3fa4e130fa18c92e3030d4accb5d3e0cadd40157"
    end

    should "recognize commit sha" do
      assert_recognizes({ :controller => "commits",
                          :action => "show",
                          :project_id => "gitorious",
                          :repository_id => "mainline",
                          :id => @sha,
                        }, {
                          :path => "/gitorious/mainline/commit/#{@sha}",
                          :method => :get
                        })

      assert_generates("/gitorious/mainline/commit/#{@sha}", {
                         :controller => "commits",
                         :action => "show",
                         :project_id => "gitorious",
                         :repository_id => "mainline",
                         :id => @sha,
                       })
    end

    should "route tags with dots in the id" do
      assert_recognizes({ :controller => "commits",
                          :action => "show",
                          :project_id => "gitorious",
                          :repository_id => "mainline",
                          :id => "v0.7.0",
                        }, {
                          :path => "/gitorious/mainline/commit/v0.7.0",
                          :method => :get
                        })

      assert_generates("/gitorious/mainline/commit/v0.7.0", {
                         :controller => "commits",
                         :action => "show",
                         :project_id => "gitorious",
                         :repository_id => "mainline",
                         :id => "v0.7.0",
                       })
    end

    should "route diff format" do
      assert_recognizes({ :controller => "commits",
                          :action => "show",
                          :project_id => "gitorious",
                          :repository_id => "mainline",
                          :id => @sha,
                          :format => "diff",
                        }, "/gitorious/mainline/commit/#{@sha}.diff")

      assert_generates("/gitorious/mainline/commit/#{@sha}.diff", {
                         :controller => "commits",
                         :action => "show",
                         :project_id => "gitorious",
                         :repository_id => "mainline",
                         :id => @sha,
                         :format => "diff"
                       })
    end

    should "route patch format" do
      assert_recognizes({ :controller => "commits",
                          :action => "show",
                          :project_id => "gitorious",
                          :repository_id => "mainline",
                          :id => @sha,
                          :format => "patch",
                        }, "/gitorious/mainline/commit/#{@sha}.patch")

      assert_generates("/gitorious/mainline/commit/#{@sha}.patch", {
                         :controller => "commits",
                         :action => "show",
                         :project_id => "gitorious",
                         :repository_id => "mainline",
                         :id => @sha,
                         :format => "patch"
                       })
    end

    context "diffs" do
      should "route comparison between two commits" do
        sha = "a" * 40
        other_sha = "b" * 40
        assert_recognizes({:controller => "commit_diffs",
                            :action => "show",
                            :project_id => "gitorious",
                            :repository_id => "mainline",
                            :from_id => sha,
                            :id => other_sha
                          }, {
                            :path => "/gitorious/mainline/commit/#{sha}/diffs/#{other_sha}"
                          })
      end
    end

    context "comments" do
      should "route index" do
        assert_recognizes({
            :controller => "commit_comments",
            :action => "index",
            :project_id => "gitorious",
            :repository_id => "capillary",
            :ref => @sha,
            :format => "json"
          }, {
            :path => "/gitorious/capillary/commit/#{@sha}/comments.json",
            :method => :get
          })

        assert_generates("/gitorious/capillary/commit/#{@sha}/comments.json", {
            :controller => "commit_comments",
            :action => "index",
            :project_id => "gitorious",
            :repository_id => "capillary",
            :ref => @sha,
            :format => "json"
          })
      end
    end
  end

  context "Tree routing" do
    should "recognize a single glob with a format" do
      assert_recognizes({ :controller => "trees",
                          :action => "archive",
                          :project_id => "proj",
                          :repository_id => "repo",
                          :branch => "foo"
                        }, "/proj/repo/archive/foo.tar.gz", {
                          :archive_format => "tar.gz"
                        })

      assert_recognizes({ :controller => "trees",
                          :action => "archive",
                          :project_id => "proj",
                          :repository_id => "repo",
                          :branch => "foo",
                          :archive_format => "zip",
                        }, "/proj/repo/archive/foo.zip")
    end

    should "recognize multiple globs with a format" do
      assert_recognizes({ :controller => "trees",
                          :action => "archive",
                          :project_id => "proj",
                          :repository_id => "repo",
                          :branch => "foo/bar",
                          :archive_format => "zip",
                        }, "/proj/repo/archive/foo/bar.zip")

      assert_recognizes({ :controller => "trees",
                          :action => "archive",
                          :project_id => "proj",
                          :repository_id => "repo",
                          :branch => "foo/bar"
                        }, "/proj/repo/archive/foo/bar.tar.gz", {
                          :archive_format => "tar.gz"
                        })
    end
  end

  context "Merge request routing" do
    should "recognize the merge request landing page" do
      assert_recognizes({ :controller => "merge_requests",
                          :action => "oauth_return",
                        }, "/merge_request_landing_page")
    end

    should "generate merge request landing page route" do
      assert_generates("/merge_request_landing_page", {
                         :controller => "merge_requests",
                         :action => "oauth_return"
                       })
    end

    should "recognize show" do
      assert_recognizes({ :controller => "merge_requests",
                          :action => "show",
                          :project_id => "johans-project",
                          :repository_id => "johansprojectrepos",
                          :id => "399"
                        }, {
                          :path => "/johans-project/johansprojectrepos/merge_requests/399",
                          :method => :get
                        })
    end
  end

  context "Site routing" do
    should "recognize /activity" do
      assert_recognizes({ :controller => "site",
                          :action => "public_timeline"
                        }, "/activities")
    end
  end

  context "Site-wide wiki routing" do
    should "generate top-level wiki URL" do
      assert_generates("/wiki", {
                         :controller => "site_wiki_pages",
                         :action => "index"
                       })
    end

    should "generate action URLs for wiki pages" do
      assert_generates("/wiki", {
                         :controller => "site_wiki_pages",
                         :action => "index"
                       })

      assert_generates("/wiki/Testpage", {
                         :controller => "site_wiki_pages",
                         :action => "show",
                         :id => "Testpage"
                       })

      assert_generates("/wiki/Testpage/edit", {
                         :controller => "site_wiki_pages",
                         :action => "edit",
                         :id => "Testpage"
                       })

      assert_generates("/wiki/Testpage/history", {
                         :controller => "site_wiki_pages",
                         :action => "history",
                         :id => "Testpage"
                       })
    end

    should "recognize /wiki/<sitename>/config" do
      assert_recognizes({ :controller => "site_wiki_pages",
                          :action => "repository_config",
                          :site_id =>"siteid"
                        }, "/wiki/siteid/config")
    end

    should "recognize /wiki/<sitename>/writable_by" do
      assert_recognizes({ :controller => "site_wiki_pages",
                          :action => "writable_by",
                          :site_id =>"siteid"
                        }, "/wiki/siteid/writable_by")
    end
  end

  context "Group routing" do
    should "recognize /+group" do
      assert_generates("/+chilieaters", {
                         :controller => "groups",
                         :action => "show",
                         :id => "chilieaters"
                       })

      assert_recognizes({ :controller => "groups",
                          :action => "show",
                          :id => "chilieaters"
                        }, "/+chilieaters")
    end

    context "memberships" do
      should "recognize /+team-name/memberships" do
        assert_generates("/+chilieaters/memberships", {
                           :controller => "memberships",
                           :action => "index",
                           :group_id => "chilieaters"
                         })

        assert_recognizes({ :controller => "memberships",
                            :action => "index",
                            :group_id => "chilieaters"
                          }, {
                            :path => "/+chilieaters/memberships",
                            :method => :get
                          })
      end

      should "recognize /+team-name/memberships/n" do
        assert_generates("/+chilieaters/memberships/42", {
                           :controller => "memberships",
                           :action => "show",
                           :group_id => "chilieaters",
                           :id => 42
                         })

        assert_recognizes({ :controller => "memberships",
                            :action => "show",
                            :group_id => "chilieaters",
                            :id => "42"
                          }, {
                            :path => "/+chilieaters/memberships/42",
                            :method => :get
                          })
      end
    end
  end

  context "Project proposal routing" do
    should "recognize index" do
      assert_recognizes({ :controller => "admin/project_proposals",
                          :action => "index"
                        }, {
                          :path => "/admin/project_proposals",
                          :method => :get
                        })
    end

    should "recognize new" do
      assert_recognizes({ :controller => "admin/project_proposals",
                          :action => "new"
                        }, {
                          :path => "/admin/project_proposals/new",
                          :method => :get
                        })
    end

    should "recognize create" do
      assert_recognizes({ :controller => "admin/project_proposals",
                          :action => "create"
                        }, {
                          :path => "/admin/project_proposals",
                          :method => :post
                        })
    end

    should "recognize approve" do
      assert_recognizes({ :controller => "admin/project_proposals",
                          :action => "approve",
                          :id => "1"
                        }, {
                          :path => "/admin/project_proposals/1/approve",
                          :method => :post
                        })
    end

    should "recognize reject" do
      assert_recognizes({ :controller => "admin/project_proposals",
                          :action => "reject",
                          :id => "1"
                        }, {
                          :path => "/admin/project_proposals/1/reject",
                          :method => :post
                        })
    end
  end

  context "Repository admin routing" do
    should "recognize index" do
      assert_recognizes({ :controller => "admin/repositories",
                          :action => "index"
                        }, {
                          :path => "/admin/repositories",
                          :method => :get
                        })
    end

    should "recognize recreate" do
      assert_recognizes({ :controller => "admin/repositories",
                          :action => "recreate",
                          :id => "1"
                        }, {
                          :path => "/admin/repositories/1/recreate",
                          :method => :put
                        })
    end
  end

  context "API routing" do
    should "recognize log graph" do
      assert_recognizes({ :controller => "api/graphs",
                          :action => "show",
                          :project_id => "gitorious",
                          :repository_id => "mainline",
                          :format => "json"
                        }, {
                          :path => "/api/gitorious/mainline/log/graph.json",
                          :method => :get
                        })
    end
  end

  context "Commit routing" do
    should "recognize feed" do
      assert_recognizes({ :controller => "commits",
                          :action => "feed",
                          :project_id => "gitorious",
                          :repository_id => "mainline",
                          :id => "master",
                          :format => "atom"
                        }, {
                          :path => "/gitorious/mainline/commits/master/feed.atom",
                          :method => :get
                        })
    end
  end

  def recognize_project_action(method, path, action)
    assert_recognizes({ :controller => "projects",
                        :action => action,
                        :id => "gitorious"
                      }, {
                        :path => path,
                        :method => method
                      })

    assert_generates(path, {
                       :controller => "projects",
                       :action => action,
                       :id => "gitorious"
                     })
  end
end
