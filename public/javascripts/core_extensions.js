/*
#--
#   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
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
/*jslint nomen: false, eqeqeq: false, plusplus: false, onevar: false*/
/*global jQuery, window, __objs, __funs*/

(function (arrayProto) {
    if (!arrayProto.each) {
        arrayProto.each = function (callback) {
            jQuery.each(this, callback);
        };
    }

    if (!arrayProto.map) {
        arrayProto.map = function (callback) {
            return jQuery.map(this, callback);
        };
    }

    // https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Global_Objects/Array/filter
    if (!arrayProto.filter) {
        arrayProto.filter = function (fun /*, thisp*/) {
            var len = this.length;

            if (typeof fun != "function") {
                throw new TypeError();
            }

            var res = [];
            var thisp = arguments[1];

            for (var i = 0; i < len; i++) {
                if (i in this) {
                    var val = this[i]; // in case fun mutates this

                    if (fun.call(thisp, val, i, this)) {
                        res.push(val);
                    }
                }
            }

            return res;
        };
    }

    // http://ejohn.org/blog/fast-javascript-maxmin/
    if (!arrayProto.max) {
        arrayProto.max = function () {
            return Math.max.apply(Math, this);
        };
    }

    if (!arrayProto.min) {
        arrayProto.min = function () {
            return Math.min.apply(Math, this);
        };
    }

    // http://www.martienus.com/code/javascript-remove-duplicates-from-array.html
    // Possibly unexpected result: Due to type coercion,
    // unique removes "4" from [1, 2, 3, 4, "4"]
    if (!arrayProto.unique) {
        arrayProto.unique = function () {
            var r = [];

            o: for (var i = 0, n = this.length; i < n; i++) {
                for (var x = 0, y = r.length; x < y; x++) {
                    if (r[x] == this[i]) {
                        continue o;
                    }
                }

                r[r.length] = this[i];
            }

            return r;
        };
    }
}(Array.prototype));

if (!String.prototype.isBlank) {
    String.prototype.isBlank = function () {
        return this == "";
    };
}

if (!Function.prototype.bind) {
    // http://laurens.vd.oever.nl/weblog/items2005/closures/
    Function.prototype.bind = function (obj) {
        var fun, funId, objId, closure;

        // Init object storage.
        if (!window.__objs) {
            window.__objs = [];
            window.__funs = [];
        }

        // For symmetry and clarity.
        fun = this;

        // Make sure the object has an id and is stored in the object store.
        objId = obj.__objId;

        if (!objId) {
            __objs[objId = obj.__objId = __objs.length] = obj;
        }

        // Make sure the function has an id and is stored in the function store.
        funId = fun.__funId;

        if (!funId) {
            __funs[funId = fun.__funId = __funs.length] = fun;
        }

        // Init closure storage.
        if (!obj.__closures) {
            obj.__closures = [];
        }

        // See if we previously created a closure for this object/function pair.
        closure = obj.__closures[funId];

        if (closure) {
            return closure;
        }

        // Clear references to keep them out of the closure scope.
        obj = null;
        fun = null;

        // Create the closure, store in cache and return result.
        return __objs[objId].__closures[funId] = function () {
            return __funs[funId].apply(__objs[objId], arguments);
        };
    };
}
