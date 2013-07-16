# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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

class SshKey < ActiveRecord::Base
  belongs_to :user

  def self.ready
    where(:ready => true)
  end

  def self.human_name
    I18n.t("activerecord.models.ssh_key")
  end

  def wrapped_key(cols=72)
    key.gsub(/(.{1,#{cols}})/, "\\1\n").strip
  end

  def components
    key.to_s.strip.split(" ", 3)
  end

  def algorithm
    components.first
  end

  def encoded_key
    components.second
  end

  def comment
    components.last
  end

  def fingerprint
    @fingerprint ||= begin
                       raw_blob = encoded_key.to_s.unpack("m*").first
                       OpenSSL::Digest::MD5.hexdigest(raw_blob).scan(/../).join(":")
                     end
  end

  def key=(key)
    self[:key] = key.to_s.strip.gsub(/(\r|\n)*/m, "")
  end

  def uniq?
    existing = SshKey.find_by_key(key)
    existing.nil? || existing == self
  end
end
