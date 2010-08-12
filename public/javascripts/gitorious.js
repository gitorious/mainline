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

var gitorious = {
    /**
     * Object.create shim. Implemented in the gitorious namespace rather than
     * globally on Object because the shim cannot be made ES5 compliant in ES3
     * environments (not possible to create object with null prototype, no
     * property descriptor).
     */
    create: (function () {
        function F() {}

        return function (proto) {
            F.prototype = proto;
            return new F();
        };
    }())
};

// Legacy, to be removed
var Gitorious = gitorious;
