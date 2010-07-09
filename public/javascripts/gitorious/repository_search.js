/*
#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2009 Marius Mathiesen <marius.mathiesen@gmail.com>
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
/*jslint eqeqeq: false, plusplus: false, onevar: false*/
/*global Gitorious, $, document*/

/*
  Live searching on repositories
*/
if (!this.Gitorious) {
    this.Gitorious = {};
}

$(document).ready(function () {
    var searchContainer = $("#repo_search");
    var searchUri = searchContainer.attr("gts:searchUri");

    var backend = {
        get: function (uri, phrase, callback) {
            $.getJSON(uri + phrase, function (data) {
                callback(data);
            });
        }
    };

    /*
      Renderer for rendering repositories as search results
    */
    var renderer = {
        escape: function (str) {
            return str.replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/&/g, "&amp;");
        },

        // Should return something that can be appended to a $ object
        render: function (repo) {
            var row = $('<li class="clone"></li>');
            var repo_title = this.escape(repo.description || repo.name);

            var title = $('<div class="name"><a href="' + repo.uri + 
                          '" title="' + repo_title + '">' +
                           this.escape(repo.name) + "</a></div>");

            title.appendTo(row);

            var ownerType = repo.owner_type;
            var description = $('<div class="' + this.escape(ownerType) + '"></div>');

            var ownerUri = repo.owner_uri;
            var ownerTag = $('<a href="' + ownerUri + '">' +
                              this.escape(repo.owner) + '</a>');
            ownerTag.appendTo(description);
            var image = repo.img;

            if (image) {
                var imageTag = $('<img src="' + image + '" width="16" height="16" />');
                imageTag.prependTo(description);
            }

            description.appendTo(row);
            return row;
        }
    };

    $("#repo_search").liveSearch(backend, {
        resourceUri: searchUri, 
        itemClass: "clone",
        resultContainer: ".repository_list",
        waitingClass: "searching",
        renderer: renderer,
        onDisplay: function () {
            $(".team_clones").hide();
            $(".personal_clones").hide();
            $("#show_all_clones").hide();
        },
        onReset: function () {
            $(".team_clones").show();
            $(".personal_clones").show();
        }
    });

    $("#show_all_clones").live("click", function (e) {
        $("#clone-list-container").load($(this).attr("href") + ".js");
        $(this).hide();
        return false;
    });
});
