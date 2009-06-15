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

var ProjectSluggorizer = Class.create({
  initialize: function(source, target) {
   this.source = $(source);
   this.target = $(target); 
   new Form.Element.Observer(
     this.source,
     0.8,  
     function(el, value){
       this.target.value = this._lintedName(value);
     }.bind(this)
   )
  },
  
  _lintedName: function(val) {
    var linted = val.gsub(/\W+/, ' ')
    linted = linted.gsub(/\ +/, '-')
    linted = linted.toLowerCase();
    linted = linted.gsub(/\-+$/, '')
    return linted;
  }
});

var Gitorious = {
  LineHighlighter: Class.create({    
    initialize: function(table) {
      this.table = $(table);
      this.currentHighlights = [];
      this.highlightClassname = "marked";
    },


    update: function(line){
      var lineno = line || this._getLineNumberFromUri();
      if (lineno) {
        this._clearExistingHighlights();
        this._highlight(lineno);
      }
    },

    _highlight: function(lineId) {
      this.table.getElementsBySelector(lineId + " td").each(function(cell) {
        cell.addClassName(this.highlightClassname);
        this.currentHighlights.push(cell);
      }.bind(this));
    },

    _getLineNumberFromUri: function() {
      var uriHash = window.location.hash;
      if (/^#line\d+$/.test(uriHash)) {
        return uriHash;
      }
    },

    _clearExistingHighlights: function() {
      if (this.currentHighlights.length > 0) {
        this.currentHighlights.each(function(hl) {
          hl.removeClassName(this.highlightClassname);
        }.bind(this));
        this.currentHighlights = [];
      }
    }
  }),
  
  Wordwrapper: {
    wrap: function(elements) {
      elements.each(function(e) {
        //e.addClassName("softwrapped");
        e.removeClassName("unwrapped");
      });
    },
    
    unwrap: function(elements) {
      elements.each(function(e) {
        //e.removeClassName("softwrapped");
        e.addClassName("unwrapped");
      });
    },
    
    toggle: function(elements) {
      if (/unwrapped/.test(elements.first().className)) {
        Gitorious.Wordwrapper.wrap(elements);
      } else {
        Gitorious.Wordwrapper.unwrap(elements);
      }
    }
  },
  
  DownloadChecker: {
    checkURL: function(url, container) {
      var element = $(container);
      element.absolutize();
      var sourceLink = element.previous();
      // Position the box
      if (sourceLink) {
        element.clonePosition(sourceLink);
        element.setStyle({
          top: parseInt(element.style.top) - (element.getHeight()+10) + "px",
          width: "175px",
          height: "70px"
        });
      }
      
      element.show();
      element.innerHTML = '<p class="spin"><img src="/images/spinner.gif" /></p>'
      // load the status
      new Ajax.Request(url, {
        onSuccess: function(transport) {
          $(container).update(transport.responseText);
        }
      });
      return false;
    }
  }
};

Event.observe(window, "dom:loaded", function(e){
  var blobTable = $("codeblob")
  if (blobTable) {
    var highlighter = new Gitorious.LineHighlighter(blobTable);
    highlighter.update();
    
    blobTable.getElementsBySelector("td.line-numbers a").each(function(link) {
      var lineno = link.href.split("#").last();
      link.observe("click", function(event) {
        highlighter.update("#" + lineno);
      });
    });
  }
  
  $$("a.link_noop").each(function(element) {
    element.observe("click", function(e){ 
      Event.stop(e); 
      return false;
    })
  })

  // Unobtrusively hooking the regular/OpenID login box stuff, so that it works
  // in a semi-sensible way with javascript disabled.
  var loginBox = $("big_header_login");
  if (loginBox) {
    var openIdLoginBox  = $("big_header_login_box_openid");
    var regularLoginBox   = $("big_header_login_box_regular");
    
    // Only showing the regular login
    
    // Toggle between the two
    var loginBoxToggler = function(e){
      Effect.toggle(openIdLoginBox, "appear", {duration: 0.3 });
      Effect.toggle(regularLoginBox, "appear", {duration: 0.3 });
      Event.stop(e);
      return false;
    }
    
    $("big_header_login_box_to_openid").observe("click", loginBoxToggler);
    $("big_header_login_box_to_regular").observe("click", loginBoxToggler);
  }
  
  var headerSearchForm = $("main_menu_search_form")
  if (headerSearchForm) {
    // The "Search..." label
    var labelText = "Search..."
    var searchInput = $("main_menu_search_form_query");
    searchInput.value = labelText;
    searchInput.observe("focus", function(){
      if (searchInput.value == labelText) {
        searchInput.value = "";
        searchInput.removeClassName("unfocused")
      }
    });
    
    searchInput.observe("blur", function(){
      if (searchInput.value == "") {
        searchInput.value = labelText;
        searchInput.addClassName("unfocused")
      }
    });
    
    // Hide the regular native submit button
    var nativeSubmitButton = headerSearchForm.getElementsBySelector("input[type=submit]")[0];
    nativeSubmitButton.hide();
    
    // Create our own awesome submit button.
    var awesomeSubmitButton = $(document.createElement("a"));
    awesomeSubmitButton.writeAttribute("id", "main_menu_search_form_graphic_submit");
    awesomeSubmitButton.writeAttribute("href", "#");
    awesomeSubmitButton.observe("click", function(e){
      headerSearchForm.submit();
      Event.stop(e);
      return false;
    });
    
    nativeSubmitButton.insert({after: awesomeSubmitButton});
  }
  
  var recentActivitiesTarget = $("recent_activities_container");
  if (recentActivitiesTarget) {
    var RECENT_ACTIVITY_WIDTH     = 280;
    var NUM_RECENT_ACTIVITIES     = 8;
    var RECENT_ACTIVITIES_HEADER  = 186 + (20 * 2);
    var BAR_WIDTH                 = (RECENT_ACTIVITY_WIDTH * NUM_RECENT_ACTIVITIES) + RECENT_ACTIVITIES_HEADER;
    
    var FPS                       = 30;
    var ANIMATION_STEP            = 2;
    var LOAD_MORE_OFFSET          = 400;
    
    var currentIteration          = 0;
    var currentAnimTimeout
    

    var getWindowWidth = function(){
      return (window.innerWidth || document.documentElement.clientWidth);
    }
    
    recentActivitiesTarget.setStyle({left: getWindowWidth() + "px"});
    
    var fetchNewBar = function(callback){
      currentIteration++;
      new Ajax.Request("/events/recent_for_homepage", {
        onSuccess: function(response) {
          // Expand the width of the container
          recentActivitiesTarget.setStyle({width: BAR_WIDTH + parseInt(recentActivitiesTarget.getStyle("width")) + "px"});
          
          // Append the new bar
          var newBar = response.responseText;
          Element.insert(recentActivitiesTarget, newBar);
          $$(".recent_activities_bar").each(function(element){
            element.setStyle({width: BAR_WIDTH + "px"});
          });
          
          if (callback) { callback.call() }
        }
      });
    }
    
    var animateBar = function(){
      var currentOffset = parseInt(recentActivitiesTarget.getStyle("left"));
      var newOffset = currentOffset - ANIMATION_STEP
      recentActivitiesTarget.setStyle({left: newOffset + "px"});
      

      if ((BAR_WIDTH * currentIteration) - (getWindowWidth() - newOffset) <= LOAD_MORE_OFFSET) {
        fetchNewBar();
      }
      
      currentAnimTimeout = setTimeout(animateBar, FPS);
    }
    

    recentActivitiesTarget.observe("mouseover", function(e){
      clearTimeout(currentAnimTimeout);
    });
    
    recentActivitiesTarget.observe("mouseout", function(e){
      if (!e.relatedTarget || !e.relatedTarget.descendantOf(this)) {
        animateBar();
      }
    })
    
    fetchNewBar(animateBar);
  }
});


// A class used for selecting ranges of objects
function SelectableRange(commitListUrl, targetBranchesUrl, statusElement)
{
  this.commitListUrl = commitListUrl
  this.targetBranchesUrl = targetBranchesUrl;
  this.statusElement = statusElement;
  this.endsAt = null;
  this.sourceBranchName = null;
  this.targetBranchName = null;
  this.registerResponders = function() {
    Ajax.Responders.register({
      onCreate: function() {
      if ($("spinner") && Ajax.activeRequestCount > 0)
        Effect.Appear("spinner", { duration:0.3 })
      },
      onComplete: function() {
        if ($("spinner") && Ajax.activeRequestCount == 0)
          Effect.Fade("spinner", { duration:0.3 })
      }
    });
  };
  this.registerResponders();
  
  this.endSelected = function(el) {
    this.endsAt = el;
    this.update();
  };
  
  this.onSourceBranchChange = function(event) {
    if (sourceBranch = $F('merge_request_source_branch')) {
      this.sourceBranchSelected(sourceBranch);
    }
  };
  
  this.onTargetRepositoryChange = function(event) {
    new Ajax.Updater('target_branch_selection', this.targetBranchesUrl, {
      method: 'post', 
      parameters: Form.serialize($('new_merge_request'))
    });
    this._updateCommitList();
  };
  
  this.onTargetBranchChange = function(event) {
    if (targetBranch = $F('merge_request_target_branch')) {
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
      var commitRows = $$(".commit_row");
      commitRows.each(function(el){ el.removeClassName('selected') });
      var firstTr = this.endsAt.up().up();
      firstTr.addClassName('selected');
      firstTr.nextSiblings().each(function(tr) {
        tr.addClassName('selected');        
      });
      // update the status field with the selected range
      var to = firstTr.getElementsBySelector(".sha-abbrev a")[0].innerHTML;
      var from = commitRows.last().getElementsBySelector(".sha-abbrev a")[0].innerHTML;
      $$("." + this.statusElement).each(function(e) {
        e.update(from + ".." + to);
      });
    }
  };
  
  this._updateCommitList = function() {
    new Ajax.Updater('commit_selection', this.commitListUrl, {
      method: 'post', 
      parameters: Form.serialize($('new_merge_request'))
    });
  }
}

function toggle_wiki_preview(target_url)
{
  var wiki_preview = $('page_preview');
  var wiki_edit = $('page_content');
  var wiki_form = wiki_edit.form;
  var toggler = $('wiki_preview_toggler');
  if (wiki_preview.visible()) // Will hide preview
  {
    toggler.value = "Show preview"
  }
  else
  {
    toggler.value = "Hide preview"
    wiki_preview.innerHTML = "";
    new Ajax.Request(target_url, {asynchronous:true, evalScripts:true, method:'post', parameters:Form.serialize(wiki_form)});
  }
  [wiki_preview,wiki_edit].each(function(e){e.toggle()});
}