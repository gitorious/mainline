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
/*jslint newcap: false, onevar: false*/
/*global replaceRailsGeneratedForm, jQuery, TestCase, assertTrue, assertFalse,
         assertEquals */

TestCase("Replace Rails generated forms", {
    setUp: function () {
        /*:DOC += <p id="c"><a data-request-method="delete" class="enabled" id="me" href="/favorites/123">Stop the game</a></p>*/
    },

    "test original link should be replaced": function () {
        var elementToReplace = jQuery("[data-request-method]");
        var api = replaceRailsGeneratedForm(jQuery("#me"));
        var el = jQuery("a[href='#me_']");

        assertEquals("me_", el.attr("id"));
        assertEquals(0, jQuery("[data-request-method]:visible").length);
    },

    "test success callback should toggle method": function () {
        var api = replaceRailsGeneratedForm(jQuery("#me"));

        assertEquals("delete", api.httpMethod());
        api.success();
        assertEquals("post", api.httpMethod());
        api.success();
        assertEquals("delete", api.httpMethod());
    },

    "test success callback should change inner HTML": function () {
        var api = replaceRailsGeneratedForm(jQuery("#me"));
        var el = api.element();
        api.success();

        assertEquals("Start the game", el.html());
        api.success();
        assertEquals("Stop the game", el.html());
    },

    "test complete callback should change location": function () {
        var api = replaceRailsGeneratedForm(jQuery("#me"));

        api.complete({
            getResponseHeader: function () {
                return "/people";
            }
        });

        assertEquals("/people", api.action());
    },

    "test should accept custom replacement texts": function () {
        /*:DOC += <p id="c"><a data-request-method="post" id="f" href="/favorites/123">Let the party end</a></p>*/
        var api = replaceRailsGeneratedForm(jQuery("#f"), {replaceWords: ["begin", "end"]});
        api.success();

        assertEquals("Let the party end", api.element().html());
        api.success();
        assertEquals("Let the party begin", api.element().html());
    },

    "test should accept custom id on inserted elements": function () {
        var api = replaceRailsGeneratedForm(jQuery("#me"), { linkName: "newLink" });
        var el = api.element();

        assertEquals("newLink", el.attr("id"));
    },

    "test should reuse CSS classes added to original element": function () {
        var api = replaceRailsGeneratedForm(jQuery("#me"));
        var el = api.element();

        assertTrue(el.hasClass("enabled"));
    },

    "test should toggle CSS classes provided": function () {
        var api = replaceRailsGeneratedForm(jQuery("#me"), {
            toggleClasses: ["enabled", "disabled"]
        });

        var el = api.element();
        api.success();

        assertFalse(el.hasClass("enabled"));
        assertTrue(el.hasClass("disabled"));
        api.success();
        assertFalse(el.hasClass("disabled"));
        assertTrue(el.hasClass("enabled"));
    },

    "test should toggle an optional class when loading": function () {
        var api = replaceRailsGeneratedForm(jQuery("#me"), {
            backend: function () {},
            waitingClass: "wait"
        });

        api.click();
        var el = api.element();

        assertTrue(el.hasClass("wait"));
        api.success();
        assertFalse(el.hasClass("wait"));
    }
});
