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
MergeRequestControllerTest = TestCase("Merge request controller", {
    tearDown: function() {
        Gitorious.MergeRequestController.getInstance()._setTransport(jQuery);
    },
    testSingleton: function() {
        var firstController = Gitorious.MergeRequestController.getInstance();
        var secondController = Gitorious.MergeRequestController.getInstance();
        assertSame(firstController, secondController);
    },
    testNoReloadUnlessChanged: function() {
        var c = new Gitorious.MergeRequestController();
        c._setCurrentShaRange("ffac");
        c.shaSelected("ffac");
        assertFalse(c.needsUpdate());
        c._setCurrentVersion(2);
        c.versionSelected(2);
        assertFalse(c.needsUpdate());
        c.shaSelected("ffcc");
        assertTrue(c.needsUpdate());
    },
    testFetchShasInVersion: function() {
        var c = Gitorious.MergeRequestController.getInstance();
        var shasFetched = false;
        var controllerMock = {
            ajax: function(options){
                NotificationCenter.notifyObservers("MergeRequestShaListingReceived",
                                                   true, "data","text");
            }
        }
        // Mocking this one, as it depends on the DOM
        c.replaceShaListing = function(html) {
            this._shaListing = html;
        }
        c._setTransport(controllerMock);
        c.versionChanged(7);
        assertTrue(c.needsUpdate());
    },
    
    testSelectDifferentVersion: function() {
        var c = Gitorious.MergeRequestController.getInstance();
        c._setCurrentShaRange("ffac");
        c._setCurrentVersion(2);

        var ControllerMock = function() {
            this.called = false;
            this.ajax = function(args){
                this.calledWith = args;
            };
            this.ajaxReceived = function() {
                NotificationCenter.notifyObservers("MergeRequestDiffReceived",
                                                   "data", "message");
            }
        };
        var m = new ControllerMock();

        c._setTransport(m);

        c.update({'version': 1, 'sha': 'ffcc-aa90888'});
        var callArgs = m.calledWith;
        assertEquals("ffcc-aa90888", callArgs.data.commit_shas);
        m.ajaxReceived();
        assertFalse(c.needsUpdate());    
    },
    testParseShaAndReturnInstance: function() {
        var spec = Gitorious.ShaSpec.parseShas("abc-bcd");
        assertEquals("abc-bcd", spec.shaSpec());
    }
});

ShaSpecTest = TestCase("Sha specs", {
    testAddSha: function() {
        var spec = new Gitorious.ShaSpec();
        assertEquals(0, spec.allShas.length);
        spec.addSha("foo");
        assertEquals(1, spec.allShas.length);
        spec.addSha("bar");
        assertEquals(2, spec.allShas.length);
    },

    testParseShasPair: function() {
        var spec = new Gitorious.ShaSpec();
        spec.parseShas("foo-bar");
        assertEquals(2, spec.allShas.length);
        assertEquals("foo", spec.firstSha().fullSha);
        assertEquals("bar", spec.lastSha().fullSha);
        assertEquals("foo-bar", spec.shaSpec());
    },

    testParseShasSingle: function() {
        var spec = new Gitorious.ShaSpec();
        spec.parseShas("foo");
        assertEquals(1, spec.allShas.length);
        assertEquals("foo", spec.firstSha().fullSha);
        assertEquals("foo", spec.shaSpec());
    }
});