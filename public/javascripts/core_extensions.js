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

// http://ejohn.org/blog/fast-javascript-maxmin/
if (!Array.prototype.max) {
    Array.prototype.max = function() {
        return Math.max.apply(Math, this);
    }
}

if (!Array.prototype.min) {
    Array.prototype.min = function() {
        return Math.min.apply(Math, this);
    }
}