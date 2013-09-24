# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

module Gitorious
  module View
    module AvatarHelper
      def gravatar_url_for(email, options = {})
        prefix = request.ssl? ? "https://secure" : "http://www"
        scheme = request.ssl? ? "https" : "http"
        options.reverse_merge!(:default => "images/default_face.gif")
        port_string = [443, 80].include?(request.port) ? "" : ":#{request.port}"
        "#{prefix}.gravatar.com/avatar/" +
          (email.nil? ? "" : Digest::MD5.hexdigest(email.downcase)) + "&amp;default=" +
          "#{scheme}://#{Gitorious.host}#{port_string}" +
          "/#{options.delete(:default)}" +
          options.map { |k,v| "&amp;#{k}=#{v}" }.join
      end

      # For a User object, return the URL for either his/her avatar or the gravatar
      # for her email address
      # Options
      # - Pass on :size for the height+width of the image in pixels
      # - Pass on :version for a named version/style of the avatar
      def avatar_url(user, options = {})
        return user.avatar.url(options[:version] || :thumb) if user.avatar?
        gravatar_url_for(user.email, options)
      end

      # For a User object, return either his/her avatar or the gravatar for her email address
      # Options
      # - Pass on :size for the height+width of the image in pixels
      # - Pass on :version for a named version/style of the avatar
      def avatar(user, options={})
        if user.avatar?
          avatar_style = options.delete(:version) || :thumb
          image_options = { :alt => 'avatar'}.merge(:width => options[:size], :height => options[:size])
          image_tag(user.avatar.url(avatar_style), image_options)
        else
          gravatar(user.email, options)
        end
      end

      # Returns an avatar from an email address (for instance from a commit) where we don't have an actual User object
      def avatar_from_email(email, options={})
        return if email.blank?
        avatar_style = options.delete(:version) || :thumb
        image = User.find_avatar_for_email(email, avatar_style)
        if image == :nil
          gravatar(email, options, :class => "gts-avatar")
        else
          image_tag(image, {
              :alt => "avatar",
              :width => options[:size],
              :height => options[:size],
              :class => "gts-avatar"
            })
        end
      end

      def gravatar(email, options = {}, image_options = {})
        size = options[:size]
        image_options = image_options.merge({ :alt => "avatar" })
        if size
          image_options.merge!(:width => size, :height => size)
        end
        image_tag(gravatar_url_for(email, options), image_options)
      end

      def gravatar_frame(email, options = {})
        extra_css_class = options[:style] ? " gravatar_#{options[:style]}" : ""
        %{<div class="gravatar#{extra_css_class}">#{gravatar(email, options)}</div>}.html_safe
      end
    end
  end
end
