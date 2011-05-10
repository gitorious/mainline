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
/*jslint nomen: false, eqeqeq: false, plusplus: false, onevar: false,
         regexp: false*/
/*global gitorious, Gitorious, diffBrowserCompactCommitSelectable, $, document, window, console*/

if (!this.Gitorious) {
    this.Gitorious = {};
}

Gitorious.Sha = function (sha) {
    this.fullSha = sha;

    this.shortSha = function () {
        return this.fullSha.substring(0, 7);
    };

    this.sha = function () {
        return this.fullSha;
    };
};

Gitorious.ShaSpec = function () {
    this.allShas = [];

    this.addSha = function (s) {
        this.allShas.push(new Gitorious.Sha(s));
    };

    // Add shas from a string, eg ff0-bba
    this.parseShas = function (shaString) {
        var pair = shaString.split("-");
        this.addSha(pair[0]);

        if (pair.length > 1) {
            this.addSha(pair[1]);
        }
    };

    this.firstSha = function () {
        return this.allShas[0];
    };

    this.lastSha = function () {
        return this.allShas[this.allShas.length - 1];
    };

    this.shaSpecs = function (callback) {
        if (this.allShas.length < 2) {
            return [this.firstSha()];
        } else {
            return [this.firstSha(), this.lastSha()];
        }
    };

    this.shaSpec = function () {
        var _specs = this.shaSpecs();

        return $.map(_specs, function (s) {
            return s.sha();
        }).join("-");
    };

    this.shaSpecWithVersion = function () {
        var result = this.shaSpec();

        if (this.hasVersion()) {
            result = result + "@" + this.getVersion();
        }

        return result;
    };

    this.shortShaSpec = function () {
        var _specs = this.shaSpecs();

        return $.map(_specs, function (s) {
            return s.shortSha();
        }).join("-");
    };

    this.singleCommit = function () {
        return this.firstSha().sha() == this.lastSha().sha();
    };

    this.setVersion = function (v)  {
        this._version = v;
    };

    this.getVersion = function () {
        return this._version;
    };

    this.hasVersion = function () {
        return typeof(this._version) != "undefined";
    };

    this.summarizeHtml = function () {
        $("#current_shas").attr("data-merge-request-current-shas", this.shaSpec());

        if (this.singleCommit()) {
            $("#current_shas .several_shas").hide();
            $("#current_shas .single_sha").show();
            $("#current_shas .single_sha .merge_base").html(this.firstSha().shortSha());
        } else {
            $("#current_shas .several_shas").show();
            $("#current_shas .single_sha").hide();
            $("#current_shas .several_shas .first").html(this.firstSha().shortSha());
            $("#current_shas .several_shas .last").html(this.lastSha().shortSha());
        }
    };
};

Gitorious.ShaSpec.parseLocationHash = function (hash) {
    if (hash == "" || typeof(hash) == "undefined") {
        return null;
    }

    var result = new Gitorious.ShaSpec();
    var _hash = hash.replace(/#/, "");
    var specAndVersion = _hash.split("@");
    result.parseShas(specAndVersion[0]);
    result.setVersion(specAndVersion[1]);

    return result;
};

// Return an instance from a String
Gitorious.ShaSpec.parseShas = function (shaString) {
    var result = new Gitorious.ShaSpec();
    result.parseShas(shaString);

    return result;
};

Gitorious.setDiffBrowserHunkStateFromCookie = function () {
    if ($.cookie("merge-requests-diff-hunks-state") === "expanded") {
        $('#merge_request_diff .file-diff .header').removeClass("closed").addClass("open");
        $('#merge_request_diff .diff-hunks:hidden').show();
    } else if ($.cookie("commits-diff-hunks-state")) {
        if ($.cookie("commits-diff-hunks-state") === "expanded") {
            $('#commit-diff-container .file-diff .header').removeClass("closed").addClass("open");
            $('#commit-diff-container .diff-hunks:hidden').show();
        } else {
            $('#commit-diff-container .file-diff .header').removeClass("open").addClass("closed");
            $('#commit-diff-container .diff-hunks:hidden').hide();
        }
    }
};

gitorious.app.observe("DiffBrowserDidReloadDiffs",
                  Gitorious.setDiffBrowserHunkStateFromCookie);

Gitorious.DiffBrowser = function (shas) {
    gitorious.app.notify("DiffBrowserWillReloadDiffs", this);
    var c = Gitorious.MergeRequestController.getInstance();
    var version = c.determineCurrentVersion();
    c.update({ version: version, sha: shas });
};

Gitorious.DiffBrowser.CommentHighlighter = {
    _lastHighlightedComment: null,

    removePrevious: function () {
        if (!this._lastHighlightedComment) {
            return;
        }

        this.remove(this._lastHighlightedComment);
    },

    add: function (commentElement) {
        this.removePrevious();
        commentElement.addClass("highlighted");
        this.toggle(commentElement, 'highlighted', 'add');
        this._lastHighlightedComment = commentElement;
    },

    remove: function (commentElement) {
        commentElement.removeClass("highlighted");
        this.toggle(commentElement, 'highlighted', 'remove');
    },

    toggle: function (commentElement, cssClass, action) {
        var lineData = commentElement.attr("gts:lines").split(/[^\d\-]/);
        var rows = commentElement.parents("table").find("tr.changes:not(.hunk-sep,.unmod)");
        var startRow = rows.filter("[data-line-num-tuple=" + lineData[0] + "]");
        var sliceStart = rows.indexOf(startRow[0]);
        var sliceEnd = sliceStart + parseInt(lineData[2], 10) + 1;
        rows.slice(sliceStart, sliceEnd)[action + "Class"]("highlighted");
    }
};

Gitorious.DiffBrowser.KeyNavigationController = function () {
    this._lastElement = null;
    this._initialized = false;
    this._enabled = false;

    this._callback = function (event) {
        if (!this._enabled)
            return;

        if (event.keyCode === 74) { // j
            this.scrollToNext();
        } else if (event.keyCode === 75) { // k
            this.scrollToPrevious();
        } else if (event.keyCode === 88) { // x
            this.expandCommentsAtCurrentIndex();
        }
    };

    this.expandCommentsAtCurrentIndex = function () {
        if (!this._lastElement) {
            return;
        }

        var comments = $(this._lastElement).find("table tr td .diff-comments");

        if (comments.is(":hidden")) {
            comments.show();
        } else {
            comments.hide();
        }
    };

    this.scrollToNext = function () {
        var elements = $("#merge_request_diff .file-diff");

        if (!this._lastElement) {
            this._lastElement = elements[0];
            this.scrollToElement(elements[0]);

            return;
        }

        var idx =  elements.indexOf(this._lastElement);
        idx++;

        if (elements[idx]) {
            this.scrollToElement(elements[idx]);
        } else {
            this.scrollToElement(elements[elements.length - 1]);
        }
    };

    this.scrollToPrevious = function () {
        var elements = $("#merge_request_diff .file-diff");
        if (this._lastElement === elements[0]) {
            return;
        }

        var idx =  elements.indexOf(this._lastElement);
        idx--;

        if (idx >= 0 && elements[idx]) {
            this.scrollToElement(elements[idx]);
        }
    };

    this.scrollToElement = function (el) {
        var element = $(el);
        element.find(".header").removeClass("closed").addClass("open");
        element.find(".diff-hunks:hidden").slideDown();
        $.scrollTo(element, { axis: "y", offset: -10 });
        this._lastElement = element[0];
    };

    this.initialize = function () {
        if (this._initialized)
            return;

        $(":input").focus(this.disable.bind(this));
        $(":input").blur(this.enable.bind(this));

        $(window).bind("keydown", this._callback.bind(this));

        this._initialized = true;
    }

    this.enable = function () {
        this._enabled = true;
    };

    this.disable = function () {
        this._enabled = false;
    };
};

Gitorious.DiffBrowser.KeyNavigation = new Gitorious.DiffBrowser.KeyNavigationController();
gitorious.app.observe("DiffBrowserDidReloadDiffs",
                               Gitorious.DiffBrowser.KeyNavigation.enable.bind(Gitorious.DiffBrowser.KeyNavigation));
gitorious.app.observe("DiffBrowserWillPresentCommentForm",
                               Gitorious.DiffBrowser.KeyNavigation.disable.bind(Gitorious.DiffBrowser.KeyNavigation));

Gitorious.MergeRequestController = function () {
    this._currentShaRange = null; // The sha range currently displayed
    this._currentVersion = null; // The version currently displayed
    this._requestedShaRange = null; // The requested sha range
    this._requestedVersion = null; // The requested version

    this._setCurrentShaRange = function (shas) {
        this._currentShaRange = shas;
    };

    this._setCurrentVersion = function (version) {
        this._currentVersion = version;
    };

    this.shaSelected = function (sha) {
        this._requestedShaRange = sha;
    };

    this.versionSelected = function (version) {
        this._requestedVersion = version;
    };

    this._setTransport = function (transport) {
        this._transport = transport;
    };

    // The correct diff url given the current version and sha selection
    this.getDiffUrl = function () {
        if (this._requestedVersion) {
            return $("li[data-mr-version-number=" + this._requestedVersion + "]").
                attr("data-mr-version-url") + "?commit_shas=" + this.getCurrentShaRange();
        } else {
            return $("#merge_request_commit_selector").
                attr("data-merge-request-version-url");
        }
    };

    //Callback when new diffs are received from the server
    this.diffsReceived = function (data, message) {
        this._setCurrentVersion(this._requestedVersion);
        this._setCurrentShaRange(this._requestedShaRange);
    };

    this.getTransport = function () {
        return this._transport || $;
    };

    this.update = function (o) {
        if (o.version) {
            this.versionSelected(o.version);
        }

        if (o.sha) {
            this.shaSelected(o.sha);
        }

        if (this.needsUpdate()) {
            $("#merge_request_diff").html(Gitorious.MergeRequestDiffSpinner);
            this.replaceDiffContents(this._requestedShaRange);
        }
    };

    // Loads diffs for the given sha range. +callback+ is a an function
    // that will be called on +caller+ when changed successfully
    this.replaceDiffContents = function (shaRange, callback, caller) {
        var options = {};

        if (shaRange)  {
            this.shaSelected(shaRange);
            options.data = { "commit_shas": shaRange };
        }

        options.url = this.getDiffUrl();
        var self = this;

        options.success = function (data, text) {
            self.diffsReceivedSuccessfully(data, text, callback, caller);
        };

        options.error = function (xhr, statusText, errorThrown) {
            self.diffsReceivedWithError(xhr, statusText, errorThrown);
        };

        this.getTransport().ajax(options);
    };

    this.diffsReceivedSuccessfully = function (data, responseText, callback, caller) {
        this._currentShaRange = this._requestedShaRange;
        this._currentVersion = this._requestedVersion;
        $("#merge_request_diff").html(data);
        var spec = new Gitorious.ShaSpec();
        spec.parseShas(this._currentShaRange);
        spec.summarizeHtml();

        gitorious.app.notify("DiffBrowserDidReloadDiffs", this);

        if (callback) {
            callback.apply(caller);
        }
    };

    this.diffsReceivedWithError = function (xhr, statusText, errorThrown) {
        $("#merge_request_diff").html(
            '<div class="merge_request_diff_loading_indicator">' +
                "An error has occured. Please try again later.</div>"
        );
    };

    this.needsUpdate = function () {
        return (this._currentShaRange != this._requestedShaRange) ||
               (this._currentVersion != this._requestedVersion);
    };

    this.willSelectShas = function () {
        $("#current_shas .label").html("Selecting");
    };

    this.didReceiveVersion = function (spec) {
        spec.setVersion(this.determineCurrentVersion());
        document.location.hash = spec.shaSpecWithVersion();
    };

    this.determineCurrentVersion = function () {
        return $("#merge_request_version").text().replace(/[^0-9]+/g, "");
    };

    this.isSelectingShas = function (spec) {
        spec.setVersion(this.determineCurrentVersion());
        document.location.hash = spec.shaSpecWithVersion();
        spec.summarizeHtml();
    };

    this.findCurrentlySelectedShas = function (spec) {
        var allShas = $("li.single_commit a").map(function () {
            return $(this).attr("data-commit-sha");
        });

        var currentShas = [];

        for (var i = allShas.indexOf(spec.firstSha().sha());
             i <= allShas.indexOf(spec.lastSha().sha());
             i++) {
            currentShas.push(allShas[i]);
        }

        return currentShas;
    };

    // De-selects any selected sha links, replace with
    // commits included in +spec+ (ShaSpec object or String)
    this.simulateShaSelection = function (shaSpec) {
        $("li.ui-selected").removeClass("ui-selected");
        var currentShas = this.findCurrentlySelectedShas(shaSpec);

        $.each(currentShas, function (ind, sha) {
            $("[data-commit-sha='" + sha + "']").parent().addClass("ui-selected");
        });

    };

    // Loads the requested (from path part of uri) shas and version
    this.loadFromBookmark = function (spec) {
        this.simulateShaSelection(spec);
    };

    this.didSelectShas = function (spec) {
        $("#current_shas .label").html("Showing");

        // In case a range has been selected, also display what's in between as selected
        var currentShas = this.findCurrentlySelectedShas(spec);

        $.each(currentShas, function (idx, sha) {
            var l = $("[data-commit-sha='" + sha + "']").parent();

            if (!l.hasClass("ui-selected")) {
                l.addClass("ui-selected");
            }
        });

        var attr = "data-merge-request-version-url";
        var mr_diff_url = $("#merge_request_commit_selector").attr(attr);
        var diff_browser = new Gitorious.DiffBrowser(spec.shaSpec());
    };

    // Another version was selected, update sha listing if necessary
    this.versionChanged = function (v) {
        this.versionSelected(v);

        if (this.needsUpdate()) {
            var url = $("#merge_request_version").attr("gts:url") +
                      "?version=" + v;

            this.getTransport().ajax({
                url: url,

                success: function (data, text) {
                    gitorious.app.notify("MergeRequestShaListingReceived",
                                     true, data, text, v);
                },

                error: function (xhr, statusText, errorThrown) {
                    gitorious.app.notify("MergeRequestShaListingReceived", false);
                }
            });
        } else {
            gitorious.app.notify("MergeRequestShaListingUpdated", "Same version");
        }
    };

    // User has selected another version to be displayed
    this.loadVersion = function (v) {
        var self = this;
        this._requestedVersion = v;
        var url = $("#merge_request_version").attr("gts:url") +
                  "?version=" + v;

        this.getTransport().ajax({
            url: url,

            success: function (data, text) {
                self.shaListingReceived(true, data, text, v, function () {
                    this.replaceDiffContents();
                }, self);
            },

            error: function (xhr, statusText, errorThrown) {
                if (typeof console != "undefined" && console.error) {
                    console.error("Got an error selecting a different version");
                }
            }
        });
    };

    this.shaListingReceived = function (successful, data, text, version, callback, caller) {
        if (successful) {
            $("#merge_request_version").html("Version " + version);
            this.replaceShaListing(data);
            gitorious.app.notify("MergeRequestShaListingUpdated", "new");
            if (callback && caller) {
                callback.apply(caller);
            }
        } else {
            //            console.error("Got an error when fetching shas");
        }
    };

    this.getCurrentShaRange = function () {
        return $("#current_shas").attr("data-merge-request-current-shas");
    };

    this.isDisplayingShaRange = function (r) {
        return this.getCurrentShaRange() == r;
    };

    this.replaceShaListing = function (markup) {
        $("#diff_browser_for_current_version").html(markup);
        Gitorious.currentMRCompactSelectable.selectable("destroy");
        Gitorious.currentMRCompactSelectable = diffBrowserCompactCommitSelectable();
    };
};

Gitorious.MergeRequestController.getInstance = function () {
    if (Gitorious.MergeRequestController._instance) {
        return Gitorious.MergeRequestController._instance;
    } else {
        var result = new Gitorious.MergeRequestController();
        gitorious.app.observe("MergeRequestDiffReceived",
                                       result.diffsReceived.bind(result));
        gitorious.app.observe("MergeRequestShaListingReceived",
                                       result.shaListingReceived.bind(result));
        Gitorious.MergeRequestController._instance = result;
        return result;
    }
};

// To preserve memory and avoid errors, we remove the selectables
Gitorious.disableCommenting = function () {
    $("table.codediff").selectable("destroy");
};

// Makes line numbers selectable for commenting
Gitorious.enableCommenting = function () {
    this.MAX_COMMENTABLES = 1500;

    // Don't add if we're dealing with a large diff
    if ($("table.codediff td.commentable").length > this.MAX_COMMENTABLES) {
        $("table.codediff td.commentable").removeClass("commentable");
        return false;
    }

    $("table.codediff").selectable({
        filter: "td.commentable, td.line-num-cut",

        start: function (e, ui) {
            Gitorious.CommentForm.destroyAll();
        },

        cancel: ".inline_comments, td.code, td.line-num-cut",

        stop: function (e, ui) {
            var diffTable = e.target;
            var allLineNumbers = [];

            $(diffTable).find("td.ui-selected").each(function () {
                if ($(this).hasClass("line-num-cut")) {
                    return false; // break on hunk seperators
                }

                $(this).parent().addClass("selected-for-commenting");
                allLineNumbers.push($(this).parents("tr").attr("data-line-num-tuple"));
            });

            var path = $(diffTable).parent().prev(".header").children(".title").text();
            var commentForm = new Gitorious.CommentForm(path);
            commentForm.setLineNumbers(allLineNumbers.unique());

            if (commentForm.hasLines()) {
                commentForm.display($(this).parents(".file-diff"));
            }
        }
    });

    // Comment highlighting of associated lines
    $("table tr td.code .diff-comment").each(function () {
        var lines = $(this).attr("gts:lines").split(",");
        var commentBody = $(this).find(".body").text();

        var replyCallback = function () {
            Gitorious.CommentForm.destroyAll();
            var lines = $(this).parents("div.diff-comment").attr("gts:lines").split(",");
            var path = $(this).parents("table").parent().prev(".header"
                                                             ).children(".title").text();
            var commentForm = new Gitorious.CommentForm(path);
            commentForm.setLineNumbers(lines);
            commentForm.setInitialCommentBody(commentBody);

            if (commentForm.hasLines()) {
                commentForm.display($(this).parents(".file-diff"));
            }

            return false;
        };

        $(this).hover(function () {
            Gitorious.DiffBrowser.CommentHighlighter.add($(this));
            $(this).find(".reply").show().click(replyCallback);
        }, function () {
            Gitorious.DiffBrowser.CommentHighlighter.remove($(this));
            $(this).find(".reply").hide().unbind("click", replyCallback);
        });
    });
};

gitorious.app.observe("DiffBrowserDidReloadDiffs",
                               Gitorious.enableCommenting.bind(Gitorious));
gitorious.app.observe("DiffBrowserWillReloadDiffs",
                               Gitorious.disableCommenting.bind(Gitorious));

Gitorious.CommentForm = function (path) {
    this.path = path;
    this.numbers = [];
    this.initialCommentBody = null;
    this.container = $("#inline_comment_form");

    this.setLineNumbers = function (n) {
        var result = [];

        n.each(function (i, number) {
            if (number != "") {
                result.push(number);
            }
        });

        this.numbers = result;
    };

    this.setInitialCommentBody = function (body) {
        var text = $.trim(body);

        this.initialCommentBody = $.map(text.split(/\r?\n/), function (str) {
            return "> " + str;
        }).join("\n") + "\n\n";

        return this.initialCommentBody;
    };

    // returns the lines as our internal representation
    // The fomat is
    // $first_line-number-tuple:$last-line-number-tuple+$extra-lines
    // where $first-line-number-tuple is the first element in the
    // data-line-num-tuple from the <tr> off the selected row and
    // $last-line-number-tuple being the last. $extra-lines is the
    // number of rows the selection span (without the initial row)
    this.linesAsInternalFormat = function () {
        var first = this.numbers[0];
        var last = this.numbers[this.numbers.length - 1];
        var span = this.numbers.length - 1;
        return first + ':' + last + '+' + span;
    };

    this.lastLineNumber = function () {
        return this.numbers[this.numbers.length - 1];
    };

    this.hasLines = function () {
        return this.numbers.length > 0;
    };

    this.getSummary = function () {
        return "Commenting on " + this.path;
    };

    this.reset = function () {
        this.container.find(".progress").hide();
        this.container.find(":input").show();
        this.container.find("#comment_body").val("");
    };

    this.updateData = function () {
        this.container.find("#description").text(this.getSummary());
        var shas = $("#current_shas").attr("data-merge-request-current-shas");
        this.container.find("#comment_sha1").val(shas);
        this.container.find("#comment_path").val(this.path);
        this.container.find("#comment_context").val(this._getRawDiffContext());
        this.container.find(".cancel").click(Gitorious.CommentForm.destroyAll);
        this.container.find("#comment_lines").val(this.linesAsInternalFormat());
    };

    this.display = function (diffContainer) {
        this.reset();
        gitorious.app.notify("DiffBrowserWillPresentCommentForm", this);
        this.updateData();
        this.container.fadeIn();

        if (this.initialCommentBody && this.container.find("#comment_body").val() == "") {
            this.container.find("#comment_body").val(this.initialCommentBody);
        }

        this.container.find("#comment_body").focus();

        var zeForm = this.container.find("form");
        var lastLine = this.lastLineNumber();

        zeForm.submit(function () {
            zeForm.find(".progress").show("fast");
            zeForm.find(":input").hide("fast");

            $.ajax({
                url: $(this).attr("action"),
                data: $(this).serialize(),
                type: "POST",
                dataType: "json",
                success: function (data, text) {
                    gitorious.app.notify("DiffBrowserWillReloadDiffs", this);
                    diffContainer.replaceWith(data["file-diff"]);
                    $(".commentable.comments").append(data.comment);
                    gitorious.app.notify("DiffBrowserDidReloadDiffs", this);
                    $("#diff-inline-comments-for-" + lastLine).slideDown();
                    Gitorious.CommentForm.destroyAll();
                },

                error: function (xhr, statusText, errorThrown) {
                    var errorDisplay = $(zeForm).find(".error");
                    zeForm.find(".progress").hide("fast");
                    zeForm.find(":input").show("fast");
                    errorDisplay.text("Please make sure your comment is valid");
                    errorDisplay.show("fast");
                }
            });

            return false;
        });

        this.container.keydown(function (e) {
            if (e.which == 27) { // Escape
                Gitorious.CommentForm.destroyAll();
            }
        });
    };

    this._getRawDiffContext = function () {
        // Extract the affected diffs (as raw quoted diffs) and return them
        var idiffRegexp = /(<span class="idiff">|<\/span>)/gmi;
        var comments = $("#merge_request_comments .comment.inline .inline_comment_link a");
        var plainDiff = [];

        var selectors = $.map(this.numbers, function (e) {
            return "table.codediff.inline tr[data-line-num-tuple=" + e + "]";
        });

        // extract the raw diff data from each row
        $(selectors.join(",")).each(function () {
            var cell = $(this).find("td.code");
            var op = (cell.hasClass("ins") ? "+ " : "- ");
            plainDiff.push(op + cell.find(".diff-content").html().replace(idiffRegexp, ''));
        });

        return (plainDiff.length > 0 ? plainDiff.join("\n") : "");
    };
};

Gitorious.CommentForm.destroyAll = function () {
    $("#inline_comment_form").fadeOut("fast").unbind("keydown");
    $("#inline_comment_form").find(".cancel_button").unbind("click");
    $("#inline_comment_form form").unbind("submit");
    $(".selected-for-commenting").removeClass("selected-for-commenting");
    $(".ui-selected").removeClass("ui-selected");
    Gitorious.DiffBrowser.KeyNavigation.enable();
};
