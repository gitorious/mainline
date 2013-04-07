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
require "minitest/autorun"
require "mocha"
require "pathname"
require((defined?(Rails) ? Rails.root : "") + "config/initializers/gitorious_config")

# Use this class in old test cases that dpeends on Shoulda.
# http://metaskills.net/2011/01/25/from-test-unit-shoulda-to-minitest-spec-minishoulda/
module MiniTest
  class Shoulda < MiniTest::Spec
    class << self
      alias :setup :before unless defined?(Rails)
      alias :teardown :after unless defined?(Rails)
      alias :should :it
      alias :context :describe
    end

    alias :assert_no_match :refute_match
    alias :assert_not_nil :refute_nil
    alias :assert_not_equal :refute_equal

    def assert_nothing_raised(&block)
      block.call # this assertion no longer exists!
    end
  end
end

# Constants used throughout
NULL_SHA = "0" * 40
SHA = "a" * 40
OTHER_SHA = "a" * 40

# Model mocks

module TestHelper
  class Model
    attr_accessor :id, :created_at, :updated_at

    def initialize(attributes = {})
      @is_new = true
      attributes.each { |k, v| send(:"#{k}=", v) }
    end

    def save
      @is_new = false
      self.class.register
    end

    def write_attribute(key, val); end
    def update_attribute(key, val); end
    def valid?; end
    def save!; save; end
    def new_record?; @is_new; end
    def uniq?; true; end
    def self.first; new; end
    def self.count; @count || 0; end

    private
    def self.register
      @count ||= 0
      @count += 1
    end
  end
end

if !defined?(Rails)
  class User < TestHelper::Model
    attr_accessor :login, :fullname, :email, :password, :password_confirmation,
    :terms_of_use, :aasm_state, :activated_at

    def initialize(attributes = {})
      super
      @@users ||= {}
      @@users[attributes[:email]] = self
    end

    def title; login; end
    def reset_password!; end
    def self.find_by_login(login); end

    def self.find_by_email_with_aliases(email)
      @@users ||= {}
      @@users[email]
    end
  end

  class Repository < TestHelper::Model
    attr_accessor :project, :user, :name, :hooks, :description, :browse_url,
      :clones, :owner, :user_id, :owner_id, :project_id, :parent_id,
      :merge_requests_enabled, :kind, :parent, :content_memberships

    def committerships
      return @cs if @cs
      @cs = []
      def @cs.create_for_owner!(owner); end
      @cs
    end

    def add_member(member)
      self.content_memberships ||= []
      self.content_memberships << member
    end

    def make_private; @private = true; end
    def private?; @private; end
    def public?; !private?; end
    def last_pushed_at; Time.now; end
    def uniq_name?; true; end
    def uniq_hashed_path?; true; end
    def internal?; false; end
    def watched_by!(watcher); end
    def project_repo?; true; end
    def tracking_repo?; false; end
    def real_gitdir; ""; end
    def set_repository_path; end
    def self.reserved_names; []; end
    def self.private_on_create?(repo); false; end
  end

  class RepositoryCollection < Array
    def initialize(project); @project = project; end

    def new(params)
      repository = Repository.new(params.merge(:project => @project))
      self << repository
      repository
    end
  end

  class Project < TestHelper::Model
    attr_accessor :title, :slug, :description, :events, :user, :owner, :user_id,
      :home_url, :mailinglist_url, :bugtracker_url, :owner_id

    def create_event(action_id, target, user, data = nil, body = nil, date = Time.now.utc)
      self.events ||= []
      self.events.push({
        :action_id => action_id,
        :target => target,
        :user => user,
        :data => data,
        :body => body,
        :date => date
      })
    end

    def repositories
      @repositories ||= RepositoryCollection.new(self)
    end

    def public?; true end
    def private?; false end
    def create_new_repository_event(repository); end
    def self.reserved_slugs; []; end
  end

  class Event < TestHelper::Model
    attr_accessor :action, :user, :data, :project, :target, :body
  end

  class SshKey < TestHelper::Model
    attr_accessor :key, :user_id
  end

  class Group < TestHelper::Model
  end

  class WikiRepository
    NAME_SUFFIX = "-gitorious-wiki"
  end

  class Action
    ADD_PROJECT_REPOSITORY = 19
    CLONE_REPOSITORY = 3
  end
end

# Rails shims

if !defined?(Rails)
  module Rails
    class Cache
      def fetch(key)
        yield
      end
    end

    class Environment
      def to_s; "test"; end
      def test?; true; end
      def production?; false; end
      def development?; false; end
    end

    class Logger
      def debug(message); end
    end

    def self.cache
      @cache ||= Cache.new
    end

    def self.env
      Environment.new
    end

    def self.logger
      Logger.new
    end

    def self.root
      Pathname(__FILE__) + "../../"
    end
  end

  class NilClass; def blank?; true; end; end
  class Array; def blank?; self.count == 0; end; end
  class TrueClass; def blank?; false; end; end
  class FalseClass; def blank?; true; end; end

  class String
    def blank?; self == ""; end

    def constantize
      self.split("::").inject(Object) do |mod, name|
        mod.const_get(name)
      end
    end
  end

  class Array
    def sum(&block)
      self.inject(0) { |s, n| s + block.call(n) }
    end
  end

  class Fixnum
    def days; self * 24 * 60 * 60; end
    def day; days; end
    def ago; Time.now - self; end
  end
end

class MessageHub
  attr_reader :messages
  def publish(queue, message)
    @messages ||= []
    @messages << { :queue => queue, :message => message }
  end
end
