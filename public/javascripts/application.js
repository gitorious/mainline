
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
/*jslint onevar: false, eqeqeq: false, plusplus: false, nomen: false*/
/*global $, document, Gitorious*/

$(document).ready(function () {
    // Project Sluggorizin'
    $("form #project_title").keyup(function (event) {
        var slug = $("form #project_slug");

        if (slug.text() != "") {
            return;
        }

        var lintName = function (val) {
            var linted = val.replace(/\W+/g, " ").replace(/\ +/g, "-");
            linted = linted.toLowerCase().replace(/\-+$/g, "");
            return linted;
        };

        slug.val(lintName(this.value));
    });

    // Line highlighting/selection
    $("#codeblob").highlightSelectedLines();

    // no-op links
    $("a.link_noop").click(function (event) {
        event.preventDefault();
    });

    // Comment previewing
    $("input#comment_preview_button").click(function (event) {
        var formElement = $(this).parents("form");
        var url = formElement.attr("action");
        url += "/preview";

        $.post(url, formElement.serialize(), function (data, responseText) {
            if (responseText === "success") {
                $("#comment_preview").html(data);
                $("#comment_preview").fadeIn();
            }
        });
        event.preventDefault();
    });

    // Project previewing
    $("input#project_preview_button").click(function (event) {
        var formElement = $(this).parents("form");
        var url = $(this).attr("gts:url");

        $.post(url, formElement.serialize(), function (data, response) {
            if (response === "success") {
                $("#project-preview").html(data).fadeIn();
            }
        });
        event.preventDefault();
    });

    // Markdown help toggling
    $(".markdown-help-toggler").click(function (event) {
        $(".markdown_help").toggle();
        event.preventDefault();
    });

    $("a#advanced-search-toggler").click(function (event) {
        $("#search_help").slideToggle();
        event.preventDefault();
    });

    // Merge request status color picking
    $("#merge_request_statuses input.color_pickable").SevenColorPicker();

    // Toggle details of commit events
    $("a.commit_event_toggler").click(function (event) {
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
    $("#big_header_login_box_to_openid, #big_header_login_box_to_regular").click(function (e) {
        $("#big_header_login_box_openid").toggle("fast");
        $("#big_header_login_box_regular").toggle("fast");
        e.preventDefault();
    });

    // replace the search form input["submit"] with something fancier
    $("#main_menu_search_form").each(function () {
        var headerSearchForm = this;
        var labelText = "Search...";
        var searchInput = $(this).find("input[type=text]");
        searchInput.val(labelText);
        searchInput.click(function (event) {
            if (searchInput.val() == labelText) {
                searchInput.val("");
                searchInput.removeClass("unfocused");
            }
        });
        searchInput.blur(function (event) {
            if (searchInput.val() == "") {
                searchInput.val(labelText);
                searchInput.addClass("unfocused");
            }
        });
        // hide the "native" submit button and replace it with our
        // own awesome submit button
        var nativeSubmitButton = $(this).find("input[type=submit]");
        nativeSubmitButton.hide();
        var awesomeSubmitButton = $(document.createElement("a"));
        awesomeSubmitButton.attr({
            "id": "main_menu_search_form_graphic_submit",
            "href": "#"
        });
        awesomeSubmitButton.click(function (event) {
            headerSearchForm.submit();
            event.preventDefault();
        });
        nativeSubmitButton.after(awesomeSubmitButton);
    });

    // Commment editing
    $(".comment .edit_link a").live("click", function () {
        var commentContainer = $(this).parents(".comment");
        var formUrl = $(this).attr("gts:url");
        var spinner = $(this).parent().next(".link-spinner").show();
        var commentId = commentContainer.attr("gts:comment-id");
        var commentLink = commentContainer.siblings("[name=comment_" + commentId + "]");

        $.ajax({
            url: formUrl,
            success: function (data) {
                spinner.hide();
                commentContainer.append(data);
                commentContainer.find("form").submit(function () {
                    var url = $(this).attr("action");
                    var data = $(this).serialize();

                    $.post(url, data, function (payload) {
                        commentLink.remove();
                        commentContainer.replaceWith(payload);
                    });

                    return false;
                });
            },

            error: function () {
                spinner.hide();
                commentContainer.append(
                    "<p>We're sorry, but you're not allowed to edit the comment. " +
                    "Only the creator of a comment may edit it, and then only for " +
                    "a short period of time after it's been created</p>"
                );
            }
        });
    });

    $('.js-pjax').pjax('#content', { 
        timeout: null, 
        error: function(xhr, err){
        // handle errors
        }
    })

    $(".comment .comment_form .cancel").live("click", function () {
        var theForm = $(this).parents(".comment_form");
        theForm.remove();
    });

    // Relative times based on clients browser time
    $.extend($.timeago.settings.strings, {
        seconds: "a minute",
        minute: "a minute",
        minutes: "%d minutes",
        hour: "an hour",
        hours: "%d hours",
        day: "a day",
        days: "%d days",
        month: "a month",
        months: "%d months",
        year: "a year",
        years: "%d years"
    });

    $("abbr.timeago").timeago();

    // Watch/unwatch projects and repositories
    $("a[data-request-method]").toggleResource({
        texts: { enabled: "Unwatch", disabled: "Watch" }
    });

    // watchable/favorite list filtering
    $(".your-favorites").each(function () {
        var $this = $(this);
        $this.find(".filters a.all").addClass("current");
        $this.find(".filters a").css({"outline": "none"});

        var makeCurrent = function (newCurrent) {
            $this.find(".filters a").removeClass("current");
            $(newCurrent).addClass("current");
        };
        var swapAndMakeCurrent = function (klass, current) {
            $this.find(".favorite." + klass).show();
            $this.find(".favorite:not(." + klass + ")").hide();
            makeCurrent(current);
        };

        $this.find(".filters a.all").click(function () {
            $this.find(".favorite").show();
            makeCurrent(this);
            return false;
        });

        $this.find(".filters a.repositories").click(function () {
            swapAndMakeCurrent("repository", this);
            return false;
        });

        $this.find(".filters a.merge-requests").click(function () {
            swapAndMakeCurrent("merge_request", this);
            return false;
        });

        $this.find(".filters a.mine").click(function () {
            swapAndMakeCurrent("mine", this);
            return false;
        });

        $this.find(".filters a.foreign").click(function () {
            swapAndMakeCurrent("foreign", this);
            return false;
        });
    });

    // Favorite toggling and deletion on the /favorites page
    $("#favorite-listing tr:odd").addClass("odd");
    $("#favorite-listing td.notification .favorite.update a").click(function () {
        var $this = $(this), payload;
        if ("off" == $this.text()) {
            payload = "_method=put&favorite[notify_by_email]=1";
        } else {
            payload = "_method=put&favorite[notify_by_email]=0";
        }
        $.post($this.attr("href"), payload, function (data, respTxt) {
            if ("success" === respTxt) {
                if ("off" === $this.text()) {
                    $this.text("on").removeClass("disabled").addClass("enabled");
                } else {
                    $this.text("off").removeClass("enabled").addClass("disabled");
                }
            }
        });

        return false;
    });

    $("#favorite-listing td.unwatch .favorite a.watch-link").click(function () {
        var $this = $(this);
        var payload = "_method=delete";
        $.post($this.attr("href"), payload, function (data, respTxt) {
            if ("success" === respTxt) {
                $this.parents("tr").fadeOut("normal", function () {
                    $(this).remove();
                    $("#favorite-listing tr").removeClass("odd");
                    $("#favorite-listing tr:odd").addClass("odd");
                });
            }
        });

        return false;
    });

    // Misc
    $('.with_sidebar').parent().addClass('sidebar-enabled');
    $("ul.navigation").find("li:first").addClass("first"); 
    $("ul.navigation").find("li:last").addClass("last"); 
    $("ul.navigation ~ ul.navigation").addClass("multiple");
    $("table").find("tr:first").find("th:first").addClass("first");
    $("table").find("tr:first").find("th:last").addClass("last");

    $("div.expandable").expander({
        slicePoint: 220,         // default is 100
        expandText: "read more", // default is "read more..."
        collapseTimer: 0,        // re-collapses after 5 seconds; default is 0, so no re-collapsing
        userCollapseText: "",    // default is "[collapse expanded text]"
        expandEffect: "fadeIn",
        userCollapse: true,
        expandSpeed: 800         // speed in milliseconds of the animation effect for expanding the text
    });

    // clone help texts
    $("a.clone-help-toggler").click(function (e) {
        $("#" + this.id + "-box").toggle();
        e.preventDefault();
    });

});

if (!this.Gitorious) {
    this.Gitorious = {};
}

Gitorious.DownloadChecker = {
    checkURL: function (url, container) {
        var element = $("#" + container);
        //element.absolutize();
        var sourceLink = element.prev();
        // Position the box
        if (sourceLink) {
            element.css({
                top: parseInt(element[0].style.top, 10) - (element.height() + 10) + "px",
                width: "175px",
                height: "70px",
                position: "absolute"
            });
        }

        element.html('<p class="spin"><img src="/images/spinner.gif" /></p>');
        element.show();
        // load the status
        element.load(url, function (responseText, textStatus, XMLHttpRequest) {
            if (textStatus == "success") {
                $(this).html(responseText);
            }
        });
        return false;
    }
};

// Gitorious.Wordwrapper = {
//   wrap: function (elements) {
//     elements.each(function (e) {
//       //e.addClassName("softwrapped");
//       e.removeClassName("unwrapped");
//     });
//   },

//   unwrap: function (elements) {
//     elements.each(function (e) {
//       //e.removeClassName("softwrapped");
//       e.addClassName("unwrapped");
//     });
//   },

//   toggle: function (elements) {
//     if (/unwrapped/.test(elements.first().className)) {
//       Gitorious.Wordwrapper.wrap(elements);
//     } else {
//       Gitorious.Wordwrapper.unwrap(elements);
//     }
//   }
// }

// A class used for selecting ranges of objects
function CommitRangeSelector(commitListUrl, targetBranchesUrl, statusElement) {
    this.commitListUrl = commitListUrl;
    this.targetBranchesUrl = targetBranchesUrl;
    this.statusElement = statusElement;
    this.endsAt = null;
    this.sourceBranchName = null;
    this.targetBranchName = null;
    this.REASONABLY_SANE_RANGE_SIZE = 50;

    this.endSelected = function (el) {
        this.endsAt = $(el);
        this.update();
    };

    this.onSourceBranchChange = function (event) {
        var sourceBranch = $("#merge_request_source_branch");

        if (sourceBranch) {
            this.sourceBranchSelected(sourceBranch);
        }
    };

    this.onTargetRepositoryChange = function (event) {
        $("#spinner").fadeIn();
        var serialized = $("#new_merge_request").serialize();

        $.post(this.targetBranchesUrl, serialized,
                function (data, responseText) {
                    if (responseText == "success") {
                        $("#target_branch_selection").html(data);
                        $("#spinner").fadeOut();
                    }
                }
              );

        this._updateCommitList();
    };

    this.onTargetBranchChange = function (event) {
        var targetBranch = $("#merge_request_target_branch").val();

        if (targetBranch) {
            this.targetBranchSelected(targetBranch);
        }
    };

    this.targetBranchSelected = function (branchName) {
        if (branchName != this.targetBranchName) {
            this.targetBranchName = branchName;
            this._updateCommitList();
        }
    };

    this.sourceBranchSelected = function (branchName) {
        if (branchName != this.sourceBranchName) {
            this.sourceBranchName = branchName;
            this._updateCommitList();
        }
    };

    this.update = function () {
        if (this.endsAt) {
            $(".commit_row").each(function () {
                $(this).removeClass("selected");
            });

            var selectedTr = this.endsAt.parent().parent();
            selectedTr.addClass("selected");
            var selectedTrCount = 1;

            selectedTr.nextAll().each(function () {
                $(this).addClass("selected");
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
            $("." + this.statusElement).each(function () {
                $(this).html(from + ".." + to);
            });
        }
    };

    this._updateCommitList = function () {
        $("#commit_table").replaceWith('<p class="hint">Loading commits&hellip; ' +
                                       '<img src="/images/spinner.gif"/></p>');
        var serialized = $("#new_merge_request").serialize();
        $.post(this.commitListUrl, serialized,
               function (data, responseText) {
                    if (responseText === "success") {
                        $("#commit_selection").html(data);
                    }
                });
    };
}

function toggle_wiki_preview(target_url) {
    var wiki_preview = $("#page_preview");
    var wiki_edit = $("#page_content");
    var wiki_form = wiki_edit[0].form;
    var toggler = $("#wiki_preview_toggler");

    if (toggler.val() == "Hide preview") {
        toggler.val("Show preview");
    } else {
        toggler.val("Hide preview");
        wiki_preview.html("");

        $.post(target_url, $(wiki_form).serialize(), function (data, textStatus) {
            if (textStatus == "success") {
                wiki_preview.html(data);
            }
        });
    }

    $.each([wiki_preview, wiki_edit], function () {
        $(this).toggle();
    });
}
