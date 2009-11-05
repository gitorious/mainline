/*
  #--
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
  #-- 
*/
/*
  Live searching on repositories
*/
{}
if (!Gitorious)
    var Gitorious = {};

/*
  Creating a jquery extension
*/
jQuery.fn.liveSearch = function(backend, options) {
    // Set some options
    options = jQuery.extend({
        resultContainer: ".live-search-results",
        backend: this.backend,
        waitingClass: ".waiting",
        resourceUri: "/foo/bar",
        delay: 250,
        itemCass: "result",
        renderer: {render: function (obj) {return jQuery("<li class=\"item\">" + obj.name + "</li>")}}
    }, options);

    // Keep this, ie. where this is started, as element
    var element = this,
    container = element.find(options.resultContainer),
    timer,
    previous,
    input = element.find("input[type=text]"),
    uri = options.resourceUri + "?" + input.attr("name") + "=";
    
    // Create the container element if it doesn't exist
    if (container.length === 0) {
        container = jQuery('<ul class="live-search-results"></ul>');
        container.appendTo(element);
    }
    container.hide();

    // Stop the timer
    function stopTimer() {
        return timer && (timer = clearTimeout(timer));
    }

    /*
      The logic behind it all. This object is returned, so it can be manipulated in tests
    */
    publicApi = {
        
        // Receive a search, queue it for some time, then perform the search
        queueSearch: function(phrase) {
            if (phrase === "" || new RegExp("^" + previous + "$", "i").test(phrase)) {
                return;
            }
            stopTimer();
            previous = phrase;
            timer = setTimeout(function (){
                return this.performSearch(phrase);
            }.bind(this), options.delay);
        },

        // Actually call out to the backend and perform the search
        performSearch: function(phrase) {
            stopTimer();
            previous = phrase;
            element.addClass(options.waitingClass);
            var callback = this.populate.bind(this);
            backend.get(uri, phrase, callback);
        },

        // When we receive a result, populate this into the dom
        populate: function(result, phrase) {
            if (typeof result != "object")
                throw new TypeError("Expected a repository object");

            container.html("").show();
            jQuery.each(result, function (i, repo) {
                markup = options.renderer.render(repo);
                markup.appendTo(container);
            });
        }
    };

    // Hook into the events in the DOM
    (function (){
        var handler = function(e) {
            return publicApi.queueSearch(input.val());
        }
        
        input.keyup(handler);    
        input.focus(handler);
        element.submit(handler);
    })();

    return publicApi; // Return the API itself so we can play around with it

}

$(document).ready(function () {
    searchContainer = jQuery("#repo_search");
    searchUri = searchContainer.attr("gts:searchUri");

    var backend = {get: function (uri, phrase, callback){
        jQuery.getJSON(uri + phrase, function(data) {
            callback(data);
        });
    }}
    var renderer = {
        render: function(repo) {
            row = jQuery('<li class="result"></li>');

            repo_title = repo.description || repo.name

            title = jQuery('<div class="name"><a href="' + repo.uri + 
                           '" title="' + repo_title + '">' + repo.name + "</a></div>");
            title.appendTo(row);
            
            ownerType = repo.owner_type;
            description = jQuery('<div class="' + ownerType + '"></div>');

            ownerUri = repo.owner_uri;
            ownerTag = jQuery('<a href="' + ownerUri + '">' + repo.owner + '</a>');
            ownerTag.appendTo(description);

            
            if (image = repo.img) {
                imageTag = jQuery('<img src="' + image + '" width="16" height="16" />');
                imageTag.prependTo(description);
            }

            description.appendTo(row);
            return row;
        }
    }

    jQuery("#repo_search").liveSearch(backend, {
        resourceUri: searchUri, 
        itemClass: "clone",
        resultContainer: ".repository_list",
        renderer: renderer});
}
                 )
