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

TestCase("Replace Rails generated forms", {
    setUp: function (){
        /*:DOC += <p id="c"><a data-request-method="delete" id="me" href="/favorites/123">Stop the game</a></p>*/
    },
    "test original link should be replaced": function () {
        var elementToReplace = jQuery("[data-request-method]");
        var api = jQuery("#me").replaceRailsGeneratedForm();
        var el = jQuery("a[href='#start_watching']");
        assertEquals("start_watching", el.attr("id"));
        assertEquals(0, jQuery("[data-request-method]:visible").length);
    },
    "test success callback should toggle method": function() {
        var api = jQuery("#me").replaceRailsGeneratedForm();
        assertEquals("delete", api.httpMethod());
        api.success();
        assertEquals("post", api.httpMethod());
        api.success();
        assertEquals("delete", api.httpMethod());
    },
    "test success callback should change inner HTML": function (){
        var api = jQuery("#me").replaceRailsGeneratedForm();
        var el = jQuery("#start_watching");
        api.success();
        assertEquals("Start the game", el.html());
        api.success();
        assertEquals("Stop the game", el.html());
    },
    "test complete callback should change location": function () {
        var api = jQuery("#me").replaceRailsGeneratedForm();
        api.complete({getResponseHeader: function() {return "/people"}});
        assertEquals("/people", api.action());
    },
    "test should accept custom replacement texts": function () {
        /*:DOC += <p id="c"><a data-request-method="post" id="f" href="/favorites/123">Let the party end</a></p>*/
        var api = jQuery("#f").replaceRailsGeneratedForm({replaceWords: ["begin","end"]});
        api.success();
        assertEquals("Let the party end", jQuery("#start_watching").html());
        api.success();
        assertEquals("Let the party begin", jQuery("#start_watching").html());
    },
    "test should accept custom id on inserted elements": function () {
        var api = jQuery("#me").replaceRailsGeneratedForm({linkName: "newLink"});
        var el = api.element();
        assertEquals("newLink", el.attr("id"));
    }
});
