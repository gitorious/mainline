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

TestCase("Live search for repositories", {
    "test should create the container if it doesn't exist": function() {
        /*:DOC += <div id="repo_search"><input type="text" /></div>*/
        jQuery("#repo_search").liveSearch();
        assertEquals(1, jQuery("#repo_search").find(".live-search-results").length);
    },

    "test should not create the container if it exists": function() {
        /*:DOC += <div id="repo_search"><ol class="live-search-results"></ol></div> */
        jQuery("#repo_search").liveSearch();
        assertEquals(1, jQuery("#repo_search").find(".live-search-results").length);        
    },

    "test should allow a custom result container": function() {
        /*:DOC += <div id="repo_search"><ol class="results"></ol></div> */
        jQuery("#repo_search").liveSearch({resultContainer: ".results"});
        assertEquals(1, jQuery("#repo_search").find(".results").length);
    },

    "test should do nothing if the selector doesn't exist": function() {
        /*:DOC += <div id="repo_search"></div>*/
        jQuery("#no_such_domid").liveSearch();
        assertEquals(0, jQuery(".live-search-results").length);
    },

    "test should hide the result container": function() {
        /*:DOC += <div id="repo_search"><li class="live-search-results"></div></div>*/
        assertEquals(0, jQuery("#repo_search .live-search-results:hidden").length);
        jQuery("#repo_search").liveSearch();
        assertEquals(1, jQuery("#repo_search .live-search-results:hidden").length);
    },


    "test should call the backend's get func when searching": function() {
        /*:DOC += <div id="repo_search"></div>*/
        var result;
        var backend = {
            get: function(uri, phrase, callback) {
                result = phrase;
            }
        };
        var api = jQuery("#repo_search").liveSearch(backend);
        api.performSearch("Foo");
        assertEquals("Foo", result);
    },

    "test should append search results to result container": function() {
        /*:DOC += <div id="repo_search"></div>*/
        var backend = {
            get: function(uri, phrase, callback) {
                result = [{"name":"gitorious"}];
                callback(result);
            }
        };        
        var api = jQuery("#repo_search").liveSearch(backend, {itemClass: "item"});
        api.performSearch("Foo");
        // The default renderer renders with li class="item"
        assertEquals(1, jQuery("#repo_search .item").length);
    },

    "test should handle non-JSON or invalid responses": function (){
        /*:DOC += <div id="repo_search"></div>*/
        var api = jQuery("#repo_search").liveSearch({});
        assertThrows(TypeError, function (){
            api.populate("testing");
        })
    },
    "test should use the renderer": function () {
        /*:DOC += <div id="s"></div> */
        var renderer = {
            render: function(person) {
                row = jQuery('<li class="foo"></li>');
                (jQuery('<h2 title="' + person.nick + '">' + person.firstName + '</h2>')).appendTo(row);
                (jQuery("<addr>" + person.address + "</addr>")).appendTo(row);
                return row;
            }
        };
        var api = jQuery("#s").liveSearch({}, {renderer: renderer});
        var ourData = [{
                    firstName: "Winnie",
                    address: "Hundred yard forest",
                    nick: "pooh"
        }];
        api.populate(ourData);
        assertEquals("Winnie", jQuery("li.foo h2").html());
    },

    "test should call the optional onDisplay when displaying results": function() {
        /*:DOC += <div id="s"></div> */
        var othersHidden = false;
        var hideOthers = function () {
            othersHidden = true;
        }
        var api = jQuery("#s").liveSearch({}, {onDisplay: hideOthers});
        api.populate({});
        assertTrue(othersHidden);
    },
    
    "test should call the optional onReset when resetting": function() {
        /*:DOC += <div id="s"></div> */
        var othersDisplayed = false;
        var displayOthers = function () {
            othersDisplayed = true;
        }
        var api = jQuery("#s").liveSearch({}, {onReset: displayOthers});
        api.reset();
        assertTrue(othersDisplayed);
        
    },
    "test should hide the reset element if one exists": function() {
        /*:DOC += <div id="s"><div class="reset" style="display:block"></div></div>*/
        var api = jQuery("#s").liveSearch();
        assertEquals(1, jQuery("#s .reset:hidden").length);
    },
    "test should display the reset element when populating": function() {
        /*:DOC += <div id="_s"><div class="reset" style="display:block"></div></div>*/
        var api = jQuery("#_s").liveSearch();
        assertEquals(0, jQuery("#_s .reset:visible").length);
        api.populate([{name: "John Doe"}]);
        assertEquals(1, jQuery("#_s .reset:visible").length);
    },
    "test should reset itself when an empty query is entered": function (){
        /*:DOC += <div id="s"></div> */
        var api = jQuery("#s").liveSearch();
        var reset = false;
        api.reset = function() {
            reset = true;
        };
        api.queueSearch("");
        assertTrue(reset);
    },
    "test should insert a text when no matches found": function (){
        /*:DOC += <div id="s"><div class="no-results-found"></div></div> */
        assertEquals(1, jQuery("#s .no-results-found:visible").length);
        var api = jQuery("#s").liveSearch();
        assertEquals(0, jQuery("#s .no-results-found:visible").length);
        api.populate([]);
        assertEquals(1, jQuery("#s .no-results-found:visible").length);
    },
    "test should hide the no-results container when matches found": function (){
        /*:DOC += <div id="s"><div class="no-results-found"></div></div> */
        assertEquals(1, jQuery("#s .no-results-found:visible").length);
        var api = jQuery("#s").liveSearch();
        assertEquals(0, jQuery("#s .no-results-found:visible").length);
        api.populate([]);
        assertEquals(1, jQuery("#s .no-results-found:visible").length);
        api.populate([{name:"John"}]);
        assertEquals(0, jQuery("#s .no-results-found:visible").length);
    }
});