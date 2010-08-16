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
/*jslint newcap: false, onevar: false*/
/*global gitorious, sinon, jQuery, TestCase, assertTrue,
         assert, assertFalse, assertEquals, assertNotEquals*/

(function () {
    var g = gitorious;

    TestCase("ResourceTogglerTest", {
        setUp: function () {
            this.postUrl = "/favorites/repository/1";
            this.deleteUrl = "/favorites/123";
            this.toggler = g.create(g.resourceToggler);
            this.toggler.url = this.deleteUrl;
            this.toggler.element = jQuery("<a href='#'>Watch</a>");

            this.server = sinon.fakeServerWithClock.create();
            this.server.fakeHTTPMethods = true;
            this.server.respondWith("POST", "", [200, { "Location": this.deleteUrl }]);
            this.server.respondWith("DELETE", "", [200, { "Location": this.postUrl }]);
        },

        tearDown: function () {
            this.server.restore();
        },

        "test should initially be enabled": function () {
            assertTrue(this.toggler.enabled);
        },

        "test should disable toggler": function () {
            this.toggler.toggleState();

            assertFalse(this.toggler.enabled);
        },

        "test should enable toggler": function () {
            this.toggler.enabled = false;
            this.toggler.toggleState();

            assert(this.toggler.enabled);
        },

        "test should remove waiting class when disabling": function () {
            this.toggler.toggleState();

            assertEquals("disabled", this.toggler.element.attr("className"));
        },

        "test should remove waiting class when enabling": function () {
            this.toggler.enabled = false;
            this.toggler.toggleState();

            assertEquals("enabled", this.toggler.element.attr("className"));
        },

        "test toggle should add waiting class": function () {
            this.toggler.toggleResource();

            assertEquals("waiting", this.toggler.element.attr("className"));
        },

        "test toggle disable enabled toggler": function () {
            this.toggler.toggleResource();
            this.server.respond();

            assertEquals("disabled", this.toggler.element.attr("className"));
        },

        "test toggle enable disabled toggler": function () {
            this.toggler.toggleResource();
            this.toggler.toggleResource();
            this.server.respond();
            
            assertEquals("enabled", this.toggler.element.attr("className"));
        },

        "test should change URL from Location header": function () {
            this.toggler.toggleResource();
            this.server.respond();

            assertEquals(this.postUrl, this.toggler.url);
        },

        "test should change URL from Location header when enabling": function () {
            this.toggler.toggleResource();
            this.server.respond();
            var url = this.toggler.url;
            this.toggler.toggleResource();
            this.server.respond();

            assertNotEquals(url, this.toggler.url);
            assertEquals(this.deleteUrl, this.toggler.url);
        },

        "test should change text when enabling": function () {
            this.toggler.texts = { enabled: "Unwatch", disabled: "Watch" };
            this.toggler.enabled = false;

            this.toggler.toggleState();

            assertEquals("Unwatch", this.toggler.element.text());
        },

        "test should change text when disabling": function () {
            this.toggler.texts = { enabled: "Unwatch", disabled: "Watch" };
            this.toggler.enabled = false;

            this.toggler.toggleState();
            this.toggler.toggleState();

            assertEquals("Watch", this.toggler.element.text());
        }
    });

    TestCase("ToggleResourceTest", {
        setUp: function () {
            /*:DOC += <div>
                        <a data-request-method="delete" class="enabled" id="watch-enabled"
                           href="/favorites/unwatch">Unwatch</a>
                        <a data-request-method="post" class="disabled" id="watch-disabled"
                           href="/favorites/watch">Watch</a>
                      </div>
            */

            this.enabledEl = jQuery("#watch-enabled");
            this.disabledEl = jQuery("#watch-disabled");

            this.server = sinon.fakeServerWithClock.create();
            this.server.fakeHTTPMethods = true;
            this.server.respondWith("POST", "", [200, { "Location": "/created" }]);
            this.server.respondWith("DELETE", "", [200, { "Location": "/deleted" }]);
        },

        tearDown: function () {
            this.server.restore();
        },

        "test should initialize enabled toggler": function () {
            var toggler = g.toggleResource(this.enabledEl, {
                texts: { disabled: "Watch", enabled: "Unwatch" }
            });

            assert(toggler.enabled);
            assertEquals("/favorites/unwatch", toggler.url);
        },

        "test should initialize disabled toggler": function () {
            var toggler = g.toggleResource(this.disabledEl, {
                texts: { disabled: "Watch", enabled: "Unwatch" }
            });

            assertFalse(toggler.enabled);
            assertEquals("/favorites/watch", toggler.url);
        },

        "test should disable enabled toggler": function () {
            var toggler = g.toggleResource(this.enabledEl, {
                texts: { disabled: "Watch", enabled: "Unwatch" }
            });

            this.enabledEl.click();
            this.server.respond();

            assertEquals("Watch", this.enabledEl.text());
            assertEquals("disabled", this.enabledEl.attr("className"));
            assertEquals("/deleted", toggler.url);
        },

        "test should enable disabled toggler": function () {
            var toggler = g.toggleResource(this.disabledEl, {
                texts: { disabled: "Watch", enabled: "Unwatch" }
            });

            this.disabledEl.click();
            this.server.respond();

            assertEquals("Unwatch", this.disabledEl.text());
            assertEquals("enabled", this.disabledEl.attr("className"));
            assertEquals("/created", toggler.url);
        },

        "test enable - disable - enable": function () {
            var toggler = g.toggleResource(this.disabledEl, {
                texts: { disabled: "Watch", enabled: "Unwatch" }
            });

            this.disabledEl.click();
            this.server.respond();
            this.disabledEl.click();
            this.server.respond();

            assertEquals("Watch", this.disabledEl.text());
            assertEquals("disabled", this.disabledEl.attr("className"));
            assertEquals("/deleted", toggler.url);
        },

        "test jQuery plugin": function () {
            this.enabledEl.toggleResource({
                texts: { enabled: "Unwatch", disabled: "Watch" }
            });

            this.enabledEl.click();
            this.server.respond();

            assertEquals("Watch", this.enabledEl.text());
            assertEquals("disabled", this.enabledEl.attr("className"));
        }
    });
}());
