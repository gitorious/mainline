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
/*jslint newcap: false, onevar: false, nomen: false*/
/*global jQuery, gitorious, Gitorious, TestCase,
         assertSame, assertFalse, assertTrue, assertEquals*/

TestCase("MergeRequestControllerTest", {
    tearDown: function () {
        Gitorious.MergeRequestController.getInstance()._setTransport(jQuery);
    },

    "test should be singleton": function () {
        var firstController = Gitorious.MergeRequestController.getInstance();
        var secondController = Gitorious.MergeRequestController.getInstance();

        assertSame(firstController, secondController);
    },

    "test should not require reload if sha does not change": function () {
        var c = new Gitorious.MergeRequestController();
        c._setCurrentShaRange("ffac");
        c.shaSelected("ffac");

        assertFalse(c.needsUpdate());
    },

    "test should not require reload if version does not change": function () {
        var c = new Gitorious.MergeRequestController();
        c._setCurrentVersion(2);
        c.versionSelected(2);

        assertFalse(c.needsUpdate());
    },

    "test should require update if sha changes": function () {
        var c = new Gitorious.MergeRequestController();
        c._setCurrentShaRange("ffac");
        c.shaSelected("ffcc");

        assertTrue(c.needsUpdate());
    },

    "test fetch shas in version": function () {
        var c = Gitorious.MergeRequestController.getInstance();
        var shasFetched = false;

        var controllerMock = {
            ajax: function (options) {
                gitorious.app.notify("MergeRequestShaListingReceived",
                                     true, "data", "text");
            }
        };

        // Mocking this one, as it depends on the DOM
        c.replaceShaListing = function (html) {
            this._shaListing = html;
        };

        c._setTransport(controllerMock);
        c.versionChanged(7);

        assertTrue(c.needsUpdate());
    },
    
    "test select different version": function () {
        var c = Gitorious.MergeRequestController.getInstance();
        c._setCurrentShaRange("ffac");
        c._setCurrentVersion(2);

        var ControllerMock = function () {
            this.called = false;
            this.ajax = function (args) {
                this.calledWith = args;
            };

            this.ajaxReceived = function () {
                gitorious.app.notify("MergeRequestDiffReceived", "data", "message");
            };
        };

        var m = new ControllerMock();
        c._setTransport(m);

        c.update({'version': 1, 'sha': 'ffcc-aa90888'});
        var callArgs = m.calledWith;

        assertEquals("ffcc-aa90888", callArgs.data.commit_shas);
        m.ajaxReceived();
        assertFalse(c.needsUpdate());    
    },

    "test parse sha and return instance": function () {
        var spec = Gitorious.ShaSpec.parseShas("abc-bcd");

        assertEquals("abc-bcd", spec.shaSpec());
    }
});

TestCase("ShaSpecTest", {
    "test should add sha": function () {
        var spec = new Gitorious.ShaSpec();
        var count = spec.allShas.length;

        spec.addSha("foo");
        spec.addSha("bar");

        assertEquals(2, spec.allShas.length - count);
    },

    "test parse shas pair": function () {
        var spec = new Gitorious.ShaSpec();

        spec.parseShas("foo-bar");

        assertEquals(2, spec.allShas.length);
        assertEquals("foo", spec.firstSha().fullSha);
        assertEquals("bar", spec.lastSha().fullSha);
        assertEquals("foo-bar", spec.shaSpec());
    },

    "test parse shas single": function () {
        var spec = new Gitorious.ShaSpec();

        spec.parseShas("foo");

        assertEquals(1, spec.allShas.length);
        assertEquals("foo", spec.firstSha().fullSha);
        assertEquals("foo", spec.shaSpec());
    }
});

TestCase("CommentFormTest", {
    "test prefix initial comment body": function () {
        var commentForm = new Gitorious.CommentForm("foo/bar.rb");

        commentForm.setInitialCommentBody("  foo\nbar\nbaz");

        assertEquals("> foo\n> bar\n> baz\n\n", commentForm.initialCommentBody);
    },

    "test prefix initial comment body with windoze line endings": function () {
        var commentForm = new Gitorious.CommentForm("foo/bar.rb");

        commentForm.setInitialCommentBody("  foo\r\nbar\r\nbaz");

        assertEquals("> foo\n> bar\n> baz\n\n", commentForm.initialCommentBody);
    },

    "test lines as internal format": function () {
        var cf = new Gitorious.CommentForm("foo/bar.rb");

        cf.numbers = ["1-1", "2-2", "3-3"];

        assertEquals("1-1:3-3+2", cf.linesAsInternalFormat());
    },

    "test should get a summary": function () {
        var cf = new Gitorious.CommentForm("file.txt");

        assertEquals("Commenting on file.txt", cf.getSummary());
    },

    "test should get the last line number tuple": function () {
        var cf = new Gitorious.CommentForm("file.txt");

        cf.setLineNumbers(["1-1", "2-1", "3-1"]);

        assertEquals("3-1", cf.lastLineNumber());
    }
});
