/*
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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
/*global NotificationCenter, NotificationCenterManager, TestCase, assertNotNull,
         assertNull, assertEquals, assertSame, assertNotSame, assertTrue,
         assertFalse */

TestCase("NotificationCenterTest", {
    "test should have a default notification center": function () {
        var nc = NotificationCenter;

        assertNotNull(nc);
        assertEquals("default notification center", nc.name);
        assertEquals(nc.name, NotificationCenter.name);
    },

    "test should add an observer": function () {
        var nc = new NotificationCenterManager("test");
        var callback = function () {};

        nc.addObserver("someIdentifier", callback);

        assertSame(callback, nc.observers.someIdentifier[0].callback);
    },

    "test should notify an observer": function () {
        var nc = new NotificationCenterManager("test");
        var callbackResult = null;

        var receiver = {
            callback: function () {
                callbackResult = "callback ran";
            }
        };

        var SendingObject = function () {
            var self = this;
            this.notify = function () {
                return nc.notifyObservers("aTest", self);
            };
        };
        var sender = new SendingObject();
        nc.addObserver("aTest", receiver.callback.bind(receiver), sender);
        assertTrue(sender.notify());
        assertEquals("callback ran", callbackResult);
    },

    testShouldSendArgumentsToCallback: function () {
        var nc = new NotificationCenterManager("test");
        var resultingData = null;
        var receiver = {
            successfulCallback: function (message, data) {
                resultingData = data;
            }
        };
        nc.addObserver("notifications", receiver.successfulCallback.bind(receiver));
        nc.notifyObservers("notifications", "hello", "world");
        assertEquals("world", resultingData);
    },

    testShouldNotifyAllObservers: function () {
        var nc = new NotificationCenterManager("test");
        var callbacksRan = [];
        var receiver = {
            callback: function (notifier, id) {
                callbacksRan.push(id);
            }
        };
        nc.addObserver("foo", receiver.callback.bind(receiver));
        nc.notifyObservers("foo", this, 1);
        nc.notifyObservers("foo", this, 2);
        nc.notifyObservers("foo", this, 3);
        assertEquals([1, 2, 3], callbacksRan);
    },

    testShouldRemoveAllObservers: function () {
        var nc = new NotificationCenterManager("test");
        nc.addObserver("foo", function () {}.bind(this), this);
        assertNotSame("undefined", typeof(nc.observers.foo));
        nc.removeAllObservers("foo");
        assertSame("undefined", typeof(nc.observers.foo));
    },

    testShouldRemoveAnObserver: function () {
        var nc = new NotificationCenterManager("test");
        var firstObserver = {};
        var secondObserver = {};
        nc.addObserver("foo", function () {}.bind(firstObserver), firstObserver);
        nc.addObserver("foo", function () {}.bind(secondObserver), secondObserver);
        assertEquals(2, nc.observers.foo.length);
        assertTrue(nc.removeObserver("foo", secondObserver));
        assertEquals(1, nc.observers.foo.length);
        assertEquals(firstObserver, nc.observers.foo[0].sender);
    },

    testSelfReferring: function () {
        var callback = {
            contacted: false,
            doneRunning: false,

            pinged: function () {
                this.contacted = true;
                this.done();
            },
            done: function () {
                this.doneRunning = true;
                NotificationCenter.removeObserver("foo", this);
            }
        };
        NotificationCenter.addObserver("foo", callback.pinged.bind(callback), callback);
        assertFalse(callback.doneRunning);

        NotificationCenter.notifyObservers("foo", {});

        assertTrue(callback.doneRunning);
        assertEquals(0, NotificationCenter.observers.foo.length);
    }
});
