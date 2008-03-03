# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 21) do

  create_table "comments", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.integer  "repository_id",                 :null => false
    t.string   "sha1",          :default => "", :null => false
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
  end

  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"
  add_index "comments", ["repository_id"], :name => "index_comments_on_repository_id"
  add_index "comments", ["sha1"], :name => "index_comments_on_sha1"
  add_index "comments", ["project_id"], :name => "index_comments_on_project_id"

  create_table "committerships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "repository_id"
    t.integer  "kind",          :default => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "committerships", ["user_id"], :name => "index_permissions_on_user_id"
  add_index "committerships", ["repository_id"], :name => "index_permissions_on_repository_id"

  create_table "merge_requests", :force => true do |t|
    t.integer  "user_id"
    t.integer  "source_repository_id"
    t.integer  "target_repository_id"
    t.text     "proposal"
    t.string   "sha_snapshot"
    t.integer  "status",               :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "merge_requests", ["user_id"], :name => "index_merge_requests_on_user_id"
  add_index "merge_requests", ["source_repository_id"], :name => "index_merge_requests_on_source_repository_id"
  add_index "merge_requests", ["target_repository_id"], :name => "index_merge_requests_on_target_repository_id"
  add_index "merge_requests", ["status"], :name => "index_merge_requests_on_status"

  create_table "projects", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "license"
    t.string   "home_url"
    t.string   "mailinglist_url"
    t.string   "bugtracker_url"
  end

  add_index "projects", ["slug"], :name => "index_projects_on_slug", :unique => true
  add_index "projects", ["title"], :name => "index_projects_on_name"
  add_index "projects", ["user_id"], :name => "index_projects_on_user_id"

  create_table "repositories", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "mainline",   :default => false
    t.integer  "parent_id"
    t.boolean  "ready",      :default => false
  end

  add_index "repositories", ["name"], :name => "index_repositories_on_name"
  add_index "repositories", ["project_id"], :name => "index_repositories_on_project_id"
  add_index "repositories", ["user_id"], :name => "index_repositories_on_user_id"
  add_index "repositories", ["parent_id"], :name => "index_repositories_on_parent_id"
  add_index "repositories", ["ready"], :name => "index_repositories_on_ready"

  create_table "ssh_keys", :force => true do |t|
    t.integer  "user_id"
    t.text     "key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ready",      :default => false
  end

  add_index "ssh_keys", ["user_id"], :name => "index_ssh_keys_on_user_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "tasks", :force => true do |t|
    t.string   "target_class"
    t.string   "command"
    t.text     "arguments"
    t.boolean  "performed",    :default => false
    t.datetime "performed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "target_id"
  end

  add_index "tasks", ["performed"], :name => "index_tasks_on_performed"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.integer  "ssh_key_id"
    t.string   "fullname"
    t.text     "url"
  end

  add_index "users", ["login"], :name => "index_users_on_login"
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["ssh_key_id"], :name => "index_users_on_ssh_key_id"

end
