# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
  context "Project routing" do
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

        assert_generates("/gitorious/mainline", {
                           :controller => "repositories",
                           :action => "show",
                           :project_id => "gitorious",
                           :id => "mainline",
                         })

        assert_generates("/gitorious/mainline/trees", {
                           :controller => "trees",
                           :action => "index",
                           :project_id => "gitorious",
                           :repository_id => "mainline",
                         })

        assert_generates("/gitorious/mainline/trees/foo/bar/baz", {
                           :controller => "trees",
                           :action => "show",
                           :project_id => "gitorious",
                           :repository_id => "mainline",
                           :branch_and_path => %w[foo bar baz]
                         })
      end

      should "recognizes routing like /projectname/repositories" do
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

      # TODO: There's nothing reserved here?
      should "recognize /projectname/starts-with-reserved-name" do
        assert_recognizes({ :controller => "repositories",
                            :action => "show",
                            :project_id => "myproject",
                            :id => "users-test-repo",
                          }, "/myproject/users-test-repo")

        assert_generates("/myproject/users-test-repo", {
                           :controller => "repositories",
                           :action => "show",
                           :project_id => "myproject",
                           :id => "users-test-repo",
                         })
      end

      should "recognize /projectname/reponame with explicit format" do
        assert_recognizes({ :controller => "repositories",
                            :action => "show",
                            :project_id => "gitorious",
                            :format => "xml",
                            :id => "mainline",
                          }, "/gitorious/mainline.xml")

        assert_recognizes({ :controller => "merge_requests",
                            :action => "index",
                            :format => "xml",
                            :project_id => "gitorious",
                            :repository_id => "mainline",
                          }, "/gitorious/mainline/merge_requests.xml")

        assert_generates("/gitorious/mainline.xml", {
                           :controller => "repositories",
                           :action => "show",
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
        assert_recognizes({ :controller => "repositories",
                            :action => "search_clones",
                            :format => "json",
                            :project_id => "gitorious",
                            :id => "mainline"
                          }, "/gitorious/mainline/search_clones.json")

        assert_generates("/gitorious/mainline/search_clones.json", {
                           :controller => "repositories",
                           :action => "search_clones",
                           :project_id => "gitorious",
                           :id => "mainline",
                           :format => "json"
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

      should "recognize /~user/reponame" do
        assert_recognizes({ :controller => "repositories",
                            :action => "show",
                            :user_id => "zmalltalker",
                            :id => "gts-mainline",
                          }, "/~zmalltalker/gts-mainline")

        assert_generates("/~zmalltalker/gts-mainline", {
                           :controller => "repositories",
                           :action => "show",
                           :user_id => "zmalltalker",
                           :id => "gts-mainline",
                         })
      end

      should "recognize /~user/reponame/action" do
        assert_recognizes({ :controller => "repositories",
                            :action => "edit",
                            :user_id => "zmalltalker",
                            :id => "gts-mainline",
                          }, "/~zmalltalker/gts-mainline/edit")

        assert_generates("/~zmalltalker/gts-mainline/edit", {
                           :controller => "repositories",
                           :action => "edit",
                           :user_id => "zmalltalker",
                           :id => "gts-mainline",
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

        should "recognize /~user.name/forgot_password" do
          assert_recognizes({ :controller => "users",
                              :action => "forgot_password",
                              :id => "user.name"
                            }, "/~user.name/forgot_password")

          assert_generates("/~user.name/forgot_password", {
                             :controller => "users",
                             :action => "forgot_password",
                             :id => "user.name"
                           })
        end

        should "recognize /~user.name/myrepo" do
          assert_recognizes({ :controller => "repositories",
                              :action => "show",
                              :user_id => "user.name",
                              :id => "myrepo",
                            }, "/~user.name/myrepo")

          assert_generates("/~user.name/myrepo", {
                             :controller => "repositories",
                             :action => "show",
                             :user_id => "user.name",
                             :id => "myrepo",
                           })
        end

        should "recognize /~user.name/myrepo/action" do
          assert_recognizes({ :controller => "repositories",
                              :action => "edit",
                              :user_id => "user.name",
                              :id => "myrepo",
                            }, "/~user.name/myrepo/edit")

          assert_generates("/~user.name/myrepo/edit", {
                             :controller => "repositories",
                             :action => "edit",
                             :user_id => "user.name",
                             :id => "myrepo",
                           })
        end
      end
    end

    context "by teams" do
      should "recognizes routing like /+teamname/repositories" do
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

      should "recognize /+teamname/repo" do
        assert_recognizes({ :controller => "repositories",
                            :action => "show",
                            :group_id => "chilimunchers",
                            :id => "gts-mainline"
                          }, "/+chilimunchers/gts-mainline")

        assert_generates("/+chilimunchers/gts-mainline", {
                           :controller => "repositories",
                           :action => "show",
                           :group_id => "chilimunchers",
                           :id => "gts-mainline"
                         })
      end

      should "recognize /+teamname/repo/action" do
        assert_recognizes({ :controller => "repositories",
                            :action => "clone",
                            :group_id => "chilimunchers",
                            :id => "gts-mainline"
                          }, "/+chilimunchers/gts-mainline/clone")

        assert_generates("/+chilimunchers/gts-mainline/clone", {
                           :controller => "repositories",
                           :action => "clone",
                           :group_id => "chilimunchers",
                           :id => "gts-mainline"
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
end
