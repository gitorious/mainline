namespace :diagnostics do
  # Diagnostics: get either simple binary answer, or a summary of Gitorious
  # installation. Must be launched with as the gitorious_user (usually 'git')

  # EXAMPLE:
  # su git -c "bundle exec rake diagnostics:summary RAILS_ENV=production"

  desc "Check if all diagnostics tests pass (true/false). Roughly the same as the web page at /admin/diagnostics/summary."
  task :healthy do
    puts `script/runner 'include Gitorious::Diagnostics;puts everything_healthy?'`
  end

  desc "Prints out Gitorious system health summary. Roughly the same output as the web page at /admin/diagnostics"
  task :summary do
    puts `script/runner 'include Gitorious::Diagnostics;puts health_text_summary'`
  end
end





