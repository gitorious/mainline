# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150123100022) do

  create_table "archived_events", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.integer  "action"
    t.string   "data"
    t.text     "body"
    t.integer  "target_id"
    t.string   "target_type"
    t.string   "user_email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cloners", :force => true do |t|
    t.string   "ip"
    t.string   "country_code"
    t.string   "country"
    t.datetime "date"
    t.integer  "repository_id"
    t.string   "protocol"
  end

  add_index "cloners", ["date"], :name => "index_cloners_on_date"
  add_index "cloners", ["ip"], :name => "index_cloners_on_ip"
  add_index "cloners", ["repository_id"], :name => "index_cloners_on_repository_id"

  create_table "comments", :force => true do |t|
    t.integer  "user_id",                             :null => false
    t.integer  "target_id",                           :null => false
    t.string   "sha1"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.string   "target_type"
    t.string   "state_change"
    t.string   "path"
    t.string   "first_line_number"
    t.integer  "number_of_lines"
    t.text     "context"
    t.string   "last_line_number"
    t.boolean  "editable",          :default => true
  end

  add_index "comments", ["project_id"], :name => "index_comments_on_project_id"
  add_index "comments", ["sha1"], :name => "index_comments_on_sha1"
  add_index "comments", ["target_id", "target_type"], :name => "index_comments_on_target_id_and_target_type"
  add_index "comments", ["target_id"], :name => "index_comments_on_repository_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "committerships", :force => true do |t|
    t.integer  "committer_id"
    t.integer  "repository_id"
    t.integer  "kind",           :default => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "committer_type",                :null => false
    t.integer  "creator_id"
    t.integer  "permissions"
  end

  add_index "committerships", ["committer_id", "committer_type"], :name => "index_committerships_on_committer_id_and_committer_type"
  add_index "committerships", ["committer_id"], :name => "index_permissions_on_user_id"
  add_index "committerships", ["repository_id"], :name => "index_committerships_on_repository_id"
  add_index "committerships", ["repository_id"], :name => "index_permissions_on_repository_id"

  create_table "content_memberships", :force => true do |t|
    t.integer  "content_id"
    t.string   "member_type"
    t.integer  "member_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "content_type"
  end

  add_index "content_memberships", ["content_id", "member_id", "member_type"], :name => "content_memberships_index"

  create_table "emails", :force => true do |t|
    t.integer  "user_id"
    t.string   "address"
    t.string   "aasm_state"
    t.string   "confirmation_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "emails", ["address"], :name => "index_emails_on_address"
  add_index "emails", ["user_id"], :name => "index_emails_on_user_id"

  create_table "events", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id",  :null => false
    t.integer  "action",      :null => false
    t.string   "data"
    t.text     "body"
    t.integer  "target_id"
    t.string   "target_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "user_email"
  end

  add_index "events", ["action"], :name => "index_events_on_action"
  add_index "events", ["created_at", "project_id"], :name => "index_events_on_created_at_and_project_id"
  add_index "events", ["created_at"], :name => "index_events_on_created_at"
  add_index "events", ["project_id"], :name => "index_events_on_project_id"
  add_index "events", ["target_type", "target_id"], :name => "index_events_on_target_type_and_target_id"
  add_index "events", ["user_id"], :name => "index_events_on_user_id"

  create_table "favorites", :force => true do |t|
    t.integer  "user_id"
    t.string   "watchable_type"
    t.integer  "watchable_id"
    t.string   "action"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notify_by_email", :default => false
  end

  add_index "favorites", ["watchable_type", "watchable_id", "user_id"], :name => "index_favorites_on_watchable_type_and_watchable_id_and_user_id"

  create_table "feed_items", :force => true do |t|
    t.integer  "event_id"
    t.integer  "watcher_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feed_items", ["event_id"], :name => "index_feed_items_on_event_id"
  add_index "feed_items", ["watcher_id", "created_at"], :name => "index_feed_items_on_watcher_id_and_created_at"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
  end

  add_index "groups", ["name"], :name => "index_groups_on_name_and_public"
  add_index "groups", ["user_id"], :name => "index_groups_on_user_id"

  create_table "issues_comments", :force => true do |t|
    t.integer  "issue_id",   :null => false
    t.integer  "user_id",    :null => false
    t.text     "body",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "issues_comments", ["issue_id"], :name => "index_issues_comments_on_issue_id"

  create_table "issues_issue_labels", :force => true do |t|
    t.integer  "issue_id"
    t.integer  "label_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "issues_issue_labels", ["issue_id", "label_id"], :name => "index_issues_issue_labels_on_issue_id_and_label_id", :unique => true
  add_index "issues_issue_labels", ["issue_id"], :name => "index_issues_issue_labels_on_issue_id"

  create_table "issues_issue_users", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "issue_id",   :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "issues_issue_users", ["issue_id"], :name => "index_issues_issue_users_on_issue_id"
  add_index "issues_issue_users", ["user_id", "issue_id"], :name => "index_issues_issue_users_on_user_id_and_issue_id", :unique => true

  create_table "issues_issues", :force => true do |t|
    t.string   "state",                       :null => false
    t.integer  "issue_id",                    :null => false
    t.integer  "project_id",                  :null => false
    t.integer  "user_id",                     :null => false
    t.string   "title",                       :null => false
    t.text     "description"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "milestone_id"
    t.integer  "priority",     :default => 0, :null => false
  end

  add_index "issues_issues", ["issue_id", "project_id"], :name => "index_issues_issues_on_issue_id_and_project_id", :unique => true
  add_index "issues_issues", ["milestone_id"], :name => "index_issues_issues_on_milestone_id"
  add_index "issues_issues", ["user_id", "project_id"], :name => "index_issues_issues_on_user_id_and_project_id"

  create_table "issues_labels", :force => true do |t|
    t.integer  "project_id", :null => false
    t.string   "name",       :null => false
    t.string   "color",      :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "issues_labels", ["project_id", "name"], :name => "index_issues_labels_on_project_id_and_name", :unique => true
  add_index "issues_labels", ["project_id"], :name => "index_issues_labels_on_project_id"

  create_table "issues_milestones", :force => true do |t|
    t.integer  "project_id",  :null => false
    t.string   "name",        :null => false
    t.text     "description"
    t.date     "due_date"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "issues_milestones", ["project_id"], :name => "index_issues_milestones_on_project_id"

  create_table "issues_queries", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.integer  "project_id",                    :null => false
    t.string   "name",                          :null => false
    t.text     "data",                          :null => false
    t.boolean  "public",     :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "issues_queries", ["project_id"], :name => "index_issues_queries_on_project_id"
  add_index "issues_queries", ["user_id", "project_id", "public"], :name => "index_issues_queries_on_user_id_and_project_id_and_public"
  add_index "issues_queries", ["user_id", "project_id"], :name => "index_issues_queries_on_user_id_and_project_id"

  create_table "ldap_groups", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.text     "description"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.string   "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.text     "member_dns"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "memberships", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "memberships", ["group_id", "user_id"], :name => "index_memberships_on_group_id_and_user_id"

  create_table "merge_request_statuses", :force => true do |t|
    t.integer  "project_id"
    t.string   "name"
    t.string   "color"
    t.integer  "state"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "default",     :default => false
  end

  add_index "merge_request_statuses", ["project_id", "name"], :name => "index_merge_request_statuses_on_project_id_and_name"
  add_index "merge_request_statuses", ["project_id"], :name => "index_merge_request_statuses_on_project_id"

  create_table "merge_request_versions", :force => true do |t|
    t.integer  "merge_request_id"
    t.integer  "version"
    t.string   "merge_base_sha"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "merge_requests", :force => true do |t|
    t.integer  "user_id"
    t.integer  "source_repository_id"
    t.integer  "target_repository_id"
    t.text     "proposal"
    t.string   "sha_snapshot"
    t.integer  "status",                         :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source_branch"
    t.string   "target_branch"
    t.string   "ending_commit"
    t.text     "reason"
    t.string   "oauth_token"
    t.string   "oauth_secret"
    t.string   "contribution_agreement_version"
    t.integer  "updated_by_user_id"
    t.string   "status_tag"
    t.string   "summary",                                           :null => false
    t.boolean  "legacy",                         :default => false
    t.integer  "sequence_number"
  end

  add_index "merge_requests", ["sequence_number", "target_repository_id"], :name => "index_merge_requests_on_sequence_number", :unique => true
  add_index "merge_requests", ["source_repository_id"], :name => "index_merge_requests_on_source_repository_id"
  add_index "merge_requests", ["status"], :name => "index_merge_requests_on_status"
  add_index "merge_requests", ["target_repository_id"], :name => "index_merge_requests_on_target_repository_id"
  add_index "merge_requests", ["user_id"], :name => "index_merge_requests_on_user_id"

  create_table "messages", :force => true do |t|
    t.integer  "sender_id"
    t.string   "subject"
    t.text     "body"
    t.string   "notifiable_type"
    t.integer  "notifiable_id"
    t.integer  "in_reply_to_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "root_message_id"
    t.boolean  "has_unread_replies", :default => false
    t.boolean  "archived_by_sender", :default => false
    t.datetime "last_activity_at"
  end

  add_index "messages", ["in_reply_to_id"], :name => "index_messages_on_in_reply_to_id"
  add_index "messages", ["notifiable_type", "notifiable_id"], :name => "index_messages_on_notifiable_type_and_notifiable_id"
  add_index "messages", ["sender_id"], :name => "index_messages_on_sender_id"

  create_table "messages_users", :force => true do |t|
    t.integer "message_id",                      :null => false
    t.integer "recipient_id",                    :null => false
    t.boolean "read",         :default => false, :null => false
    t.boolean "archived",     :default => false, :null => false
  end

  add_index "messages_users", ["message_id"], :name => "index_messages_users_on_message_id"
  add_index "messages_users", ["recipient_id"], :name => "index_messages_users_on_recipient_id"

  create_table "open_id_authentication_associations", :force => true do |t|
    t.integer "issued"
    t.integer "lifetime"
    t.string  "handle"
    t.string  "assoc_type"
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.integer "timestamp",  :null => false
    t.string  "server_url"
    t.string  "salt",       :null => false
  end

  create_table "project_proposals", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.integer  "owner_id"
    t.string   "owner_type"
    t.boolean  "wiki_enabled",                :default => true
    t.integer  "site_id"
    t.boolean  "merge_requests_need_signoff", :default => false
    t.string   "oauth_signoff_key"
    t.string   "oauth_signoff_secret"
    t.string   "oauth_signoff_site"
    t.string   "oauth_path_prefix"
    t.text     "merge_request_custom_states"
    t.datetime "suspended_at"
    t.string   "features",                    :default => "--- []\n\n", :null => false
  end

  add_index "projects", ["owner_type", "owner_id"], :name => "index_projects_on_owner_type_and_owner_id"
  add_index "projects", ["site_id"], :name => "index_projects_on_site_id"
  add_index "projects", ["slug"], :name => "index_projects_on_slug", :unique => true
  add_index "projects", ["title"], :name => "index_projects_on_name"
  add_index "projects", ["user_id"], :name => "index_projects_on_user_id"

  create_table "repositories", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.boolean  "ready",                                  :default => false
    t.integer  "kind",                                   :default => 0
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "hashed_path"
    t.text     "description"
    t.datetime "last_pushed_at"
    t.integer  "wiki_permissions",                       :default => 0
    t.boolean  "deny_force_pushing",                     :default => false
    t.boolean  "notify_committers_on_new_merge_request", :default => true
    t.datetime "last_gc_at"
    t.boolean  "merge_requests_enabled",                 :default => true
    t.integer  "disk_usage"
    t.integer  "push_count_since_gc"
    t.boolean  "super_group_removed",                    :default => false, :null => false
    t.integer  "last_merge_request_sequence_number",     :default => 0,     :null => false
  end

  add_index "repositories", ["hashed_path"], :name => "index_repositories_on_hashed_path", :unique => true
  add_index "repositories", ["kind"], :name => "index_repositories_on_kind"
  add_index "repositories", ["name"], :name => "index_repositories_on_name"
  add_index "repositories", ["owner_type", "owner_id"], :name => "index_repositories_on_owner_type_and_owner_id"
  add_index "repositories", ["parent_id"], :name => "index_repositories_on_parent_id"
  add_index "repositories", ["project_id", "kind"], :name => "index_repositories_on_project_id_and_kind"
  add_index "repositories", ["project_id"], :name => "index_repositories_on_project_id"
  add_index "repositories", ["ready"], :name => "index_repositories_on_ready"
  add_index "repositories", ["user_id"], :name => "index_repositories_on_user_id"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "kind"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", :force => true do |t|
    t.integer  "user_id"
    t.integer  "repository_id"
    t.string   "last_response"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "failed_request_count",     :default => 0
    t.integer  "successful_request_count", :default => 0
    t.string   "service_type",             :default => "web_hook", :null => false
    t.text     "data",                                             :null => false
  end

  add_index "services", ["repository_id"], :name => "index_hooks_on_repository_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "sites", :force => true do |t|
    t.string   "title"
    t.string   "subdomain"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "wiki_git_path"
  end

  add_index "sites", ["subdomain"], :name => "index_sites_on_subdomain"

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
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], :name => "taggings_idx", :unique => true
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string  "name"
    t.integer "taggings_count", :default => 0
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "login",                                                           :null => false
    t.string   "email"
    t.string   "crypted_password",               :limit => 40
    t.string   "salt",                           :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",                :limit => 40
    t.datetime "activated_at"
    t.integer  "ssh_key_id"
    t.string   "fullname"
    t.text     "url"
    t.text     "identity_url"
    t.boolean  "is_admin",                                     :default => false
    t.datetime "suspended_at"
    t.string   "aasm_state"
    t.boolean  "public_email",                                 :default => true
    t.boolean  "wants_email_notifications",                    :default => true
    t.string   "password_key"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.boolean  "default_favorite_notifications",               :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["login"], :name => "index_users_on_login"
  add_index "users", ["password_key"], :name => "index_users_on_password_key"
  add_index "users", ["ssh_key_id"], :name => "index_users_on_ssh_key_id"

end
