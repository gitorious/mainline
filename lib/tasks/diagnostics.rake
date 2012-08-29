namespace :diagnostics do
  # Diagnostics: get either simple binary answer, or a summary of Gitorious
  # installation. Must be launched with superuser privelieges(sudo)

  # EXAMPLE:
  # sudo bundle exec rake diagnostics:summary RAILS_ENV=production

  def exit_if_nonsudo
    if Process.uid != 0
      puts "Please run the task as sudo!"
      exit
    end
  end

  desc "Check if all diagnostics tests pass (true/false). Roughly the same as the web page at /admin/diagnostics/summary."
  task :healthy do
    exit_if_nonsudo
    puts `script/runner 'include Gitorious::Diagnostics;puts everything_healthy?'`
  end

  desc "Prints out Gitorious system health summary. Roughly the same output as the web page at /admin/diagnostics"
  task :summary do
    exit_if_nonsudo
    puts `script/runner 'include Gitorious::Diagnostics;puts health_text_summary'`
  end
end





