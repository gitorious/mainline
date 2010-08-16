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
/*jslint plusplus: false, eqeqeq: false, nomen: false, onevar: false,
         newcap: false*/
/*globals gitorious, TestCase, assertEquals, assertNoException,assertTrue,
          assertFalse, assertException*/

TestCase("ObservableAddObserverTest", {
    setUp: function () {
        this.observable = gitorious.create(gitorious.observable);
    },

    "test should store functions": function () {
        var observers = [function () {}, function () {}];

        this.observable.observe("event", observers[0]);
        this.observable.observe("event", observers[1]);

        assertTrue(this.observable.hasObserver("event", observers[0]));
        assertTrue(this.observable.hasObserver("event", observers[1]));
    },

    "test should throw for uncallable observer": function () {
        var observable = this.observable;

        assertException(function () {
            observable.observe("event", {});
        }, "TypeError");
    }
});

TestCase("ObservableHasObserverTest", {
    setUp: function () {
        this.observable = gitorious.create(gitorious.observable);
    },

    "test should return false when no observers": function () {
        assertFalse(this.observable.hasObserver(function () {}));
    }
});

TestCase("ObservableNotifyObserversTest", {
    setUp: function () {
        this.observable = gitorious.create(gitorious.observable);
    },

    "test should call all observers": function () {
        var observer1 = function () {
            observer1.called = true;
        };

        var observer2 = function () {
            observer2.called = true;
        };

        this.observable.observe("event", observer1);
        this.observable.observe("event", observer2);

        this.observable.notify("event");

        assertTrue(observer1.called);
        assertTrue(observer2.called);
    },

    "test should pass through arguments": function () {
        var actual;

        this.observable.observe("event", function () {
            actual = arguments;
        });

        this.observable.notify("event", "String", 1, 32);

        assertEquals(["String", 1, 32], actual);
    },

    "test should notify all even when some fail": function () {
        var observer1 = function () {
            throw new Error("Oops");
        };

        var observer2 = function () {
            observer2.called = true;
        };

        this.observable.observe("event", observer1);
        this.observable.observe("event", observer2);

        this.observable.notify("event");

        assertTrue(observer2.called);
    },

    "test should call observers in the order they were added": function () {
        var calls = [];

        var observer1 = function () {
            calls.push(observer1);
        };

        var observer2 = function () {
            calls.push(observer2);
        };

        this.observable.observe("event", observer1);
        this.observable.observe("event", observer2);

        this.observable.notify("event");

        assertEquals(observer1, calls[0]);
        assertEquals(observer2, calls[1]);
    },

    "test should not fail if no observers": function () {
        var observable = this.observable;

        assertNoException(function () {
            observable.notify("event");
        });
    },

    "test should notify relevant observers only": function () {
        var calls = [];

        this.observable.observe("event", function () {
            calls.push("event");
        });

        this.observable.observe("other", function () {
            calls.push("other");
        });

        this.observable.notify("other");

        assertEquals(["other"], calls);
    }
});

TestCase("ObservableRemoveObserverTest", {
    setUp: function () {
        this.observable = gitorious.create(gitorious.observable);
    },

    "test should remove observer": function () {
        var observer = function () {};
        this.observable.observe("something", observer);

        this.observable.removeObserver("something", observer);

        assertFalse(this.observable.hasObserver("something", observer));
    },

    "test should not remove observer for wrong event": function () {
        var observer = function () {};
        this.observable.observe("something", observer);

        this.observable.removeObserver("other", observer);

        assertTrue(this.observable.hasObserver("something", observer));
    }
});

TestCase("ObservableEmptyObserversTest", {
    setUp: function () {
        this.observable = gitorious.create(gitorious.observable);
    },

    "test should clear observers for single event": function () {
        var observers = [function () {}, function () {}, function () {}];
        this.observable.observe("something", observers[0]);
        this.observable.observe("something", observers[1]);
        this.observable.observe("else", observers[2]);

        this.observable.emptyObservers("something");

        assertFalse(this.observable.hasObserver("something", observers[0]));
        assertFalse(this.observable.hasObserver("something", observers[1]));
        assertTrue(this.observable.hasObserver("else", observers[2]));
    },

    "test should clear all observers": function () {
        var observers = [function () {}, function () {}, function () {}];
        this.observable.observe("something", observers[0]);
        this.observable.observe("something", observers[1]);
        this.observable.observe("else", observers[2]);

        this.observable.emptyObservers();

        assertFalse(this.observable.hasObserver("something", observers[0]));
        assertFalse(this.observable.hasObserver("something", observers[1]));
        assertFalse(this.observable.hasObserver("else", observers[2]));
    }
});
