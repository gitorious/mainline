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

Event.observe(window, "load", function(e){
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
});


// A class used for selecting ranges of objects
function SelectableRange(commitListUrl, targetBranchesUrl)
{
  this.commitListUrl = commitListUrl
  this.targetBranchesUrl = targetBranchesUrl;
  this.endsAt = null;
  this.sourceBranchName = null;
  this.targetBranchName = null;
  
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
      console.debug("New target branch selected");
      this.targetBranchName = branchName;
      this._updateCommitList();
    }
  };
  
  this.sourceBranchSelected = function(branchName) {
    if (branchName != this.sourceBranchName) {
      console.debug("New source branch selected");
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
      if (commitRows.last() == firstTr) {
        var from = firstTr.getElementsBySelector(".sha-abbrev a")[0].innerHTML;
      } else {
        var lastSibling = firstTr.siblings().last();
        var from = lastSibling.getElementsBySelector(".sha-abbrev a")[0].innerHTML;
      }
      $(this.statusElement).update(from + ".." + to);
    }
  };
  
  this._updateCommitList = function() {
    new Ajax.Updater('commit_selection', this.commitListUrl, {
      method: 'post', 
      parameters: Form.serialize($('new_merge_request'))
    });
  }
}
