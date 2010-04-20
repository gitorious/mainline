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

// Make JQuery work with Rails' respond_to
jQuery.ajaxSetup({
    'beforeSend': function(xhr) { xhr.setRequestHeader("Accept", "text/javascript"); },
    'complete': function() { jQuery('abbr.timeago').timeago(); }
});

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


// Replace Rails' obtrusive hijacking of a elements with a custom action
// - linkName: the id given to the new link (the old one will be hidden
// - backend: The AJAX backend, used when testing
// - replaceWords: A pair of words that will be swapped in the html contents of
//   the link. See rails_form_replacer_test.js for sample usage

jQuery.fn.replaceRailsGeneratedForm = function (options) {
    return this.each(function (){
        replaceRailsGeneratedForm(this, options);
    })
}

function replaceRailsGeneratedForm(el, defaultOptions) {
    var $this = $(el);
    var options = jQuery.extend({
        linkName: $this.attr("id") + "_",
        backend: jQuery.ajax,
        replaceWords: ["Start","Stop"],
        toggleClasses: ["enabled","disabled"],
        waitingClass: "waiting"
    }, defaultOptions);
    var action = $this.attr("href");
    var httpMethod = $this.attr("data-request-method");
    var newElement = jQuery("<a>");
    newElement.attr("href", "#" + options.linkName);
    newElement.attr("id", options.linkName);
    newElement.attr("class", $this.attr("class"));
    newElement.html($this.html());
    newElement.insertAfter($this);
    $this.hide();
    var api = {
        click: function (){
            options.backend({
                url: action,
                type: "post",
                data: {"_method": httpMethod},
                success: api.success,
                complete: api.complete
            });
            newElement.addClass(options.waitingClass);
            return false;
        },
        success: function (){
            newElement.removeClass(options.waitingClass);
            if (httpMethod == "post") {
                newElement.html(newElement.html().replace(options.replaceWords[0], options.replaceWords[1]));
                httpMethod = "delete";
            } else {
                newElement.html(newElement.html().replace(options.replaceWords[1], options.replaceWords[0]));
                httpMethod = "post"
            }
            jQuery.each(options.toggleClasses, function (i, name) {
                newElement.toggleClass(name);
            })
        },
        complete: function (xhr, textStatus){
            action = xhr.getResponseHeader("Location");
        },
        element: function () {return newElement},
        action: function (){return action},
        httpMethod: function() {return httpMethod}
    };
    newElement.bind("click", api.click);
    return api;
}