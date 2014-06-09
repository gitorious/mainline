# encoding: utf-8
#--
#   Copyright (C) 2012, 2014 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David A. Cuadrado <krawek@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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
#++

module RepositoriesHelper
  include FavoritesHelper

  def markdown_help
    <<-HTML
          <div class="collapse gts-help" id="markdown-help">
            <table class="table">
              <tr>
                <td><pre><code>[link](http://gitorious.org)</code></pre></td>
                <td><a href="http://gitorious.org">link</a></td>
              </tr>
              <tr>
                <td><pre><code>    if (true) {
        return;
    }</code></pre></td>
                <td><pre><code>if (true) {
    return;
}</code></pre></td>
              </tr>
              <tr>
                <td><pre><code>inline `code` here</code></pre></td>
                <td>      inline <code>code</code> here</td>
              </tr>
              <tr>
                <td><pre><code>**bold**</code></pre></td>
                <td><strong>bold</strong></td>
              </tr>
              <tr>
                <td><pre><code>_emphasized_</code></pre></td>
                <td><em>emphasized</em></td>
              </tr>
              <tr>
                <td><pre><code>* item 1
* item 2</code></pre></td>
                <td><ul><li>item 1</li><li>item 2</li></ul></td>
              </tr>
              <tr>
                <td><pre><code>1. item 1
2. item 2</code></pre></td>
                <td><ol><li>item 1</li><li>item 2</li></ol></td>
              </tr>
              <tr>
                <td><pre><code># Header 1#</code></pre></td>
                <td><h1>Header 1</h1></td>
              </tr>
              <tr>
                <td><pre><code>## Header 2</code></pre></td>
                <td><h2>Header 2</h2></td>
              </tr>
            </table>
            <p><a href="http://daringfireball.net/projects/markdown/">Full Markdown reference</a></p>
          </div>
    HTML
  end
end
