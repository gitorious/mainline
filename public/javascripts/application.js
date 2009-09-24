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
        if ($("#search_help").is(":visible")) {
            $("#search_help").slideUp("fast");
        } else {
            $("#search_help").slideDown("fast");
        }
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

    // toggling of diffs in merge-request diff browser
    $('#merge_request_diff .file-diff .header').live("click", function(event) {
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
    $("#merge_request_diff .file-diff-controls a#expand-all").live("click", function(e){
        var container = $(this).parent().parent().parent();
        container.find('.file-diff .header').removeClass("closed").addClass("open");
        container.find('.diff-hunks:hidden').show();
        $.cookie("merge-requests-diff-hunks-state", "expanded");
        e.preventDefault();
    });
    $("#merge_request_diff .file-diff-controls a#collapse-all").live("click", function(e){
        var container = $(this).parent().parent().parent();
        container.find('.file-diff .header').removeClass("open").addClass("closed");
        container.find('.diff-hunks').hide();
        $.cookie("merge-requests-diff-hunks-state", null);
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
        shaSpec.summarizeHtml();
      };
      return jQuery("#merge_request_commit_selector.compact").selectable({
        filter: "li.single_commit",
        stop: function(e, ui) {
            var sha_spec = new Gitorious.ShaSpec();
            jQuery("li.ui-selected a", this).each(function() {
                sha = jQuery(this).attr("data-commit-sha");
                sha_spec.addSha(sha);
            });
          $("#current_shas .label").html("Selected:");
            var mr_diff_url = jQuery("#merge_request_commit_selector")
              .attr("data-merge-request-version-url");
            var diff_browser = new Gitorious.DiffBrowser(sha_spec.shaSpec());
        },
        selecting: function(e, ui) {
          $("#current_shas .label").html("Selecting:");
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
        if ($("#large_commit_selector").is(":visible")) {
          $("#large_commit_selector").slideUp();
        } else {
          $("#large_commit_selector").slideDown();
        }
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
    
    // FIXME: DOM id's are supposed to be unique ya know
    jQuery("#current_shas").each(function(){
        var sha_spec = jQuery(this).attr("data-merge-request-current-shas");
        diff_browser = new Gitorious.DiffBrowser(sha_spec);
      }
    );

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
  // Add shas from a string, eg ff0..bba
  this.parseShas = function(shaString) {
    pair = shaString.split("..");
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
    return jQuery.map(_specs, function(s){return s.sha()}).join("..");
  }
  
  this.shortShaSpec = function() {
    var _specs = this.shaSpecs();
    return jQuery.map(_specs, function(s){ return s.shortSha() }).join("..");
  }

  this.singleCommit = function() {
    return this.firstSha().sha() == this.lastSha().sha();
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

Gitorious.setDiffBrowserHunkStateFromCookie = function() {
  if ($.cookie("merge-requests-diff-hunks-state") === "expanded") {
    var container = $("#merge_request_diff");
    container.find('.file-diff .header').removeClass("closed").addClass("open");
    container.find('.diff-hunks:hidden').show();
  };
}

Gitorious.DiffBrowser = function(shas)
{
    jQuery("#merge_request_diff").html(Gitorious.MergeRequestDiffSpinner);
    var mr_diff_url = jQuery("#merge_request_commit_selector")
      .attr("data-merge-request-version-url");
    jQuery.get(mr_diff_url, {"commit_shas": shas}, function(data, responseText) {
        if (responseText === "success") {
          jQuery("#merge_request_diff").html(data);
          var shaSpec = new Gitorious.ShaSpec();
          shaSpec.parseShas(shas);
          shaSpec.summarizeHtml();

          Gitorious.setDiffBrowserHunkStateFromCookie();
        }
    });
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
