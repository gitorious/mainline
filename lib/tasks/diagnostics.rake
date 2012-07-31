namespace :diagnostics do

  desc "Check if all diagnostics tests pass (true/false). Note that this has to be run as the same user that usually runs/owns the app (often the 'git' user). Roughly the same as the web page at /admin/diagnostics/summary."
  task :healthy do
    puts `script/runner 'include Gitorious::Diagnostics;puts everything_healthy?'`
  end

  desc "Prints out Gitorious system health summary. Note that this has to be run as the same user that usually runs/owns the app (often the 'git' user). Roughly the same output as the web page at /admin/diagnostics"
  task :summary do
    puts `script/runner 'include Gitorious::Diagnostics;puts health_text_summary'`
  end
end


