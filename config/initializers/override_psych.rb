# If the Psych YAML parser is installed and available, it will conflict with
# the version of ActiveSupport shipping with Gitorious
if defined?(Psych) && defined?(YAML)
  YAML::ENGINE.yamler = 'syck'
end
