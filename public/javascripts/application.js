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


function sourceBranchSelected(form, value)
{
  if (sourceBranch = $F('merge_request_source_branch'))
  {
    selectableRange.sourceBranchSelected(sourceBranch);
  }
}
// A class used for selecting ranges of objects
function SelectableRange(commitListUrl)
{
  this.commitListUrl = commitListUrl
  this.endsAt = null;
  this.sourceBranchName = null;
  this.endSelected = function(el)
  {
    this.endsAt = el;
    this.update();
  };
  this.sourceBranchSelected = function(branchName)
  {
    if (branchName != this.sourceBranchName)
    {
      console.debug("New source branch selected");
      this.sourceBranchName = branchName;
      new Ajax.Updater('commit_selection', this.commitListUrl, {method:'get', parameters: Form.serialize($('new_merge_request'))});    
    }
  };
  this.update = function()
  {
    if (this.endsAt)
    {
      $$(".commit_row").each(function(el){el.removeClassName('selected')});
      var firstTr = this.endsAt.up().up();
      firstTr.addClassName('selected');
      firstTr.previousSiblings().each(function(tr)
      {
        tr.addClassName('selected');        
      })
    }
  }
}
