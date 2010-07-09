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
/*jslint onevar: false, eqeqeq: false, plusplus: false*/
/*global gitorious*/

(function () {
    var observable = gitorious.create(gitorious.observable);

    gitorious.app = {
        observe: observable.observe.bind(observable),
        notify: observable.notify.bind(observable),
        removeObserver: observable.removeObserver.bind(observable),
        emptyObservers: observable.emptyObservers.bind(observable),

        init: function () {
            // Will eventually handle all bootstrapping
        }
    };
}());
