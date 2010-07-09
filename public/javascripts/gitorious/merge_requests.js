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
var diffBrowserCompactCommitSelectable;
$(document).ready(function() {
    $("body#merge_requests", function(){
        var spec = Gitorious.ShaSpec.parseLocationHash(document.location.hash);
        if (spec) {
          Gitorious.MergeRequestController.getInstance().loadFromBookmark(spec);
        }
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
        $.cookie(cookiePrefix + "-diff-hunks-state", "expanded", { expires:365 });
        e.preventDefault();
    });
    $(".file-diff-controls a#collapse-all").live("click", function(e){
        var container = $(this).parent().parent().parent();
        var cookiePrefix = $(this).attr("gts:cookie-prefix") || 'generic';
        container.find('.file-diff .header').removeClass("open").addClass("closed");
        container.find('.diff-hunks').hide();
        $.cookie(cookiePrefix + "-diff-hunks-state", "collapsed", { expires:365 });
        e.preventDefault();
    });

    // merge request diffing loading indimacator
    Gitorious.MergeRequestDiffSpinner = $("#merge_request_diff_loading").html();
    $("#merge_request_diff").html(Gitorious.MergeRequestDiffSpinner);

    // Merge request selection of branches, compact mode
    // wrapped in a function so we can reuse it when we load another version
    diffBrowserCompactCommitSelectable = function() {
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
          var version = $(this).attr("data-mr-version-number");
          Gitorious.MergeRequestController.getInstance().loadVersion(version);
//          Gitorious.MergeRequestController.getInstance().versionChanged(version);
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

    // Diff commenting
    $("table tr td.inline_comments a.diff-comment-count").live("click", function(e) {
        var lineOffsets = $(this).parents("tr").attr("data-line-num-tuple");
        $("#diff-inline-comments-for-" + lineOffsets).slideToggle();
        e.preventDefault();
    });


    // Clicking on a comment relating to an inline commit comment
    $(".commentable.comments .inline_comment_link a").live("click", function (){
        var comment = $(this).parents("div.comment.inline");
        var path = $(comment).attr("data-diff-path");
        var last_line_number = $(comment).attr("data-last-line-in-diff");
        var href = $(this).attr("href");
        var hunks = $(".file-diff[data-diff-path=" + path + "] .diff-hunks");
        hunks.removeClass("closed").addClass("open");
        hunks.slideDown();
        var lastLine = $("#diff-inline-comments-for-" + last_line_number);
        lastLine.slideToggle();
        Gitorious.DiffBrowser.CommentHighlighter.add($(href));
        $.scrollTo(href);
        return true;
    });
    
    // Clicking on a comment relating to a merge request 
    // version displays the comment in context
    $("#merge_request_comments .comment.inline .inline_comment_link a").live("click", function() {
        var comment = $(this).parents("div.comment.inline");
        var path = $(comment).attr("data-diff-path");
        var last_line = $(comment).attr("data-last-line-in-diff");
        var sha_range = $(comment).attr("data-sha-range");
        var version = $(comment).attr("data-merge-request-version");

        // Notify the controller of the current version and sha range
        // Add self as listener when this has been completed
        // When this has been completed, remove self as listener
        var elementInDiff = function(s) {
          return $(".file-diff[data-diff-path=" + path + "] " + s);
        }
        var href =  $(this).attr("href");
        var commentSpinner = $("#loading_comment_" + href.split("_")[2]);
        commentSpinner.show();
        var jumpToComment = {
            shaListingCurrent: function(newOrOld) {
                var c = Gitorious.MergeRequestController.getInstance();
                var spec = Gitorious.ShaSpec.parseShas(sha_range);
                c.simulateShaSelection(spec);
                c.replaceDiffContents(sha_range, this.displayComments, this);
            },
            displayComments: function(message) {                
                var lastLine = elementInDiff("#diff-inline-comments-for-" + last_line);
                var hunks = elementInDiff(".diff-hunks");
                hunks.removeClass("closed").addClass("open");
                hunks.slideDown();
                lastLine.slideToggle();
                Gitorious.DiffBrowser.CommentHighlighter.add($(href));                
                this.finish();
                $.scrollTo(href);
            },
            finish: function() {
                commentSpinner.hide();
                NotificationCenter.removeObserver("MergeRequestShaListingUpdated", this);
            }
        };
        NotificationCenter.addObserver("MergeRequestShaListingUpdated",
                                       jumpToComment.shaListingCurrent.bind(jumpToComment));
        Gitorious.MergeRequestController.getInstance().versionChanged(version);
        return true;
    });

    $("#toggle_inline_comments").live("change", function(){
        if ($(this).is(":checked")) {
          $(".comment.inline").show();
        } else {
          $(".comment.inline").hide();
        }
    });
    if ($("#inline_comment_form.commit").length > 0) {
        Gitorious.enableCommenting();
    }
});


if (!Gitorious)
  var Gitorious = {};

