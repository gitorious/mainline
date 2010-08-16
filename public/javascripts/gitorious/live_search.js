/*
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
/*global jQuery, window*/

/*
  Creating a jquery extension
*/
jQuery.fn.liveSearch = function (backend, opt) {
    // Set some options
    var options = jQuery.extend({
        resultContainer: ".live-search-results",
        backend: this.backend,
        waitingClass: "waiting",
        resourceUri: "/foo/bar",
        delay: 250,
        itemCass: "result",
        renderer: {
            render: function (obj) {
                return jQuery("<li class=\"item\">" + obj.name + "</li>");
            }
        }
    }, opt);

    var element = this, // Keep this, ie. where this is started, as element
        container = element.find(options.resultContainer),  // Where the results go
        timer,  // Timing to avoid parallell searches
        previous,  // The last search term
        input = element.find("input[type=text]"),  
        uri = options.resourceUri + "?" + input.attr("name") + "=",
        resetter,
        noResults = element.find(".no-results-found");  
    
    // Create the container element if it doesn't exist
    if (container.length === 0) {
        container = jQuery('<ul class="live-search-results"></ul>');
        container.appendTo(element);
    }

    container.hide();
    noResults.hide();

    resetter = element.find(".reset");
    
    resetter.hide();

    // Stop the timer
    function stopTimer() {
        return timer && (timer = window.clearTimeout(timer));
    }

    /*
      The logic behind it all. This object is returned, so it can be manipulated in tests
    */
    var publicApi = {
        // Receive a search, queue it for some time, then perform the search
        queueSearch: function (phrase) {
            if (phrase === "") {
                this.reset();
                return;
            }

            if (new RegExp("^" + previous + "jQuery", "i").test(phrase)) {
                return;
            }

            stopTimer();
            previous = phrase;

            timer = window.setTimeout(function () {
                return this.performSearch(phrase);
            }.bind(this), options.delay);
        },

        // Actually call out to the backend and perform the search
        performSearch: function (phrase) {
            stopTimer();
            previous = phrase;
            element.addClass(options.waitingClass);
            var callback = this.populate.bind(this);
            backend.get(uri, phrase, callback);
        },

        // When we receive a result, populate this into the dom
        populate: function (result, phrase) {
            if (typeof result != "object") {
                throw new TypeError("Expected an object");
            }

            if (options.onDisplay) {
                options.onDisplay();
            }

            resetter.show();
            element.removeClass(options.waitingClass);
            container.html("").show();

            if (result.length < 1) {
                noResults.show();
            } else {
                noResults.hide();
                jQuery.each(result, function (i, obj) {
                    var markup = options.renderer.render(obj);
                    markup.appendTo(container);
                });
            }
        },

        // Remove the search results, call into onReset 
        reset: function () {
            if (options.onReset) {
                options.onReset();
            }

            input.val("");
            resetter.hide();
            container.hide();
        }
    };

    // Hook into the events in the DOM
    (function () {
        var handler = function (e) {
            return publicApi.queueSearch(input.val());
        };
        
        var resetFunc = function (e) {
            return publicApi.reset();
        };

        input.keyup(handler);    
        input.focus(handler);
        resetter.click(resetFunc);
        element.submit(handler);
    }());

    return publicApi; // Return the API itself so we can play around with it
};
