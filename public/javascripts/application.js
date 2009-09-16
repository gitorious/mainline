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
        e.preventDefault();
    });
    $("#merge_request_diff .file-diff-controls a#collapse-all").live("click", function(e){
        var container = $(this).parent().parent().parent();
        container.find('.file-diff .header').removeClass("open").addClass("closed");
        container.find('.diff-hunks').hide();
        e.preventDefault();
    });

    // merge request diffing loading indimacator
    Gitorious.MergeRequestDiffSpinner = $("#merge_request_diff_loading").html();
    $("#merge_request_diff").html(Gitorious.MergeRequestDiffSpinner);

    // Merge request selection of branches, compact mode
    // wrapped in a function so we can reuse it when we load another version
    var diffBrowserCompactCommitSelectable = function() {
      return jQuery("#merge_request_commit_selector.compact").selectable({
        filter: "li.single_commit",
        stop: function(e, ui) {
            var sha_spec = new Gitorious.ShaSpec();
            jQuery("li.ui-selected a", this).each(function() {
                sha = jQuery(this).attr("data-commit-sha");
                sha_spec.add_sha(sha);
            });
            var mr_diff_url = jQuery("#merge_request_commit_selector")
              .attr("data-merge-request-version-url");
            diff_browser = new Gitorious.DiffBrowser(sha_spec.sha_spec());
            jQuery("#current_shas").html(sha_spec.short_sha_spec());
        }
      });
    }
    Gitorious.currentMRCompactSelectable = diffBrowserCompactCommitSelectable();

    // Merge request version viewing
    $("select#merge_request_version").live("change",(function(event){
        if (this.options[this.selectedIndex].value != '') {
          var url = $(this).attr("gts:url") + '?version=' +
            this.options[this.selectedIndex].value;
          $("#diff_browser_for_current_version").load(url, null, function() {
            new Gitorious.DiffBrowser(
              jQuery("#current_shas").attr("data-merge-request-current-shas") );
            // jump through hoops and beat the selectable into submission,
            // since it doesn't use live events, we have to re-create it, which sucks...
            Gitorious.currentMRCompactSelectable.selectable("destroy");
            Gitorious.currentMRCompactSelectable = diffBrowserCompactCommitSelectable();
          });
        }
    }));
    
    // Merge request selection of branches, monster mode
    $("#large_commit_selector_toggler").click(function(event) {
        if ($("#large_commit_selector").is(":visible")) {
          $("#large_commit_selector").slideUp();
        } else {
          $("#large_commit_selector").slideDown();
        }
        event.preventDefault();
    });
    $("#large_commit_selector table#commit_table tr input").click(function(event) {
        $(this).parents("tr").addClass("selected");
    });
    
    jQuery("#current_shas").each(function(){
        sha_spec = jQuery(this).attr("data-merge-request-current-shas");
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

Gitorious.Sha = function(sha)
{
    this.full_sha = sha;
    this.short_sha = function()
    {
        return this.full_sha.substring(0, 8);
    };
    this.sha = function()
    {
        return this.full_sha;
    }
}

Gitorious.ShaSpec = function()
{
    this.all_shas = [];
    this.add_sha = function(s)
    {
        this.all_shas.push(new Gitorious.Sha(s));
    }
    this.first_sha = function()
    {
        return this.all_shas[0];
    }
    this.last_sha = function()
    {
        return this.all_shas[this.all_shas.length - 1];
    }
    this.sha_specs = function(callback)
    {
        shas = (this.all_shas.length < 2) ? [this.first_sha()] : [this.first_sha(), this.last_sha()];
        return shas;
    }
    this.sha_spec = function()
    {
        return  this.sha_specs().map(function(s){return s.sha()}).join("..");
    }
    this.short_sha_spec = function()
    {
        return this.sha_specs().map(function(s){return s.short_sha()}).join("..");
    }

};

Gitorious.DiffBrowser = function(shas)
{
    jQuery("#merge_request_diff").html(Gitorious.MergeRequestDiffSpinner);
    var mr_diff_url = jQuery("#merge_request_commit_selector")
      .attr("data-merge-request-version-url");
    jQuery.get(mr_diff_url, {"commit_shas": shas}, function(data, responseText) {
        if (responseText === "success") {
          jQuery("#merge_request_diff").html(data);
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
