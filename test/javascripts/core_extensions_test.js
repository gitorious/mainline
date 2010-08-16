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
/*global Gitorious, TestCase, assertEquals, assertSame*/

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
    },

    "test unique": function () {
        var obj = {};
        var obj2 = {};
        var fn = function () {};
        var fn2 = function () {};
        var arr = [1, 2, 3, 1, 2, 3, "4", obj, fn, fn2, obj2, 21];

        assertEquals([1, 2, 3, "4", obj, fn, fn2, obj2, 21], arr.unique());
    }
});

TestCase("StringExtensionsTest", {
    "test is blank": function () {
        assertEquals(true, "".isBlank());
    }
});

TestCase("FunctionExtensionsTest", {
    "test should bind function to object": function () {
        var thisObj;

        var obj = {
            fn: function () {
                thisObj = this;
            }
        };

        var bound = obj.fn.bind(obj);
        bound();

        assertSame(obj, thisObj);
    },

    "test should bind when called with call": function () {
        var thisObj;

        var obj = {
            fn: function () {
                thisObj = this;
            }
        };

        var bound = obj.fn.bind(obj);
        bound.call({});

        assertSame(obj, thisObj);
    }
});
