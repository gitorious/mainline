# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

module CapybaraTestCase
  include Capybara::DSL

  def self.included(klass)
    klass.extend ClassMethods
    CapybaraTestCase.setup_fixtures(klass)

    klass.setup do
      DatabaseCleaner.start

      CapybaraTestCase.setup_capybara(klass)
    end

    klass.teardown do
      DatabaseCleaner.clean

      CapybaraTestCase.reset_capybara
    end
  end

  def self.setup_fixtures(klass)
    klass.use_transactional_fixtures = false
    klass.fixtures :all
  end

  def self.setup_capybara(klass)
    Capybara.current_driver = klass.capybara_driver
  end

  def self.reset_capybara
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  module ClassMethods
    def js_test
      @capybara_driver = Capybara.javascript_driver
    end

    def capybara_driver
      @capybara_driver || Capybara.default_driver
    end
  end
end
