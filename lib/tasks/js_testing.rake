namespace :test do

  desc "Run all javascript unit tests"
  task :javascripts do
    jar_file = File.join(Rails.root, "test", "javascripts", "JsTestDriver.jar")
    config = File.join(Rails.root, "config","jsTestDriver.conf")
    command_line = "java -jar #{jar_file} --config #{config} --tests all --captureConsole"
    command_line << " --reset" if ENV["RESET"]
    puts `#{command_line}`
  end

  desc "Start the javascript test driver server"
  task :start_server do
    puts `java -jar #{File.join(Rails.root, "test", "javascripts", "JsTestDriver.jar")} --port 4224`
  end
end

