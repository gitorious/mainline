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
    if (pair.length > 1) {
      this.addSha(pair[1]);
    } else {
      this.addSha(pair[0]);
    }
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
    if (this.singleCommit()) {
      $("#current_shas .several_shas").hide();
      $("#current_shas .single_sha").show();
      $("#current_shas .single_sha .merge_base").html(this.firstSha().shortSha());
    } else {
      $("#current_shas").attr("data-merge-request-current-shas", this.shaSpec());
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

Gitorious.DiffBrowser = function(shas)
{
  Gitorious.disableCommenting();
  jQuery("#merge_request_diff").html(Gitorious.MergeRequestDiffSpinner);
  var mr_diff_url = jQuery("#merge_request_commit_selector")
    .attr("data-merge-request-version-url");
  jQuery.ajax({
    "url": mr_diff_url,
    "data": {"commit_shas": shas},
    "success": function(data, responseText) {
      if (responseText === "success") {
        jQuery("#merge_request_diff").html(data);
        var commentMarkup = jQuery("#__temp_comments").html();
        jQuery("#__temp_comments").html("");
        jQuery("#merge_request_comments").html(commentMarkup);
        var shaSpec = new Gitorious.ShaSpec();
        shaSpec.parseShas(shas);
        Gitorious.MergeRequestController.getInstance().didReceiveVersion(shaSpec);
        Gitorious.setDiffBrowserHunkStateFromCookie();
        Gitorious.enableCommenting();
        Gitorious.DiffBrowser.KeyNavigation.enable();
        Gitorious.DiffBrowser.insertDiffContextsIntoComments();
      }
    },
    "error": function(xhr, statusText, errorThrown) {
      jQuery("#merge_request_diff").html("<div class=\"merge_request_diff_loading_indicator\">" + 
                                         "An error has occured. Please try again later.</div>");
    }
  });
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

Gitorious.DiffBrowser.KeyNavigation = {
   _currentIndex: 0,

   _callback: function(event) {
    var scrollToCommentAtCurrentIndex = function(commentElement) {
      var elements = $("table tr td .diff-comments .diff-comment");
      if (Gitorious.DiffBrowser.KeyNavigation._currentIndex >= elements.length ||
          Gitorious.DiffBrowser.KeyNavigation._currentIndex <= 0)
        {
          Gitorious.DiffBrowser.KeyNavigation._currentIndex = 0;
        }
      var element = $(elements[Gitorious.DiffBrowser.KeyNavigation._currentIndex]);
      element.parents(".diff-comments:hidden").slideDown();
      $.scrollTo(element, { axis:'y', offset:-150 });
      Gitorious.DiffBrowser.CommentHighlighter.add(element);
    };

    if (event.keyCode === 74) { // j
      scrollToCommentAtCurrentIndex();
      Gitorious.DiffBrowser.KeyNavigation._currentIndex++;
    } else if (event.keyCode === 75) { // k
      Gitorious.DiffBrowser.KeyNavigation._currentIndex--;
      scrollToCommentAtCurrentIndex();
    }
  },

  enable: function() {
    Gitorious.DiffBrowser.KeyNavigation.disable()
    $(window).keydown(Gitorious.DiffBrowser.KeyNavigation._callback);
    // unbind whenever we're in an input field
    $(":input").focus(function() {
        Gitorious.DiffBrowser.KeyNavigation.disable();
    });
    $(":input").blur(function() {
        $(window).keydown(Gitorious.DiffBrowser.KeyNavigation._callback);
    });
  },

  disable: function() {
      $(window).unbind("keydown", Gitorious.DiffBrowser.KeyNavigation._callback);
  }
};

Gitorious.MergeRequestController = function() {
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

  // Loads the requested (from path part of uri) shas and version
  this.loadFromBookmark = function(spec) {
    jQuery("li.ui-selected").removeClass("ui-selected");
    var currentShas = this.findCurrentlySelectedShas(spec);
    jQuery.each(currentShas, function(ind, sha){
      jQuery("[data-commit-sha='" + sha + "']").parent().addClass("ui-selected");
    })
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
}

Gitorious.MergeRequestController.getInstance = function() {
  if (Gitorious.MergeRequestController._instance) {
    return Gitorious.MergeRequestController._instance;
  } else {
    var result = new Gitorious.MergeRequestController();
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

NotificationCenter.defaultCenter().addObserver("DiffBrowserWillReloadDiffs", Gitorious,
                                               Gitorious.disableCommenting, this);
NotificationCenter.defaultCenter().addObserver("DiffBrowserDidReloadDiffs", Gitorious,
                                               Gitorious.enableCommenting, this);

Gitorious.DiffBrowser.insertDiffContextsIntoComments = function() {
    // Extract the affected diffs and insert them above the comment it
    // belongs to
    $("#merge_request_comments .comment.inline").each(function() {
        var comment = $( $(this).find(".inline_comment_link a").attr("href") );
        if (comment.length === 0)
          return;
        var selectors = $.map(comment.attr("gts:lines").split(","), function(e) {
            return "table.codediff.inline tr.line-" + e;
        });
        // extract the raw diff data from each row
        var plainDiff = "";
        $(selectors.join(",")).each(function() {
            var cell = $(this).find("td.code").clone();
            cell.children("ins, del, div").empty(); // we only want the actual diff data
            var op = "> " + (cell.hasClass("ins") ? "+ " : "- ");
            plainDiff += op + cell.text();
            plainDiff += "\n";
       });
       $(this).prepend('<pre class="diff-comment-context"><code>' +
                       plainDiff + '</code></pre');
    });
};

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
    Gitorious.DiffBrowser.KeyNavigation.disable();
    var comment_form = jQuery("#inline_comment_form");
    var hash = document.location.hash;
    var commentContainer = options.inside;
    commentContainer.html(comment_form.html());
    commentContainer.find("#description").text(this.getSummary());
    var shas = hash.split("@")[0].replace("#","");
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
          NotificationCenter.defaultCenter().notifyObservers("DiffBrowserWillReloadDiffs",
                                                             this);
          var diffContainer = zeForm.parents(".file-diff");
          diffContainer.replaceWith(data);
          NotificationCenter.defaultCenter().notifyObservers("DiffBrowserDidReloadDiffs",
                                                             this);
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
    var data = { left: $(document).width() - container.width() - 75 + "px" };
    if (trigger)
      data.top = trigger.position().top + "px";
    container.css(data);
    container.slideDown();
  }
}

Gitorious.CommentForm.destroyAll = function() {
  $(".comment_container").html("").unbind("keypress").slideUp("fast");
  $(".selected-for-commenting").removeClass("selected-for-commenting");
  $(".ui-selected").removeClass("ui-selected");
  Gitorious.DiffBrowser.KeyNavigation.enable();
}
