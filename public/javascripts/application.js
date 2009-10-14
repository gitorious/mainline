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

jQuery.fn.highlightSelectedLines = function() {
    var currentHighlights = [];
    if (/^#line\d+$/.test(window.location.hash)) {
      currentHighlights = [window.location.hash];
    }

    this.find("tr td.line-numbers a").click(function() {
        var element = $(this).get(0);
        currentHighlights = [element.name];
        highlightCodeLine(currentHighlights);
    });

    var jthis = this;
    var highlightCodeLine = function(lineId) {
        jQuery.each(currentHighlights, function() {
            $(jthis).find("tr#" + this + " td").removeClass("marked");
        });
        $(jthis).find("tr#" + lineId + " td").addClass("marked");
        currentHighlights = [lineId];
    };

    if (currentHighlights.length === 0) return;
    highlightCodeLine(currentHighlights);
};

jQuery.fn.changableSelection = function(options) {
  var currentContainer = $(this);
  var choices = $(options.container || $(this).next("ul.changable-selection-options"));

  choices.css({
    display:'none',
    cursor:'pointer'
  }).children("li").bind('click', function(e) {
      currentContainer.text( $(this).text() );
      choices.hide();
      if (options.onChange) options.onChange.call(this);
      return false;
  });

  currentContainer.bind('click', function(event) {
      choices.css({
        top: (event.pageY - $(this).height()) + "px",
        // TODO: Check for vicinity to screen edge and adjust left/right accordingly
        left: (event.pageX - $(this).width() - 10) + "px",
				position: "absolute",
				opacity: 1.0,
        zIndex: 1000
      }).fadeIn('fast');
      return false;
  }).css({cursor:'pointer'});

  $(document).click(function(){
      choices.fadeOut('fast');
  });
};

jQuery.fn.hoverBubble = function() {
  $(this).each(function() {
      var originalOffset = $(this).offset();
      var bubbleHeight = $(this).next(".hover-bubble-content").height();
      var triggerWidth = $(this).width();
      $(this).next(".hover-bubble-content").css({
        top: originalOffset.top - bubbleHeight - 25 + 'px',
        left: originalOffset.left - (triggerWidth/2) - 50 + 'px',
        opacity: 0
      });
      $(this).hover(function() {
          $(this).next(".hover-bubble-content").stop()
            .animate({
              top: originalOffset.top - bubbleHeight - 15 + 'px',
              opacity: 0.95
            }, "fast").show();
      }, function(){
          $(this).next(".hover-bubble-content").stop()
            .animate({
              top: originalOffset.top - bubbleHeight - 25 + 'px',
              opacity: 0
            }, "fast");
      });

  });
};

// toggle the elements by sliding either up or down
jQuery.fn.slideToggle = function(speed) {
  $(this).each(function() {
      if ($(this).is(":visible")) {
        $(this).slideUp(speed);
      } else {
        $(this).slideDown(speed);
      }
  });
  return $(this);
};

$(document).ready(function() {
    // Project Sluggorizin'
    $("form #project_title").keyup(function(event) {
        var slug = $("form #project_slug");
        if (slug.text() != "") return;
        var lintName = function(val) {
          var linted = val.replace(/\W+/g, ' ').replace(/\ +/g, '-');
          linted = linted.toLowerCase().replace(/\-+$/g, '');
          return linted;
        }
        
        slug.val( lintName(this.value) );
    });

    // Line highlighting/selection
    $("#codeblob").highlightSelectedLines();

    // no-op links
    $("a.link_noop").click(function(event) {
        event.preventDefault();
    });
    
    // Comment previewing
    $("input#comment_preview_button").click(function(event){
        var formElement = $(this).parents("form");
        var url = formElement.attr("action");
        url += "/preview"
        $.post(url, formElement.serialize(), function(data, responseText){
            if (responseText === "success") {
              $("#comment_preview").html(data);
              $("#comment_preview").fadeIn();
            }
        });
        event.preventDefault();
    });

    // Project previewing
    $("input#project_preview_button").click(function(event){
        var formElement = $(this).parents("form");
        var url = $(this).attr("gts:url");
        $.post(url, formElement.serialize(), function(data, response) {
            if (response === "success")
              $("#project-preview").html(data).fadeIn();
        });
        event.preventDefault();
    });

    // Message actions
    $(".message_actions a.mark_as_unread").click(function(event){
        var link = $(this);
        $.post(link.attr("href"), "_method=put", function(data, response){
            if (response === "success") {
              var parts = link.attr("href").split("/");
              $("#message_" + parts[parts.length-2]).removeClass("unread");
              link.parent().slideUp();
            }              
        });
        event.preventDefault();
    });

    // Message selection toggling
    $("a#toggle_all_messages_checked").click(function(e) {
        $(".select_msg").each(function() {
            this.checked = (this.checked ? '' : 'checked');
        });
        e.preventDefault();
    });
    $("a#toggle_all_unread_messages_checked").click(function(e) {
        $(".select_msg").each(function() { this.checked = ''; });
        $(".unread .select_msg").each(function() {
            this.checked = (this.checked ? '' : 'checked');
        });
        e.preventDefault();
    });

    // Markdown help toggling
    $(".markdown-help-toggler").click(function(event){
        $(".markdown_help").toggle();
        event.preventDefault();
    });

    $("a#advanced-search-toggler").click(function(event) {
        $("#search_help").slideToggle();
        event.preventDefault();
    });

    // Merge request status color picking
    $("#merge_request_statuses input.color_pickable").SevenColorPicker();

    // Toggle details of commit events
    $("a.commit_event_toggler").click(function(event){
        var callbackUrl = $(this).attr("gts:url");
        var eventId = $(this).attr("gts:id");

        $("#commits_in_event_" + eventId).toggle();
        if ($("#commits_in_event_" + eventId).is(":visible")) {
          $("#commits_in_event_" + eventId).load(callbackUrl);
        }
        event.preventDefault();
    });
    
    // frontpage for non-loggedin users
    // Unobtrusively hooking the regular/OpenID login box stuff, so that it works
    // in a semi-sensible way with javascript disabled.
    $("#big_header_login_box_to_openid, #big_header_login_box_to_regular").click(function(e){
        $("#big_header_login_box_openid").toggle("fast");
        $("#big_header_login_box_regular").toggle("fast");
        e.preventDefault();
    });

  $("body#merge_requests", function(){
    var spec = Gitorious.ShaSpec.parseLocationHash(document.location.hash);
    if (spec) {
      Gitorious.MergeRequestController.getInstance().loadFromBookmark(spec);
    }
  })

    // replace the search form input["submit"] with something fancier
    $("#main_menu_search_form").each(function(){
        var headerSearchForm = this;
        var labelText = "Search...";
        var searchInput = $(this).find("input[type=text]");
        searchInput.val(labelText);
        searchInput.click(function(event){
            if (searchInput.val() == labelText) {
              searchInput.val("");
              searchInput.removeClass("unfocused");
            }
        });
        searchInput.blur(function(event){
            if (searchInput.val() == "") {
              searchInput.val(labelText);
              searchInput.addClass("unfocused");
            }
        });
        // hide the 'native' submit button and replace it with our 
        // own awesome submit button
        var nativeSubmitButton = $(this).find("input[type=submit]");
        nativeSubmitButton.hide();
        var awesomeSubmitButton = $(document.createElement("a"));
        awesomeSubmitButton.attr({
            'id':'main_menu_search_form_graphic_submit',
            'href': '#'
        });
        awesomeSubmitButton.click(function(event){
            headerSearchForm.submit();
            event.preventDefault();
        });
        nativeSubmitButton.after(awesomeSubmitButton);
    });

    // toggling of diffs in diff browsers
    $('.file-diff .header').live("click", function(event) {
        var hunksContainer = $(this).next();
        if (hunksContainer.is(":visible")) {
          $(this).removeClass("open").addClass("closed");
          hunksContainer.slideUp();
        } else {
          $(this).removeClass("closed").addClass("open");
          hunksContainer.slideDown();
        }
        event.preventDefault();
    });
    $(".file-diff-controls a#expand-all").live("click", function(e){
        var container = $(this).parent().parent().parent();
        var cookiePrefix = $(this).attr("gts:cookie-prefix") || 'generic';
        container.find('.file-diff .header').removeClass("closed").addClass("open");
        container.find('.diff-hunks:hidden').show();
        $.cookie(cookiePrefix + "-diff-hunks-state", "expanded");
        e.preventDefault();
    });
    $(".file-diff-controls a#collapse-all").live("click", function(e){
        var container = $(this).parent().parent().parent();
        var cookiePrefix = $(this).attr("gts:cookie-prefix") || 'generic';
        container.find('.file-diff .header').removeClass("open").addClass("closed");
        container.find('.diff-hunks').hide();
        $.cookie(cookiePrefix + "-diff-hunks-state", "collapsed");
        e.preventDefault();
    });

    // merge request diffing loading indimacator
    Gitorious.MergeRequestDiffSpinner = $("#merge_request_diff_loading").html();
    $("#merge_request_diff").html(Gitorious.MergeRequestDiffSpinner);

    // Merge request selection of branches, compact mode
    // wrapped in a function so we can reuse it when we load another version
    var diffBrowserCompactCommitSelectable = function() {
      var selectingAndUnselecting = function() {
        var commits = $("li.ui-selecting a");
        if (!commits[0]) return true;
        var first_commit_sha = $(commits[0]).attr("data-commit-sha");
        var last_commit_sha = $(commits[commits.length - 1]).attr("data-commit-sha");
        
        var shaSpec = new Gitorious.ShaSpec();
        shaSpec.addSha(first_commit_sha);
        shaSpec.addSha(last_commit_sha); 

        Gitorious.MergeRequestController.getInstance().isSelectingShas(shaSpec);
      };
      return jQuery("#merge_request_commit_selector.compact").selectable({
        filter: "li.single_commit",
        stop: function(e, ui) {
          var sha_spec = new Gitorious.ShaSpec();
          jQuery("li.ui-selected a", this).each(function() {
            sha = jQuery(this).attr("data-commit-sha");
            sha_spec.addSha(sha);
          });
          Gitorious.MergeRequestController.getInstance().didSelectShas(sha_spec);
        },
        start: function(e, ui) {
          Gitorious.MergeRequestController.getInstance().willSelectShas();
        },
        selecting: function(e, ui) {
          selectingAndUnselecting();
        },
        unselecting: function(e,ui) {
          selectingAndUnselecting();
        },
        cancel: ".merge_base"
      });
    }
    Gitorious.currentMRCompactSelectable = diffBrowserCompactCommitSelectable();

    $("#merge_request_version").changableSelection({
      onChange: function() {
          var version = $(this).text().replace(/[^0-9]+/g, '');
          var url = $(this).parent().prev().attr("gts:url") + '?version=' + version;
          $("#diff_browser_for_current_version").load(url, null, function() {
            new Gitorious.DiffBrowser(
              jQuery("#current_shas").attr("data-merge-request-current-shas") );
            // jump through hoops and beat the selectable into submission,
            // since it doesn't use live events, we have to re-create it, which sucks...
            Gitorious.currentMRCompactSelectable.selectable("destroy");
            Gitorious.currentMRCompactSelectable = diffBrowserCompactCommitSelectable();
          });
      }
    });
    
    $("#merge_request_current_version ul.compact li.single_commit").hoverBubble();
    
    // Merge request selection of branches, monster mode
    $("#large_commit_selector_toggler").live("click", function(event) {
        $("#large_commit_selector").slideToggle();
        event.preventDefault();
    });

    // Handle selection of multiple commits in the large merge-request commit diff browser
    var previousSelectedCommitRowIndex;
    $("#large_commit_selector table#commit_table tr input").live("click", function(event) {
        var selectedTr = $(this).parents("tr");
        var commitRows = selectedTr.parents("table").find("tr.commit_row");

        if (commitRows.filter(".selected").length === 0) {
            // mark initial selection
            selectedTr.addClass("selected");
            return;
        }

        var firstSelRowIndex = commitRows.indexOf(commitRows.filter(".selected:first")[0]);
        var lastSelRowIndex = commitRows.indexOf(commitRows.filter(".selected:last")[0]);
        var selectedRowIndex = commitRows.indexOf(selectedTr[0]);
        var markRange = function(start, end) {
            commitRows.slice(start, end + 1).addClass("selected");
        };

        // reset selections first
        commitRows.filter(".selected").removeClass("selected");
        if (selectedRowIndex === firstSelRowIndex || selectedRowIndex === lastSelRowIndex) {
            selectedTr.addClass("selected");
            return;
        }

        if (selectedRowIndex > firstSelRowIndex &&
            selectedRowIndex < lastSelRowIndex) // in-between
        {
            if (previousSelectedCommitRowIndex === firstSelRowIndex) {
                markRange(selectedRowIndex, lastSelRowIndex);
            } else {
                markRange(firstSelRowIndex, selectedRowIndex);
            }
        } else if (selectedRowIndex > firstSelRowIndex) { // downwards
            markRange(firstSelRowIndex, selectedRowIndex);
        } else { // upwards
            markRange(selectedRowIndex, lastSelRowIndex);
        }

        previousSelectedCommitRowIndex = selectedRowIndex;
    });

    // Display a range of commits from the large merge-request commit diff browser
    $("#show-large-diff-range").live("click", function(event) {
        var selected = $("#large_commit_selector table#commit_table tr.commit_row.selected");
        var spec = new Gitorious.ShaSpec();
        var firstSHA = selected.filter(":first").find("input.merge_to").val();
        var lastSHA = selected.filter(":last").find("input.merge_to").val();
        spec.addSha(firstSHA);
        if (firstSHA != lastSHA)
          spec.addSha(lastSHA);
        spec.summarizeHtml();
        var diff_browser = new Gitorious.DiffBrowser(spec.shaSpec());
        $("#large_commit_selector").hide();
        event.preventDefault();
    });

    // Show a single commit in the large merge-request commit diff browser
    $("#large_commit_selector #commit_table a.clickable_commit").live("click", function(e){
        var spec = new Gitorious.ShaSpec();
        spec.addSha($(this).attr("data-commit-sha"));
        var diff_browser = new Gitorious.DiffBrowser(spec.shaSpec());
        $("#large_commit_selector").hide();
        e.preventDefault();
    });
    
    jQuery("#current_shas").each(function(){
        var sha_spec = jQuery(this).attr("data-merge-request-current-shas");
        diff_browser = new Gitorious.DiffBrowser(sha_spec);
      }
    );

  /*
  jQuery("tr.changes td.line-numbers").live("mousedown", function() {
    var numbers = $(this).text();
    var file_name = $(this).closest("div").prev(".header").children(".title").text();
    var other_line_numbers = $(this).closest("table").find("td.line-numbers");
    var commentForm = new Gitorious.CommentForm(file_name);
    commentForm.addLineNumber(numbers);
    other_line_numbers.mouseenter(function(e){
      commentForm.addLineNumber($(this).text());
      e.preventDefault();
    });
    other_line_numbers.mouseout(function(e){      
      commentForm.removeLineNumber($(this).text());
      e.preventDefault()
    });
    other_line_numbers.mouseup(function(){
      other_line_numbers.unbind("mouseenter");
      other_line_numbers.unbind("mouseout");
      other_line_numbers.unbind("mouseup");
      commentForm.display();
    });
  });
  */
    // Diff commenting
    $("table tr td.inline_comments a.diff-comment-count").live("click", function(e) {
        var lineNum = $(this).parents("td").next("td").text();
        if (lineNum === "") // look in the next TD
          lineNum = $(this).parents("td").next("td").next("td").text();
        $(this).parents("tr.changes")
            .find("td.code .diff-comments.line-" + lineNum).slideToggle();
        e.preventDefault();
    });

  // Clicking on a comment relating to a merge request 
  // version displays the comment in context
  $("#merge_request_comments .comment.inline .inline_comment_link a").live("click", function(){
    var comment = $(this).parent().parent();
    var path = $(comment).attr("data-diff-path");
    var last_line = $(comment).attr("data-last-line-in-diff");
    var elementInDiff = function(s) {
      return $(".file-diff[data-diff-path=" + path + "] " + s);
    }
    var hunks = elementInDiff(".diff-hunks");
    hunks.removeClass("closed").addClass("open");
    hunks.slideDown();
    elementInDiff(".diff-comments.line-" + last_line).slideToggle();
    Gitorious.DiffBrowser.CommentHighlighter.add( $($(this).attr("href")) );
    return true;
  })

  $("#toggle_inline_comments").live("change", function(){
    if ($(this).is(":checked")) {
      $(".comment.inline").show();
    } else {
      $(".comment.inline").hide();
    }
  });
});

var Gitorious = {};
Gitorious.DownloadChecker = {
      checkURL: function(url, container) {
        var element = $("#" + container);
        //element.absolutize();
        var sourceLink = element.prev();
        // Position the box
        if (sourceLink) {
            element.css({
                'top': parseInt(element[0].style.top) - (element.height()+10) + "px",
                'width': '175px',
                'height': '70px',
                'position': 'absolute'
            });
        }

        element.html('<p class="spin"><img src="/images/spinner.gif" /></p>');
        element.show();
        // load the status
        element.load(url, function(responseText, textStatus, XMLHttpRequest){
            if (textStatus == "success") {
                $(this).html(responseText);
            }
        });
        return false;
    }
};

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
    result = this.shaSpec();
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
  result = new Gitorious.ShaSpec();
  _hash = hash.replace(/#/, "");
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
      window.scrollTo(0, element.position().top + window.innerHeight);
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
    $(window).keypress(function(e) {
        $(window).keydown(Gitorious.DiffBrowser.KeyNavigation._callback);
      });
    // unbind whenever we're in an input field
    Gitorious.DiffBrowser.KeyNavigation.disable();
    $(":input").blur(function() {
        $(window).keydown(Gitorious.DiffBrowser.KeyNavigation._callback);
    });
  },

  disable: function() {
    $(":input").focus(function() {
        $(window).unbind("keypress", Gitorious.DiffBrowser.KeyNavigation._callback);
    });
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

// Gitorious.Wordwrapper = {
//   wrap: function(elements) {
//     elements.each(function(e) {
//       //e.addClassName("softwrapped");
//       e.removeClassName("unwrapped");
//     });
//   },
  
//   unwrap: function(elements) {
//     elements.each(function(e) {
//       //e.removeClassName("softwrapped");
//       e.addClassName("unwrapped");
//     });
//   },
  
//   toggle: function(elements) {
//     if (/unwrapped/.test(elements.first().className)) {
//       Gitorious.Wordwrapper.wrap(elements);
//     } else {
//       Gitorious.Wordwrapper.unwrap(elements);
//     }
//   }
// }

// A class used for selecting ranges of objects
function CommitRangeSelector(commitListUrl, targetBranchesUrl, statusElement)
{
  this.commitListUrl = commitListUrl
  this.targetBranchesUrl = targetBranchesUrl;
  this.statusElement = statusElement;
  this.endsAt = null;
  this.sourceBranchName = null;
  this.targetBranchName = null;
  this.REASONABLY_SANE_RANGE_SIZE = 50;
  
  this.endSelected = function(el) {
    this.endsAt = $(el);
    this.update();
  };
  
  this.onSourceBranchChange = function(event) {
    if (sourceBranch = $('#merge_request_source_branch')) {
      this.sourceBranchSelected(sourceBranch);
    }
  };
  
  this.onTargetRepositoryChange = function(event) {
    console.log("repo changed!");
    $("#spinner").fadeIn();
    $.post(this.targetBranchesUrl, $("#new_merge_request").serialize(),
           function(data, responseText)
    {
      if (responseText === "success") {
        $("#target_branch_selection").html(data);
        $("#spinner").fadeOut();
      }
    });
    this._updateCommitList();
  };
  
  this.onTargetBranchChange = function(event) {
    if (targetBranch = $('#merge_request_target_branch').val()) {
      this.targetBranchSelected(targetBranch);
    }
  };
  
  this.targetBranchSelected = function(branchName) {
    if (branchName != this.targetBranchName) {
      this.targetBranchName = branchName;
      this._updateCommitList();
    }
  };
  
  this.sourceBranchSelected = function(branchName) {
    if (branchName != this.sourceBranchName) {
      this.sourceBranchName = branchName;
      this._updateCommitList();
    }
  };
  
  this.update = function() {
    if (this.endsAt) {
      $(".commit_row").each(function(){ $(this).removeClass("selected") });
      var selectedTr = this.endsAt.parent().parent();
      selectedTr.addClass('selected');
      var selectedTrCount = 1;
      selectedTr.nextAll().each(function() {
          $(this).addClass('selected');
          selectedTrCount++;
      });

      if (selectedTrCount > this.REASONABLY_SANE_RANGE_SIZE) {
        $("#large_selection_warning").slideDown();
      } else {
        $("#large_selection_warning").slideUp();
      }

      // update the status field with the selected range
      var to = selectedTr.find(".sha-abbrev a").html();
      var from = $(".commit_row:last .sha-abbrev a").html();
      $("." + this.statusElement).each(function() {
          $(this).html(from + ".." + to);
      });
    }
  };
  
  this._updateCommitList = function() {
    $("#commit_table").replaceWith('<p class="hint">Loading commits&hellip; ' +
                                   '<img src="/images/spinner.gif"/></p>');
    $.post(this.commitListUrl, $("#new_merge_request").serialize(),
           function(data, responseText)
    {
        if (responseText === "success")
          $("#commit_selection").html(data);
    });
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

}

Gitorious.CommentForm = function(path){
  this.path = path;
  this.numbers = [];
  this.setLineNumbers = function(n) {
    result = [];
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
      jQuery.ajax({
        "url": $(this).attr("action"),
        "data": $(this).serialize(),
        "type": "POST",
        "success": function(data, text) {
          Gitorious.CommentForm.destroyAll();
          new Gitorious.DiffBrowser(shas);
        },
        "error": function(xhr, statusText, errorThrown) {
          var errorDisplay = $(zeForm).find(".error");
          zeForm.find(".progress").hide("fast");
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
}

function toggle_wiki_preview(target_url) {
  var wiki_preview = $('#page_preview');
  var wiki_edit = $('#page_content');
  var wiki_form = wiki_edit[0].form;
  var toggler = $('#wiki_preview_toggler');
  if (toggler.val() == "Hide preview") {
    toggler.val("Show preview");
  } else {
    toggler.val("Hide preview");
    wiki_preview.html("");
    $.post(target_url, $(wiki_form).serialize(), function(data, textStatus){
        if (textStatus == "success") {
          wiki_preview.html(data);
        }
    });
  }
  jQuery.each([wiki_preview, wiki_edit], function(){ $(this).toggle() });
}

// function load_commit_status()
// {
//   var merge_request_uri = document.location.pathname;
//   ['merged','unmerged'].each(function(s)
//   {
//     var i1 = new Image();
//     i1.src = "/images/merge_requests/" + s + ".png";        
//   });
//   $$('tr.commit_row').each(function(commit_row)
//   {
//     id = commit_row.getAttribute('data-merge-request-commit-id');
//     new Ajax.Request(merge_request_uri + "/commit_status?commit_id=" + id, {method:'get', onSuccess: function(transport){
//       commit_row.removeClassName("unknown-status");
//       if (transport.responseText == 'false'){
//         commit_row.addClassName("unmerged");
//       }
//       else{
//         commit_row.addClassName("merged");
//       }
//     }});
//   });
// }

if (!Array.prototype.each) {
  Array.prototype.each = function(callback) {
    jQuery.each(this, callback);
  }
}
if (!Array.prototype.map) {    
  Array.prototype.map = function(callback) {
    return jQuery.map(this, callback);
  }
}

// https://developer.mozilla.org/en/Core_JavaScript_1.5_Reference/Global_Objects/Array/filter
if (!Array.prototype.filter)
{
  Array.prototype.filter = function(fun /*, thisp*/)
  {
    var len = this.length >>> 0;
    if (typeof fun != "function")
      throw new TypeError();
    
    var res = new Array();
    var thisp = arguments[1];
    for (var i = 0; i < len; i++)
    {
      if (i in this)
      {
        var val = this[i]; // in case fun mutates this
        if (fun.call(thisp, val, i, this))
          res.push(val);
      }
    }    
    return res;
  };
}

if (!String.prototype.isBlank) {
  String.prototype.isBlank = function() {
    return this == "";
  }
}


// Make JQuery work with Rails' respond_to
jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} 
})
