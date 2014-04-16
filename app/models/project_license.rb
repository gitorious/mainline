# -*- coding: utf-8 -*-
#--
#   Copyright (C) 2011 Gitorious AS
#   Copyright (C) 2010 Marius Mathiesen <marius@gitorious.com>
#   Copyright (C) 2008 Dag Odenhall <dag.odenhall@gmail.com>
#   Copyright (C) 2007, 2008, 2009 Johan Sørensen <johan@johansorensen.com>
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

class ProjectLicense
  attr_reader :name, :description

  DEFAULT = ["Academic Free License v3.0",
             "Apache License",
             "Apple Public Source License",
             "Boost Software License",
             "BSD License",
             "Eclipse Public License - v 1.0",
             "GNU General Public License version 2(GPLv2)",
             "GNU General Public License version 3 (GPLv3)",
             "GNU Lesser General Public License (LGPL)",
             "GNU Affero General Public License (AGPLv3)",
             "ISC License",
             "Lisp Lesser License",
             "MIT License",
             "Microsoft Permissive License (Ms-PL)",
             "Mozilla Public License 1.0 (MPL)",
             "Mozilla Public License 1.1 (MPL 1.1)",
             "Perl Artistic License",
             "Public Domain",
             "Python License",
             "Qt Public License (QPL)",
             "Ruby License",
             "zlib/libpng License",
             "Other Open Source Initiative Approved License",
             "Other/Proprietary License",
             "Other/Multiple",
             "None"]

  def initialize(name, description = nil)
    @name = name
    @description = description
  end

  def to_s; name; end
  def inspect; name; end

  def self.default
    @default
  end

  def self.default=(default)
    @default = default
  end

  def self.all
    @licenses ||= []
  end

  def self.licenses=(licenses)
    @licenses = load_licenses(licenses)
  end

  def self.first
    all.first
  end

  private
  def self.load_licenses(licenses)
    return [] if licenses.nil?
    return licenses.map { |l| load_license(l) } if Array === licenses
    [new(licenses)]
  end

  def self.load_license(license)
    if Hash === license
      key = license.keys.first
      return new(key, license[key])
    end

    new(license)
  end
end
