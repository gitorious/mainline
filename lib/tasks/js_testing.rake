namespace :test do

  desc "Run all javascript unit tests"
  task :javascripts do
    command_line = "java -jar #{File.join(Rails.root, "test", "javascripts", "JsTestDriver.jar")} --config #{File.join(Rails.root, "config","jsTestDriver.conf")} --tests all"
    puts `#{command_line}`
  end

  desc "Start the javascript test driver server"
  task :start_server do
    puts `java -jar #{File.join(Rails.root, "test", "javascripts", "JsTestDriver.jar")} --port 9876`
  end
end
