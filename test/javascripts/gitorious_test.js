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
#   along with this program. If not, see <http://www.gnu.org/licenses/>.
#--
*/
/*jslint onevar: false, eqeqeq: false, plusplus: false, newcap: false*/
/*global gitorious, TestCase, assert*/

TestCase("GitoriousTest", {
    "test should create object inheriting from other object": function () {
        var obj = {};
        var newObj = gitorious.create(obj);

        assert(obj.isPrototypeOf(newObj));
    }
});
