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
/*jslint plusplus: false, eqeqeq: false, nomen: false, onevar: false*/
/*globals gitorious*/

this.gitorious = this.gitorious || {};

gitorious.observable = (function () {
    // Internal helper
    function getObservers(observable, event) {
        if (!observable.observers) {
            observable.observers = {};
        }

        if (!observable.observers[event]) {
            observable.observers[event] = [];
        }

        return observable.observers[event];
    }

    return {
        observe: function (event, observer) {
            if (typeof observer != "function") {
                throw new TypeError("observer is not function");
            }

            getObservers(this, event).push(observer);
        },

        hasObserver: function (event, observer) {
            var observers = getObservers(this, event);

            for (var i = 0, l = observers.length; i < l; i++) {
                if (observers[i] == observer) {
                    return true;
                }
            }

            return false;
        },

        notify: function (event) {
            var observers = getObservers(this, event);
            var args = Array.prototype.slice.call(arguments, 1);

            for (var i = 0, l = observers.length; i < l; i++) {
                try {
                    observers[i].apply(this, args);
                } catch (e) {}
            }
        },

        removeObserver: function (event, observer) {
            var observers = getObservers(this, event);

            for (var i = 0, l = observers.length; i < l; i++) {
                if (observers[i] === observer) {
                    observers.splice(i, 1);
                    break;
                }
            }
        },

        emptyObservers: function (event) {
            if (event) {
                if (this.observers) {
                    delete this.observers[event];
                }
            } else {
                this.observers = {};
            }
        }
    };
}());
