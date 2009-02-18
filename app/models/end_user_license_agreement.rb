#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2009 Marius Mårnes Mathiesen <marius.mathiesen@gmail.com>
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

class EndUserLicenseAgreementError < StandardError;end
class EndUserLicenseAgreement
  attr_accessor :contents
  attr_reader :checksum
  
  def self.current_version
    @current_version ||= find_current_version
  end
  
  def self.reset
    @current_version = nil
  end
  
  def self.find_current_version
    returning new do |l|
      if File.exist?(filename)
        l.contents = File.read(self.filename)
      else
        raise EndUserLicenseAgreementError, "The license file could not be found"
      end
      l.calculate_checksum
    end
  end
  
  def self.filename
    File.join(Rails.root, "data", Rails.env == "test" ? "eula.license" : "eula_test.license")
  end
  
  def calculate_checksum
    @checksum = Digest::SHA1.hexdigest(contents)
  end
end