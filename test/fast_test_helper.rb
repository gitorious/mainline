# encoding: utf-8
#--
#   Copyright (C) 2012-2014 Gitorious AS
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

# We must load ci_reporter's minitest_loader explicitly here, even though
# we've also loaded it in the main Gitorious Rakefile. The reason is that the
# rake:micros task runs the fast tests through a separate system() call, so
# ci_reporter never propagates to the MiniTest class in these tests.
ENV['CI_CAPTURE'] ||= 'off'
require "ci/reporter/rake/minitest_loader"

require "mocha/setup"
require "pathname"
require((defined?(Rails) ? Rails.root : "") + "config/gitorious_config")

$: << File.expand_path('../../app/git', __FILE__)
$: << File.expand_path('../../app/services', __FILE__)

require 'action_view'

class MiniTest::Spec
  def assert_cache_header(cache_control, rack_response)
    actual = rack_response[1]["Cache-Control"]
    assert_equal cache_control.gsub(" ", ""), actual.gsub(" ","")
  end
  def assert_nothing_raised(&block)
    block.call # this assertion no longer exists!
  end
end
# Constants used throughout
NULL_SHA = "0" * 40
SHA = "a" * 40
OTHER_SHA = "a" * 40

# Model mocks

module TestHelper
  class Model
    attr_accessor :id, :to_param, :created_at, :updated_at

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
    def normalize_url(url); url; end
    def self.first; new; end
    def self.count; @count || 0; end

    def self.model_name; ActiveModel::Name.new(self); end
    private
    def self.register
      @count ||= 0
      @count += 1
    end
  end
end

if !defined?(Rails)
  class Mailer
    class Email
      def deliver; end
    end

    def self.activation(*args)
      Mailer::Email.new
    end
  end

  class FakeAttachment
    private

    def flush_errors
      {}
    end
  end

  class User < TestHelper::Model
    attr_accessor :login, :fullname, :email, :password, :password_confirmation, :activation_code,
    :terms_of_use, :activated_at, :avatar_file_name, :identity_url, :crypted_password,
    :is_admin

    def initialize(attributes = {})
      super
      @@users ||= {}
      @@users[attributes[:email]] = self
    end

    def title; login; end
    def reset_password!; end
    def uniq_login?; true; end
    def uniq_email?; true; end
    def normalize_identity_url(url); url; end
    def self.find_by_login(login); end
    def self.find(id); new({:id => id});end
    def self.generate_random_password; "rAnD0mZ!"; end
    def accept_terms!; end
    def avatar; FakeAttachment.new; end

    def self.find_by_email_with_aliases(email)
      @@users ||= {}
      @@users[email]
    end
  end

  class FakeRepositoryCommitterships
    def create_for_owner!
    end
  end

  class Repository < TestHelper::Model
    attr_accessor :project, :user, :name, :hooks, :description, :browse_url,
      :clones, :owner, :user_id, :owner_id, :project_id, :parent_id,
      :merge_requests_enabled, :kind, :parent, :content_memberships,
      :full_repository_path, :gitdir, :open_merge_requests, :services,
      :real_gitdir, :disk_usage, :git

    def committerships
      @fake_committerships ||= FakeRepositoryCommitterships.new
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
    def set_repository_path; end
    def open_merge_requests; @open_merge_requests || []; end
    def self.reserved_names; []; end
    def self.private_on_create?(repo); false; end
    def self.find_by_path(path);new;end
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
      :home_url, :mailinglist_url, :bugtracker_url, :owner_id, :wiki_enabled,
      :default_merge_request_status_id, :merge_request_statuses

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

    def merge_request_statuses; @merge_request_statuses || []; end
    def wiki_enabled?; self.wiki_enabled; end
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

    def self.ready; []; end
  end

  class Group < TestHelper::Model
    attr_accessor :creator
  end

  class Membership < TestHelper::Model
    attr_accessor :user, :group, :role, :login, :persisted

    def persisted?
      @persisted
    end
  end

  class Message < TestHelper::Model
  end

  class Role
    def self.member; :member; end
    def self.admin; :admin; end
  end

  class WikiRepository
    NAME_SUFFIX = "-gitorious-wiki"
  end

  class Action
    ADD_PROJECT_REPOSITORY = 19
    CLONE_REPOSITORY = 3
  end

  class Service < TestHelper::Model
    attr_accessor :user, :repository, :service_type, :adapter,
      :successful_request_count, :failed_request_count, :last_response

    class WebHook < TestHelper::Model
      attr_accessor :url
    end
  end

  class Committership < TestHelper::Model
    attr_accessor :repository
  end

  class Comment < TestHelper::Model
    attr_accessor :user, :body, :created_at, :first_line_number,
      :last_line_number, :context, :path, :sha1, :target,
      :user_id, :project_id, :state_changed_from, :state_changed_to

    def applies_to_line_numbers?; false; end
    def editable_until; Time.now + 3600; end
  end

  class MergeRequestStatus
    def self.open?(*); true; end
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
      def info(message); end
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

  class NilClass
    def blank?; true; end
    def presence; nil; end
  end

  class Array; def blank?; self.count == 0; end; end
  class TrueClass; def blank?; false; end; end
  class FalseClass; def blank?; true; end; end

  class String
    def blank?; self == ""; end

    def presence
      if blank?
        nil
      else
        self
      end
    end

    def constantize
      self.split("::").inject(Object) do |mod, name|
        mod.const_get(name)
      end
    end

    def underscore
      self.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    def force_utf8
      self
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

  module ActiveRecord
    class RecordInvalid
    end
  end
end

class MessageHub
  attr_reader :messages
  def publish(queue, message)
    @messages ||= []
    @messages << { :queue => queue, :message => message }
  end
end

class DoltApp
  def call(env)
    env["dolt"] = { :repository => "gitorious/gitorious" }
    [200, {}, []]
  end
end

class NonDoltApp
  def call(env)
    [200, {"Cache-Control" => "max-age=315360000, public"}, []]
  end
end
