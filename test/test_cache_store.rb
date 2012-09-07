# Copyright (c) 2006 Damien Merenne

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# This fragment store remembers the fragments that have been 
# cached or deleted so that we can use it to check if
# caching or expiring of fragment was done or not.
class TestCacheStore < ActiveSupport::Cache::MemoryStore #:nodoc:
  attr_reader :written, :deleted, :deleted_matchers
  
  def initialize
    super
    @written = []
    @deleted = []
    @deleted_matchers = []
  end
  
  def reset
    @data.clear
    @written.clear
    @deleted.clear
    @deleted_matchers.clear
  end
  
  def write(name, value, options = nil)
    @written.push(name)
    super
  end
  
  def delete(name, options = nil)
    @deleted.push(name)
    super
  end
  
  def delete_matched(matcher, options = nil)
    @deleted_matchers.push(matcher)
  end
  
  def written?(name)
    @written.include?(name)
  end
  
  def deleted?(name)
    @deleted.include?(name) || @deleted_matchers.detect { |matcher| name =~ matcher }
  end
end
