/*
#--
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
/*jslint onevar: false, eqeqeq: false, plusplus: false, newcap: false*/
/*global Gitorious, TestCase, assertEquals, assertFalse, assertTrue, assertNull */

TestCase("BookmarkableMergeRequestTest", {
    "test should recognize first and last sha with no version": function () {
        var shaSpec = Gitorious.ShaSpec.parseLocationHash("aab00199-bba00199");

        assertEquals("aab00199", shaSpec.firstSha().sha());
        assertEquals("bba00199", shaSpec.lastSha().sha());
        assertFalse(shaSpec.hasVersion());
    },

    "test should recognize version": function () {
        var shaSpec = Gitorious.ShaSpec.parseLocationHash("aab00199-bba00199@2");

        assertTrue(shaSpec.hasVersion());
        assertEquals("2", shaSpec.getVersion());
    },

    "test should ignore leading hash": function () {
        var shaSpec = Gitorious.ShaSpec.parseLocationHash("#aab00199-bba00199@2");

        assertEquals("aab00199", shaSpec.firstSha().sha());
    },

    "test should return null for empty location hash": function () {
        var shaSpec = Gitorious.ShaSpec.parseLocationHash("");

        assertNull(shaSpec);
    }

    /*
      TODO:
      - query the current version from the location hash on load
      - set the current version on selection
      - extract the functionality for selecting commits, versions etc to a single, testable place
    */
});
