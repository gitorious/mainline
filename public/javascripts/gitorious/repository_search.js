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
/*global jQuery, gitorious, document*/

(function (g, jQuery) {
    g.repositorySearch = {
        renderer: {
            escape: function (str) {
                return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            },

            // Should return something that can be appended to a jQuery object
            render: function (repo) {
                var row = jQuery('<li class="clone"></li>');
                var repoTitle = this.escape(repo.description || repo.name);

                var title = jQuery('<div class="name"><a href="' + repo.uri + 
                                   '" title="' + repoTitle + '">' +
                                   this.escape(repo.name) + "</a></div>");

                title.appendTo(row);

                var ownerType = repo.owner_type;
                var description = jQuery('<div class="' + this.escape(ownerType) + '"></div>');

                var ownerUri = repo.owner_uri;
                var ownerTag = jQuery('<a href="' + ownerUri + '">' +
                                      this.escape(repo.owner) + '</a>');
                ownerTag.appendTo(description);
                var image = repo.img;

                if (image) {
                    var imageTag = jQuery('<img src="' + image + '" width="16" height="16" />');
                    imageTag.prependTo(description);
                }

                description.appendTo(row);

                return row;
            }
        },

        backend: {
            get: function (uri, phrase, callback) {
                jQuery.getJSON(uri + phrase, function (data) {
                    callback(data);
                });
            }
        },

        // Should not hardcode selectors
        create: function (element) {
            element = jQuery(element);

            return element.liveSearch(this.backend, {
                resourceUri: element.attr("gts:searchUri"),
                itemClass: "clone",
                resultContainer: ".repository_list",
                waitingClass: "searching",
                renderer: this.renderer,

                onDisplay: function () {
                    jQuery(".team_clones").hide();
                    jQuery(".personal_clones").hide();
                    jQuery("#show_all_clones").hide();
                },

                onReset: function () {
                    jQuery(".team_clones").show();
                    jQuery(".personal_clones").show();
                }
            });
        }
    };

    /*
      Live searching on repositories
    */
    jQuery(document).ready(function () {
        g.repositorySearch.create("#repo_search");

        jQuery("#show_all_clones").live("click", function (e) {
            $this = jQuery(this);
            jQuery("#clone-list-container").load($this.attr("href") + ".js");
            $this.hide();

            return false;
        });
    });
}(gitorious, jQuery));
