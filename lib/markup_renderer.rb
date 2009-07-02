# encoding: utf-8
#--
#   Copyright (C) 2009 Johan Sørensen
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

require "zlib"

class MarkupRenderer
  class NotProcessedYetError < StandardError; end
  
  WRAPPER_NAME = "markdown-wrapper".freeze
  PRE_TAG_EXTRATION_KEY = "gts-markup-renderer".freeze
  
  def initialize(content, options = {})
    @content = content.to_s
    @options = options
    @options[:markdown] ||= [:smart]
    @markdown = nil
  end

  def markdown
    raise NotProcessedYetError unless @markdown
    @markdown
  end

  def to_html
    pre_process
    @markdown = RDiscount.new(@content, *@options[:markdown])
    post_process(@markdown.to_html)
  end

  def pre_process
    # Extract <pre> tags
    pre_tag_content = {}
    @content.gsub!(/(<pre>.*?<\/pre>)/im) do |pre|
      crc = Zlib.crc32(pre)
      pre_tag_content[crc] = pre
      "$#{PRE_TAG_EXTRATION_KEY}-#{crc}$"
    end

    # Convert windows lineendings
    @content.gsub!(/\r\n?/, "\n")
    
    # Convert any single newlines to space-space-newline
    # so markdown will break them
    @content.gsub!(/([^\n]\n)(?=[^\n])/) do |m|
      m.gsub!(/^(.+)$/, '\1  ')
    end

    # re-insert the extracted <pre> tag content
    @content.gsub!(/\$#{PRE_TAG_EXTRATION_KEY}-(\d+)\$/) do
      pre_tag_content[$1.to_i]
    end

    @content
  end

  def post_process(text)
    if @options[:wrapper].blank?
      text
    else
      if @options[:wrapper] == true
        "<div class=\"#{WRAPPER_NAME}\">\n#{text}</div>\n"
      else
        "<div class=\"#{@options[:wrapper]} #{WRAPPER_NAME}\">\n#{text}</div>\n"
      end
    end
  end
end
