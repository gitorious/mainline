/*
  #--
  #   Copyright (C) 2010 Christian Johansen <christian@shortcut.no>
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
  #-- 
*/
/*jslint newcap: false, onevar: false, nomen: false*/
/*global jQuery, gitorious, TestCase, assertSame, assertFalse,
         assertTrue, assertEquals*/

(function () {
    var rs = gitorious.repositorySearch;

    TestCase("RepositoryLiveSearchRendererTest", {
        "test should escape left angle brackets": function () {
            assertEquals("&lt; oh no &lt;", rs.renderer.escape("< oh no <"));
        },

        "test should escape right angle brackets": function () {
            assertEquals("&gt; oh no &gt;", rs.renderer.escape("> oh no >"));
        },

        "test should escape ampersands": function () {
            assertEquals("&amp; oh no &amp;", rs.renderer.escape("& oh no &"));
        },

        "test should escape string": function () {
            assertEquals("&lt;a href='#'&gt;&lt;span&gt;Hey &amp; hey&lt;/span&gt;&lt;/a&gt;",
                         rs.renderer.escape("<a href='#'><span>Hey & hey</span></a>"));
        },

        "test should build markup for repo with name": function () {
            var result = rs.renderer.render({
                name: "Gitorious",
                uri: "/gitorious/mainline",
                owner_type: "owner",
                owner_uri: "/users/cjohansen",
                owner: "Christian Johansen",
                img: "/images/cj.png"
            });

            assertEquals(1, result.length);
            assertTagName("li", result.get(0));
            assertEquals(2, result.find(">*").length);
            assertEquals("Gitorious", result.find("div.name a").attr("title"));
            assertEquals("Gitorious", result.find("div.name a").text());
            assertEquals("/images/cj.png", result.find("div.owner img").attr("src"));
            assertEquals("/users/cjohansen", result.find("div.owner a").attr("href"));
            assertEquals("Christian Johansen", result.find("div.owner a").text());
        },

        "test should build markup for repo with description": function () {
            var result = rs.renderer.render({
                name: "Gitorious",
                description: "Hi, I am Gitorious",
                uri: "/gitorious/mainline",
                owner_type: "owner",
                owner_uri: "/users/cjohansen",
                owner: "Christian Johansen",
                img: "/images/cj.png"
            });

            assertEquals("Hi, I am Gitorious", result.find("div.name a").attr("title"));
            assertEquals("Gitorious", result.find("div.name a").text());
            assertEquals("/images/cj.png", result.find("div.owner img").attr("src"));
            assertEquals("/users/cjohansen", result.find("div.owner a").attr("href"));
            assertEquals("Christian Johansen", result.find("div.owner a").text());
        }
    });

    TestCase("RepositorySearchBackendTest", {
        "test should call jQuery.getJSON": sinon.test(function () {
            this.stub(jQuery, "getJSON");
            var spy = this.spy();

            rs.backend.get("/my/search/", "camera", spy);

            assert(jQuery.getJSON.calledWith("/my/search/camera"));
        }),

        "test jQuery.getJSON should yield data to callback": sinon.test(function () {
            this.stub(jQuery, "getJSON");
            var spy = this.spy();
            var data = {};

            rs.backend.get("/my/search/", "camera", spy);
            jQuery.getJSON.getCall(0).args[1](data);

            assertSame(data, spy.getCall(0).args[0]);
        })
    });

    TestCase("RepositorySearchCreateTest", {
        setUp: function () {
            /*:DOC += <div gts:searchUri="/search" id="repo_search"><input type="text" /></div>*/
        },

        "test should return search api": function () {
            var search = rs.create("#repo_search");

            assertFunction(search.queueSearch);
            assertFunction(search.performSearch);
        },

        "test should get URL from gts:searchUri attribute": sinon.test(function () {
            var stub = this.stub(jQuery.fn, "liveSearch");

            var search = rs.create("#repo_search");

            assertEquals(rs.backend, stub.args[0][0]);
            assertEquals("/search", stub.args[0][1].resourceUri);
            assertEquals(rs.renderer, stub.args[0][1].renderer)
        })
    });
}());
