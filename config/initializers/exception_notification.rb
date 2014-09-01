bugsnag_api_key = Gitorious::Configuration.get("bugsnag_api_key")
exception_recipients = Gitorious::Configuration.get("exception_recipients")

if bugsnag_api_key
  Bugsnag.configure do |config|
    config.api_key = bugsnag_api_key
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
