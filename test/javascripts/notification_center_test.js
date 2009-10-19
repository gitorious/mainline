/*
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

NotificationCenterTest = TestCase("Notification Center", {
    testShouldHaveADefaultNotificationCenter: function() {
        var nc = NotificationCenter;
        assertNotNull(nc);
        assertEquals("default notification center", nc.name);
        assertEquals(nc.name, NotificationCenter.name);
    },

    testShouldAddAnObserver: function() {
        var nc = new NotificationCenterManager("test");
        var observingObject = { callback: function(){ "callback ran" } };
        var sendingObject = "sender";
        nc.addObserver("someIdentifier", observingObject, 
                       observingObject.callback, sendingObject);
        assertEquals(sendingObject, nc.observers["someIdentifier"][0].sender);
    },

    testShouldNotifyAnObserver: function() {
        var nc = new NotificationCenterManager("test");
        var callbackResult = null;
        var receiver = { callback: function(){ callbackResult = "callback ran"; } };
        var SendingObject = function() {
            var self = this;
            this.notify = function() {
                return nc.notifyObservers("aTest", self);
            }
        };
        var sender = new SendingObject();
        nc.addObserver("aTest", receiver, receiver.callback, sender);
        assertTrue(sender.notify());
        assertEquals("callback ran", callbackResult);
    },

    testShouldSendArgumentsToCallback: function() {
        var nc = new NotificationCenterManager("test");
        var tally = 0;
        var receiver = {
            incrementByCallback: function(sender, amount) {
                tally += amount
            }
        };
        nc.addObserver("incrementor", receiver, receiver.incrementByCallback, this, 3);
        nc.notifyObservers("incrementor", this);
        assertEquals(3, tally);
    },

    testShouldNotifyAllObservers: function() {
        var nc = new NotificationCenterManager("test");
        var callbacksRan = [];
        var receiver = {
            callback: function(sender, id) { callbacksRan.push(id) }
        };
        nc.addObserver("foo", receiver, receiver.callback, this, 1);
        nc.addObserver("foo", receiver, receiver.callback, this, 2);
        nc.addObserver("foo", receiver, receiver.callback, this, 3);
        nc.notifyObservers("foo", this);
        assertEquals([1,2,3], callbacksRan);
    },

    testShouldRemoveAllObservers: function() {
        var nc = new NotificationCenterManager("test");
        nc.addObserver("foo", this, function(){}, this);
        assertNotSame("undefined", typeof(nc.observers["foo"]));
        nc.removeAllObservers("foo");
        assertSame("undefined", typeof(nc.observers["foo"]));
    },

    testShouldRemoveAnObserver: function() {
        var nc = new NotificationCenterManager("test");
        var senderOne = new Object();
        var senderTwo = new Object();
        nc.addObserver("foo", this, function(){}, senderOne);
        nc.addObserver("foo", this, function(){}, senderTwo);
        assertEquals(2, nc.observers["foo"].length);
        assertTrue(nc.removeObserver("foo", senderTwo));
        assertEquals(1, nc.observers["foo"].length);
        assertEquals(senderOne, nc.observers["foo"][0].sender);
    }
});