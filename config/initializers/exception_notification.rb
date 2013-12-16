airbrake_api_key = Gitorious::Configuration.get("airbrake_api_key")
exception_recipients = Gitorious::Configuration.get("exception_recipients")

if airbrake_api_key
  require 'airbrake'

  Airbrake.configure do |config|
    config.api_key = airbrake_api_key
  end

  # Manually register Airbrake's middleware as Rails doesn't initialize any
  # railtie that is registered after the initialization process started.
  Gitorious::Application.config.middleware.insert(0, "Airbrake::UserInformer")
  Gitorious::Application.config.middleware.insert_after(
    "ActionDispatch::DebugExceptions", "Airbrake::Rails::Middleware"
  )

  if Gitorious::Messaging.adapter == "resque"
    require 'resque/failure/multiple'
    require 'resque/failure/airbrake'
    require 'resque/failure/redis'

    Resque::Failure::Airbrake.configure do |config|
      config.api_key = airbrake_api_key
    end

    Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Airbrake]
    Resque::Failure.backend = Resque::Failure::Multiple
  end

elsif exception_recipients.present?
  require "exception_notification"

  Gitorious::Application.config.middleware.use(ExceptionNotification::Rack, {
    :email => {
      :email_prefix => "[Gitorious] ",
      :sender_address => Gitorious.email_sender,
      :exception_recipients => exception_recipients
    }
  })
else
  if Rails.env.production?
    $stderr.puts "WARNING! No value set for exception_recipients in gitorious.yml."
    $stderr.puts "Will not be able to send email regarding unhandled exceptions"
  end
end
