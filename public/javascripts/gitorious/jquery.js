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
/*jslint eqeqeq: false, plusplus: false, onevar: false*/
/*global $, document, window*/

// Make JQuery work with Rails' respond_to
$.ajaxSetup({
    "beforeSend": function (xhr) {
        xhr.setRequestHeader("Accept", "text/javascript");
    },

    "complete": function () {
        $('abbr.timeago').timeago();
    }
});

$.fn.highlightSelectedLines = function () {
    var currentHighlights = [];

    if (/^#line\d+$/.test(window.location.hash)) {
        currentHighlights = [window.location.hash];
    }

    var jthis = this;
    var highlightCodeLine = function (lineId) {
        $.each(currentHighlights, function () {
            $(jthis).find("tr#" + this + " td").removeClass("marked");
        });

        $(jthis).find("tr#" + lineId + " td").addClass("marked");
        currentHighlights = [lineId];
    };

    this.find("tr td.line-numbers a").click(function () {
        var element = $(this).get(0);
        currentHighlights = [element.name];
        highlightCodeLine(currentHighlights);
    });

    if (currentHighlights.length === 0) {
        return;
    }

    highlightCodeLine(currentHighlights);
};

$.fn.changableSelection = function (options) {
    var currentContainer = $(this);
    var choices = $(options.container || $(this).next("ul.changable-selection-options"));

    choices.css({
        display: "none",
        cursor: "pointer"
    }).children("li").bind('click', function (e) {
        currentContainer.text($(this).text());
        choices.hide();

        if (options.onChange) {
            options.onChange.call(this);
        }

        return false;
    });

    currentContainer.bind('click', function (event) {
        choices.css({
            top: (event.pageY - $(this).height()) + "px",
            // TODO: Check for vicinity to screen edge and adjust left/right accordingly
            left: (event.pageX - $(this).width() - 10) + "px",
            position: "absolute",
            opacity: 1.0,
            zIndex: 1000
        }).fadeIn('fast');
        return false;
    }).css({ cursor: "pointer" });

    $(document).click(function () {
        choices.fadeOut('fast');
    });
};

$.fn.hoverBubble = function () {
    $(this).each(function () {
        var originalOffset = $(this).offset();
        var bubbleHeight = $(this).next(".hover-bubble-content").height();
        var triggerWidth = $(this).width();

        $(this).next(".hover-bubble-content").css({
            top: originalOffset.top - bubbleHeight - 25 + 'px',
            left: originalOffset.left - (triggerWidth / 2) - 50 + 'px',
            opacity: 0
        });

        $(this).hover(function () {
            $(this).next(".hover-bubble-content").stop()
                .animate({
                    top: originalOffset.top - bubbleHeight - 15 + 'px',
                    opacity: 0.95
                }, "fast").show();
        }, function () {
            $(this).next(".hover-bubble-content").stop()
                .animate({
                    top: originalOffset.top - bubbleHeight - 25 + 'px',
                    opacity: 0
                }, "fast");
        });

    });
};

// toggle the elements by sliding either up or down
$.fn.slideToggle = function (speed) {
    $(this).each(function () {
        if ($(this).is(":visible")) {
            $(this).slideUp(speed);
        } else {
            $(this).slideDown(speed);
        }
    });

    return $(this);
};
