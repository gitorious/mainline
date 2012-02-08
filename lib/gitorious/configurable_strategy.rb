# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
  module ConfigurableStrategy

    def configure(user_configuration)
      use_default_configuration unless user_configuration["disable_default"]
      Array(user_configuration["methods"]).each { |m| add_custom_strategy(m) }
    end

    def use_default_configuration
      add_strategy default_configuration
    end

    def add_strategy(strategy)
      strategies << strategy unless strategy_added?(strategy.class)
    end

    def strategy_added?(strategy_class)
      strategies.any? { |m| m.class == strategy_class }
    end

    def add_custom_strategy(configuration)
      strategy_class = configuration["adapter"].constantize
      add_strategy(strategy_class.new(configuration))
    end

    def strategies
      @strategies ||= []
    end
  end

  class ConfigurationError < StandardError
  end
end
