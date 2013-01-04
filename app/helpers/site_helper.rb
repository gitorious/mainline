# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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

module SiteHelper
  def recent_event_timestamp(time)
    distance = Time.now - time

    human_distance = case distance
    when 0..3599
      "#{distance.ceil / 60} min."
    else
      "#{distance.ceil / 60 / 60} h."
    end
  end

  # Inserting wbr tags on colons and slashes for the recent events so that
  # it word breaks prettier.
  def word_break_recent_event_actions(text)
    text.gsub(/<a([^>]+)>([^<]+)/) {
      tag_attributes = $~[1]
      to_break = $~[2]

      word_broken = to_break.gsub(/\/|\:/) { $~[0] + "<wbr>" }
      %{<a#{tag_attributes}>#{word_broken}}
    }.html_safe
  end

  def screenshots_rotator(dir)
    root = File.join(Rails.root, "public")
    files = Dir.glob(File.join(root, dir, "*.png"))
    return "" if files.length == 0
    urls = files.collect { |f| f.sub(root, "") }

    html = <<-HTML
    <div id="screenshots-rotator">
      <div id="screenshotsnavigation"></div>
      <div id="screenshots-container">
        #{urls.collect { |u| "<img src=\"#{u}\">" }.join('').html_safe}
      </div>
    </div>
    HTML
    html.html_safe
  end
end
