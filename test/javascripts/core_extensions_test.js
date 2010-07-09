/*
#--
#   Copyright (C) 2009 Marius Mathiesen <marius.mathiesen@gmail.com>
#   Copyright (C) 2010 Christian Johansen <christian@cjohansen.no>
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
/*global Gitorious, TestCase, assertEquals */

TestCase("ArrayExtensionsTest", {
    "test map": function () {
        var arr = ["foo", "bar"];

        var result = arr.map(function (e) {
            return e + "s";
        });

        assertEquals(["foos", "bars"], result);
    },

    "test filter": function () {
        var arr = ["foo", "bar"];

        var result = arr.filter(function (el, i) {
            return el != "bar";
        });

        assertEquals(["foo"], result);
    },

    "test min and max": function () {
        var arr = [1, 2, 3];

        assertEquals(1, arr.min());
        assertEquals(3, arr.max());
        assertEquals(100, [1, "100", "99", 99].max());
    }
});

TestCase("StringExtensionsTest", {
    "test is blank": function () {
        assertEquals(true, "".isBlank());
    }
});
