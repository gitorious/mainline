/*
  #--
  #   Copyright (C) 2007-2009 Johan Sørensen <johan@johansorensen.com>
  #   Copyright (C) 2009 Marius Mathiesen <marius.mathiesen@gmail.com>
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

if (!Gitorious)
    var Gitorious = {};

Gitorious.Sha = function(sha) {
    this.fullSha = sha;

    this.shortSha = function() {
        return this.fullSha.substring(0, 7);
    };

    this.sha = function() {
        return this.fullSha;
    }
}

Gitorious.ShaSpec = function() {
    this.allShas = [];
    
    this.addSha = function(s) {
        this.allShas.push(new Gitorious.Sha(s));
    }

    // Add shas from a string, eg ff0-bba
    this.parseShas = function(shaString) {
        pair = shaString.split("-");
        this.addSha(pair[0]);
        if (pair.length > 1)
            this.addSha(pair[1]);
    }
    
    this.firstSha = function() {
        return this.allShas[0];
    }
    
    this.lastSha = function() {
        return this.allShas[this.allShas.length - 1];
    }
    
    this.shaSpecs = function(callback) {
        if (this.allShas.length < 2) {
            return [this.firstSha()];
        } else {
            return [this.firstSha(), this.lastSha()];
        }
    }
    
    this.shaSpec = function() {
        var _specs = this.shaSpecs();
        return jQuery.map(_specs, function(s){return s.sha()}).join("-");
    }

    this.shaSpecWithVersion = function() {
        var result = this.shaSpec();
        if (this.hasVersion()) {
            result = result + "@" + this.getVersion();
        }
        return result;
    }

    this.shortShaSpec = function() {
        var _specs = this.shaSpecs();
        return jQuery.map(_specs, function(s){ return s.shortSha() }).join("-");
    }

    this.singleCommit = function() {
        return this.firstSha().sha() == this.lastSha().sha();
    }
    
    this.setVersion = function(v)  {
        this._version = v;
    }

    this.getVersion = function() {
        return this._version;
    }
    
    this.hasVersion = function() {
        return typeof(this._version) != "undefined";
    }

    this.summarizeHtml = function() {
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
    }

};

Gitorious.ShaSpec.parseLocationHash = function(hash) {
    if (hash == "" || typeof(hash) == "undefined") {
        return null;
    }
    var result = new Gitorious.ShaSpec();
    var _hash = hash.replace(/#/, "");
    specAndVersion = _hash.split("@");
    result.parseShas(specAndVersion[0]);
    result.setVersion(specAndVersion[1]);
    return result;
}

// Return an instance from a String
Gitorious.ShaSpec.parseShas = function(shaString) {
    result = new Gitorious.ShaSpec();
    result.parseShas(shaString);
    return result;
}

Gitorious.setDiffBrowserHunkStateFromCookie = function() {
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
}
NotificationCenter.addObserver("DiffBrowserDidReloadDiffs", Gitorious,
                               Gitorious.setDiffBrowserHunkStateFromCookie);


Gitorious.DiffBrowser = function(shas)
{
    NotificationCenter.notifyObservers("DiffBrowserWillReloadDiffs", this);
    jQuery("#merge_request_diff").html(Gitorious.MergeRequestDiffSpinner);
    var c = Gitorious.MergeRequestController.getInstance();
    var version = c.determineCurrentVersion();
    c.update({version:version, sha: shas});
}

Gitorious.DiffBrowser.CommentHighlighter = {
    _lastHighlightedComment: null,

    removePrevious: function() {
        var self = Gitorious.DiffBrowser.CommentHighlighter
        if (!self._lastHighlightedComment)
            return;
        self.remove(self._lastHighlightedComment);
    },

    add: function(commentElement) {
        Gitorious.DiffBrowser.CommentHighlighter.removePrevious();
        commentElement.addClass("highlighted");
        $.each(commentElement.attr("gts:lines").split(","), function() {
            commentElement.parents("table").find("tr.line-" + this).addClass("highlighted");
        });
        Gitorious.DiffBrowser.CommentHighlighter._lastHighlightedComment = commentElement;
    },

    remove: function(commentElement) {
        commentElement.removeClass("highlighted");
        $.each(commentElement.attr("gts:lines").split(","), function() {
            commentElement.parents("table").find("tr.line-" + this).removeClass("highlighted");
        });
    }
};

Gitorious.DiffBrowser.KeyNavigationController = function() {
    this._lastElement = null;

    this._callback = function(event) {
        if (event.keyCode === 74) { // j
            event.data.controller.scrollToNext();
        } else if (event.keyCode === 75) { // k
            event.data.controller.scrollToPrevious();
        } else if (event.keyCode === 88) { // x
            event.data.controller.expandCommentsAtCurrentIndex();
        }
    };

    this.expandCommentsAtCurrentIndex = function() {
        if (!this._lastElement)
            return;

        var comments = $(this._lastElement).find("table tr td .diff-comments");
        if (comments.is(":hidden")) {
            comments.show();
        } else {
            comments.hide();
        }
    };

    this.scrollToNext = function() {
        var elements = $("#merge_request_diff .file-diff");
        if (!this._lastElement) {
            this._lastElement = elements[0];
            this.scrollToElement(elements[0])
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

    this.scrollToPrevious = function() {
        var elements = $("#merge_request_diff .file-diff");
        if (this._lastElement === elements[0]) {
            return;
        }

        var idx =  elements.indexOf(this._lastElement);
        idx--;
        if (idx >= 0 && elements[idx])
            this.scrollToElement(elements[idx]);
    };

    this.scrollToElement = function(element) {
        var element = $(element);
        element.find(".header").removeClass("closed").addClass("open");
        element.find(".diff-hunks:hidden").slideDown();
        $.scrollTo(element, { axis:'y', offset:-10 });
        this._lastElement = element[0];
    };

    this.enable = function() {
        this.disable()
        $(window).bind("keydown", {controller:this}, this._callback);
        // unbind whenever we're in an input field
        var self = this;
        $(":input").focus(function() {
            self.disable();
        });
        $(":input").blur(function() {
            $(window).bind("keydown", {controller:this}, this._callback);
        });
    };

    this.disable = function() {
        $(window).unbind("keydown", this._callback);
    };
};

Gitorious.DiffBrowser.KeyNavigation = new Gitorious.DiffBrowser.KeyNavigationController();
NotificationCenter.addObserver("DiffBrowserDidReloadDiffs",
                               Gitorious.DiffBrowser.KeyNavigation,
                               Gitorious.DiffBrowser.KeyNavigation.enable);
NotificationCenter.addObserver("DiffBrowserWillPresentCommentForm",
                               Gitorious.DiffBrowser.KeyNavigation,
                               Gitorious.DiffBrowser.KeyNavigation.disable);



Gitorious.MergeRequestController = function() {
    this._currentShaRange = null; // The sha range currently displayed
    this._currentVersion = null; // The version currently displayed
    this._requestedShaRange = null; // The requested sha range
    this._requestedVersion = null; // The requested version


    this._setCurrentShaRange = function(shas) {
        this._currentShaRange = shas;
    }

    this._setCurrentVersion = function(version) {
        this._currentVersion = version;
    }

    this.shaSelected = function(sha) {
        this._requestedShaRange = sha;
    }

    this.versionSelected = function(version) {
        this._requestedVersion = version;
    }

    this._setTransport = function(transport) {
        this._transport = transport;
    }
    // The correct diff url given the current version and sha selection
    this.getDiffUrl = function() {
        if (this._requestedVersion) {
            return jQuery("li[data-mr-version-number=" + this._requestedVersion + "]").
                attr("data-mr-version-url");
        } else {
            return jQuery("#merge_request_commit_selector").
                attr("data-merge-request-version-url");
        }
    }

    //Callback when new diffs are received from the server
    this.diffsReceived = function(data, message) {
        this._setCurrentVersion(this._requestedVersion);
        this._setCurrentShaRange(this._requestedShaRange);
    }


    this.getTransport = function() {
        return this._transport || jQuery;
    }
    
    this.update = function(o) {
        if (o.version)
            this.versionSelected(o.version);

        if (o.sha)
            this.shaSelected(o.sha);

        if (this.needsUpdate()) {
            this.replaceDiffContents(this._requestedShaRange);
        }
    }

    // Loads diffs for the given sha range. +callback+ is a an function
    // that will be called on +caller+ when changed successfully
    this.replaceDiffContents = function(shaRange, callback, caller) {
        var options = {};
        if (shaRange)  {
            this.shaSelected(shaRange);
            options["data"] = {"commit_shas": shaRange};
        } 

        options["url"] = this.getDiffUrl();
        var self = this;
        options["success"] = function(data, text) {
            self.diffsReceivedSuccessfully(data,text, callback, caller)
        };
        options["error"] = function(xhr, statusText, errorThrown) {
            self.diffsReceivedWithError(xhr, statusText, errorThrown)
        };
        this.getTransport().ajax(options);
    }

    this.diffsReceivedSuccessfully = function(data, responseText, callback, caller) {
        this._currentShaRange = this._requestedShaRange;
        this._currentVersion = this._requestedVersion;
        jQuery("#merge_request_diff").html(data);
        var spec = new Gitorious.ShaSpec();
        spec.parseShas(this._currentShaRange);
        spec.summarizeHtml();

        NotificationCenter.notifyObservers("DiffBrowserDidReloadDiffs", this);
        if (callback) {
            callback.apply(caller);
        }
    }
    this.diffsReceivedWithError = function(xhr, statusText, errorThrown) {
        jQuery("#merge_request_diff").html(
            '<div class="merge_request_diff_loading_indicator">' +
                "An error has occured. Please try again later.</div>"
        );
    }
    
    this.needsUpdate = function() {
        return (this._currentShaRange != this._requestedShaRange)
            || (this._currentVersion != this._requestedVersion);
    }

    this.willSelectShas = function() {
        $("#current_shas .label").html("Selecting");
    }
    
    this.didReceiveVersion = function(spec) {
        spec.setVersion(this.determineCurrentVersion());
        document.location.hash = spec.shaSpecWithVersion();
    }

    this.determineCurrentVersion = function() {
        return $("#merge_request_version").text().replace(/[^0-9]+/g,'');
    }

    this.isSelectingShas = function(spec) {
        spec.setVersion(this.determineCurrentVersion());
        document.location.hash = spec.shaSpecWithVersion();
        spec.summarizeHtml();
    }

    this.findCurrentlySelectedShas = function(spec) {
        var allShas = jQuery("li.single_commit a").map(function(){
            return $(this).attr("data-commit-sha");
        })
        var currentShas = [];
        for (var i = allShas.indexOf(spec.firstSha().sha());
             i <= allShas.indexOf(spec.lastSha().sha()); 
             i++) {
            currentShas.push(allShas[i]);
        }
        return currentShas;
    }

    // De-selects any selected sha links, replace with
    // commits included in +spec+ (ShaSpec object or String)
    this.simulateShaSelection = function(shaSpec) {
        jQuery("li.ui-selected").removeClass("ui-selected");
        var currentShas = this.findCurrentlySelectedShas(shaSpec);
        jQuery.each(currentShas, function(ind, sha){
            jQuery("[data-commit-sha='" + sha + "']").parent().addClass("ui-selected");
        })        
    }
    
    // Loads the requested (from path part of uri) shas and version
    this.loadFromBookmark = function(spec) {
        this.simulateShaSelection(spec);
    }
    
    this.didSelectShas = function(spec) {
        $("#current_shas .label").html("Showing");
        
        // In case a range has been selected, also display what's in between as selected
        var currentShas = this.findCurrentlySelectedShas(spec);
        jQuery.each(currentShas, function(idx,sha){
            var l = jQuery("[data-commit-sha='" + sha + "']").parent();
            if (!l.hasClass("ui-selected")) {
                l.addClass("ui-selected");
            }
        });

        var mr_diff_url = jQuery("#merge_request_commit_selector")
            .attr("data-merge-request-version-url");
        var diff_browser = new Gitorious.DiffBrowser(spec.shaSpec());    
    }
    // Another version was selected, update sha listing if necessary    
    this.versionChanged = function(v) {
        this.versionSelected(v);
        if (this.needsUpdate()) { 
            var url = jQuery("#merge_request_version").attr("gts:url") +
                "?version=" + v;
            this.getTransport().ajax({
                url: url,
                success: function(data,text){
                    NotificationCenter.notifyObservers("MergeRequestShaListingReceived", 
                                                       true, data,text, v);
                },
                error: function(xhr,statusText,errorThrown){
                    NotificationCenter.notifyObservers("MergeRequestShaListingReceived", 
                                                       false);
                }
            });
        } else {
            NotificationCenter.notifyObservers("MergeRequestShaListingUpdated", 
                                               "Same version");
        }
    }

    // User has selected another version to be displayed
    this.loadVersion = function(v) {
        var self = this;
        var url = jQuery("#merge_request_version").attr("gts:url") +
            "?version=" + v;
        this.getTransport().ajax({
            url: url,
            success: function(data,text) {
                self.shaListingReceived(true, data, text, v, function() {
                    this.replaceDiffContents()
                }, self);
            },
            error: function(xhr,statusText,errorThrown) {
                console.error("Got an error selecting a different version");
            }});
    }


    this.shaListingReceived = function(successful, data, text, version, callback, caller) {
        if (successful) {
            jQuery("#merge_request_version").html("Version " + version);
            jQuery("#diff_browser_for_current_version").html(data);
            NotificationCenter.notifyObservers("MergeRequestShaListingUpdated", 
                                               "new");
            if (callback && caller) {
                callback.apply(caller);
            }
        } else {
//            console.error("Got an error when fetching shas");
        }
    }
    
    this.getCurrentShaRange = function() {
        return jQuery("#current_shas").attr("data-merge-request-current-shas");
    }

    this.isDisplayingShaRange = function(r) {
        return this.getCurrentShaRange() == r;
    }

    this.replaceShaListing = function(markup) {
        jQuery("#diff_browser_for_current_version").html(markup);
        new Gitorious.DiffBrowser(this.getCurrentShaRange());
        Gitorious.currentMRCompactSelectable.selectable("destroy");
        Gitorious.currentMRCompactSelectable = diffBrowserCompactCommitSelectable();
    }
}

Gitorious.MergeRequestController.getInstance = function() {
    if (Gitorious.MergeRequestController._instance) {
        return Gitorious.MergeRequestController._instance;
    } else {
        var result = new Gitorious.MergeRequestController();
        NotificationCenter.addObserver("MergeRequestDiffReceived", result,
                                       result.diffsReceived);
        NotificationCenter.addObserver("MergeRequestShaListingReceived", 
                                       result, result.shaListingReceived);
        Gitorious.MergeRequestController._instance = result;
        return result;
    }
}

// To preserve memory and avoid errors, we remove the selectables
Gitorious.disableCommenting = function() {
    jQuery("table.codediff").selectable("destroy");
}

// Makes line numbers selectable for commenting
Gitorious.enableCommenting = function() {
    jQuery("table.codediff").selectable({
        filter: "td.commentable",
        start: function(e, ui) {
            Gitorious.CommentForm.destroyAll();
        },
        cancel: ".inline_comments",
        stop: function(e, ui) {
            var diffTable = e.target;
            $(diffTable).find("td.ui-selected").each(function(el){
                $(this).parent().addClass("selected-for-commenting");
            })
                var allLineNumbers = $(diffTable).find("td.ui-selected").map(function(){
                    return $(this).text();
                });
            var path = $(diffTable).parent().prev(".header").children(".title").text();
            var commentForm = new Gitorious.CommentForm(path);
            commentForm.setLineNumbers(allLineNumbers);
            var commentContainer = $(diffTable).prev(".comment_container");
            if (commentForm.hasLines()) {
                commentForm.display({inside: commentContainer});
            }
        }
    });

    // Comment highlighting of associated lines
    $("table tr td.code .diff-comment").each(function() {
        var lines = $(this).attr("gts:lines").split(",");
        var replyCallback = function() {
            Gitorious.CommentForm.destroyAll();
            var lines = $(this).parents("div.diff-comment").attr("gts:lines").split(",")
            var path = $(this).parents("table").parent().prev(".header"
                                                             ).children(".title").text();
            var commentForm = new Gitorious.CommentForm(path);
            commentForm.setLineNumbers(lines);
            if (commentForm.hasLines())
                commentForm.display({
                    inside: $(this).parents("table").prev(".comment_container"),
                    trigger: $(this)
                });
            return false;
        };
        $(this).hover(function() {
            Gitorious.DiffBrowser.CommentHighlighter.add($(this));
            $(this).find(".reply").show().click(replyCallback);
        }, function() {
            Gitorious.DiffBrowser.CommentHighlighter.remove($(this))
            $(this).find(".reply").hide().unbind("click", replyCallback);
        });
    });
};
NotificationCenter.addObserver("DiffBrowserDidReloadDiffs", Gitorious,
                               Gitorious.enableCommenting);
NotificationCenter.addObserver("DiffBrowserWillReloadDiffs", Gitorious,
                               Gitorious.disableCommenting);


Gitorious.DiffBrowser.insertDiffContextsIntoComments = function() {
    // Extract the affected diffs and insert them above the comment it
    // belongs to
    var idiffRegexp = /(<span class="idiff">|<\/span>)/gmi;
    var comments = $("#merge_request_comments .comment.inline .inline_comment_link a");
    for (var i=0; i < comments.length; i++) {
        var commentElement = $( $(comments[i]).attr("href") );
        if (commentElement.length === 0)
            continue;
        var selectors = $.map(commentElement.attr("gts:lines").split(","), function(e) {
            return "table.codediff.inline tr.line-" + e;
        });
        // extract the raw diff data from each row
        var plainDiff = [];
        $(selectors.join(",")).each(function() {
            var cell = $(this).find("td.code");
            var op = "&gt; " + (cell.hasClass("ins") ? "+ " : "- ");
            plainDiff.push(op + cell.find(".diff-content").html().replace(idiffRegexp, ''));
        });
        if ($(comments[i]).parents(".comment.inline").find(".diff-comment-context").length > 0) {
            // We have already added this context, move on
            continue;
        }
        $(comments[i]).parents(".comment.inline")
            .prepend('<pre class="diff-comment-context"><code>' +
                     plainDiff.join("\n") + '</code></pre');
    };
};

NotificationCenter.addObserver("DiffBrowserDidReloadDiffs", Gitorious.DiffBrowser,
                               Gitorious.DiffBrowser.insertDiffContextsIntoComments);

Gitorious.CommentForm = function(path){
    this.path = path;
    this.numbers = [];

    this.setLineNumbers = function(n) {
        var result = [];
        n.each(function(i,number){
            if (number != "") {
                result.push(number);
            }
        });
        this.numbers = result;
    }
    this.linesAsString = function() {
        var sortedLines = this.numbers.sort();
        return sortedLines[0] + ".." + sortedLines[sortedLines.length - 1];
    }
    this.hasLines = function() {
        return this.numbers.length > 0;
    }
    this.getSummary = function() {
        return "Commenting on lines " + this.linesAsString() + " in " + this.path;
    }
    this.display = function(options) {
        NotificationCenter.notifyObservers("DiffBrowserWillPresentCommentForm", this);
        var comment_form = jQuery("#inline_comment_form");
        var commentContainer = options.inside;
        commentContainer.html(comment_form.html());
        commentContainer.find("#description").text(this.getSummary());
        var shas = $("#current_shas").attr("data-merge-request-current-shas");
        commentContainer.find("#comment_sha1").val(shas);
        commentContainer.find("#comment_path").val(this.path);
        commentContainer.find(".cancel_button").click(Gitorious.CommentForm.destroyAll);
        commentContainer.find("#comment_lines").val(this.linesAsString());
        this._positionAndShowContainer(commentContainer, options.trigger);
        commentContainer.find("#comment_body").focus();
        var zeForm = commentContainer.find("form");
        zeForm.submit(function(){
            zeForm.find(".progress").show("fast");
            zeForm.find(":input").hide("fast");
            jQuery.ajax({
                "url": $(this).attr("action"),
                "data": $(this).serialize(),
                "type": "POST",
                "success": function(data, text) {
                    NotificationCenter.notifyObservers("DiffBrowserWillReloadDiffs", this);
                    var diffContainer = zeForm.parents(".file-diff");
                    diffContainer.replaceWith(data);
                    NotificationCenter.notifyObservers("DiffBrowserDidReloadDiffs", this);
                },
                "error": function(xhr, statusText, errorThrown) {
                    var errorDisplay = $(zeForm).find(".error");
                    zeForm.find(".progress").hide("fast");
                    zeForm.find(":input").show("fast");
                    errorDisplay.text("Please make sure your comment is valid");
                    errorDisplay.show("fast");
                }
            });
            return false;
        });

        commentContainer.keydown(function(e){
            if (e.which == 27) { // Escape
                Gitorious.CommentForm.destroyAll();
            }
        })
        
    },

    // Positions the commentContainer, optionally near the trigger
    this._positionAndShowContainer = function(container, trigger) {
        var cssData = {
            left: $(document).width() - container.width() - 75 + "px"
        };
        container.css(cssData);
        container.slideDown();
    }
}

Gitorious.CommentForm.destroyAll = function() {
    $(".comment_container").html("").unbind("keypress").slideUp("fast");
    $(".selected-for-commenting").removeClass("selected-for-commenting");
    $(".ui-selected").removeClass("ui-selected");
    Gitorious.DiffBrowser.KeyNavigation.enable();
}
