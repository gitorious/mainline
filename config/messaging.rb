#
# Add your destination definitions here
# can also be used to configure filters, and processor groups
#
ActiveMessaging::Gateway.define do |s|
  #s.destination :orders, '/queue/Orders'
  #s.filter :some_filter, :only=>:orders
  #s.processor_group :group1, :order_processor
  
  s.destination :create_repo, '/queue/GitoriousRepositoryCreation'
  s.destination :destroy_repo, '/queue/GitoriousRepositoryDeletion'
  s.destination :push_event, '/queue/GitoriousPushEvent'
  s.destination :ssh_key_generation, '/queue/GitoriousSshKeys'
  s.destination :archive_repo, '/queue/GitoriousRepositoryArchiving'
  s.destination :cc_message, '/queue/GitoriousEmailNotifications'
  s.destination :mirror_merge_request, '/queue/GitoriousMergeRequestCreation'
  s.destination :merge_request_backend_updates, '/queue/GitoriousMergeRequestBackend'
  s.destination :merge_request_version_deletion, '/queue/GitoriousMergeRequestVersionDeletion'
  s.destination :web_hook_notifications, '/queue/GitoriousPostReceiveWebHook'
end
