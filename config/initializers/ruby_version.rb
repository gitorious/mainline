if !%w[1.8.7 1.9.3 2.0.0].include?(RUBY_VERSION)
  $stderr.puts <<-WARN
######################################################################
#                              WARNING!                              #
######################################################################
#                                                                    #
# Your Ruby version, #{RUBY_VERSION} may not be supported. Gitorious #
# has only been tested with Ruby 1.8.7, 1.9.3, and 2.0.0. Please     #
# consider using one of these officially supported versions. If you  #
# feel that this warning has been issued in error, please let us     #
# know at http://groups.google.com/group/gitorious/                  #
#                                                                    #
# Please note that Ruby 1.9.1 and 1.9.2 should not be used. Upgrade  #
# to 1.9.3 or 2.0.0                                                  #
#                                                                    #
######################################################################
  WARN
end
