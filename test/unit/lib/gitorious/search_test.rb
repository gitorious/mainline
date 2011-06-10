# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

require "test_helper"
class SearchTest < ActiveSupport::TestCase
  
  context "Using Ultrasphinx" do
    Gitorious::Search.use Gitorious::Search::Ultrasphinx::Adapter

    # A sample indexed model
    class Searchable < ActiveRecord::Base
      include Gitorious::Search
      is_indexed(:fields => {})
    end

    should "call into Ultrasphinx" do
      assert_not_nil Ultrasphinx::MODEL_CONFIGURATION["SearchTest::Searchable"]
    end    
  end

  context "Specifying associations" do
    should "index a single attribute" do
      helper = Gitorious::Search::Ultrasphinx::SearchHelper.new do |h|
        h.index :body
      end
      assert_equal 1, helper.arguments.size
      arg = helper.arguments.first
      assert_equal :fields, arg.method_name
      assert_equal :body, arg.arguments
    end

    should "index by association" do
      helper = Gitorious::Search::Ultrasphinx::SearchHelper.new do |h|
        h.index "user#login", :as => :commented_by
      end

      arg = helper.arguments.first
      assert_equal :include, arg.method_name
      assert_equal({:association_name => "user", :field => "login", :as => "commented_by"}, arg.arguments)
    end

    should "group options" do
      helper = Gitorious::Search::Ultrasphinx::SearchHelper.new do |h|
        h.index :body
        h.index :name
        h.index "user#login", :as => :commented_by
      end

      assert_equal [:body, :name], helper.options[:fields]
      assert_equal [{:association_name => "user", :field => "login", :as => "commented_by"}], helper.options[:include]
    end

    should "support conditions" do
      helper = Gitorious::Search::Ultrasphinx::SearchHelper.new do |h|
        h.conditions "name IS NOT NULL"
      end
      assert_equal "name IS NOT NULL", helper.options[:conditions]
    end

    should "support fields with a custom name" do
      helper = Gitorious::Search::Ultrasphinx::SearchHelper.new do |h|
        h.index :status_tag, :as => "status"
        h.index :name
      end
      assert_equal([{:field => "status_tag", :as => "status"}, :name], helper.options[:fields])
    end

    should "support concatenation" do
      helper = Gitorious::Search::Ultrasphinx::SearchHelper.new do |h|
        h.collect(
          :name, :from => "Tag", :as => "category",
          :using => "LEFT OUTER JOIN taggings on taggings.id=project.id")
      end
      a = helper.options[:concatenate].first
      assert_equal "name", a[:field]
      assert_equal "Tag", a[:class_name]
      assert_equal "category", a[:as]
    end

  end

  context "Calling Ultrasphinx" do
    
    class SampleSearchable < ActiveRecord::Base
      include Gitorious::Search
    end
    
    should "handle a single field" do
      SampleSearchable.expects(:is_indexed_ultrasphinx).with(:fields => [:body])
      SampleSearchable.is_indexed {|s| s.index(:body)}
    end

    should "handle associations" do
      SampleSearchable.expects(:is_indexed_ultrasphinx).with(:include => [{:association_name => "user", :field => "login", :as => "commented_by"}])
      SampleSearchable.is_indexed {|s| s.index("user#login", :as => :commented_by)}
    end

    should "handle both fields and associations" do
      SampleSearchable.expects(:is_indexed_ultrasphinx).with(
        :fields => [:body],
        :include => [
                     {:association_name => "user",
                       :field => "login",
                       :as => "commented_by"}])
      SampleSearchable.is_indexed do |s|
        s.index :body
        s.index "user#login", :as => :commented_by
      end
    end
  end

  context "Solr search helper" do

    class SunspotSearchable
      extend Gitorious::Search::Sunspot::Adapter
    end

    should "index associated fields" do
      SunspotSearchable.expects(:searchable).yields(SunspotSearchable)
      SunspotSearchable.expects(:text).with(:commented_by).yields(SunspotSearchable)
      
      SunspotSearchable.is_indexed do |s|
        s.index "user#login", :as => :commented_by
      end
    end

    should "index a single field" do
      SunspotSearchable.expects(:searchable).yields(SunspotSearchable)
      SunspotSearchable.expects(:text).with(:title)
      
      SunspotSearchable.is_indexed do |s|
        s.index :title
      end
    end
  end
end
