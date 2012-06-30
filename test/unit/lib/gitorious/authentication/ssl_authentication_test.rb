require "test_helper"

class Gitorious::Authentication::SSLAuthenticationTest < ActiveSupport::TestCase
  def valid_client_credentials(cn, email)
    # construct a simple Rails request.env hash
    env = Hash.new
    env['SSL_CLIENT_S_DN_CN'] = cn
    env['SSL_CLIENT_S_DN_Email'] = email
    # Wrap this in the G::A::Credentials object.
    credentials = Gitorious::Authentication::Credentials.new
    credentials.env = env
    credentials
  end

  context "Authentication" do
    setup do
      @ssl = Gitorious::Authentication::SSLAuthentication.new({})
    end

    should "return the actual user" do
      assert_equal(users(:moe), @ssl.authenticate(valid_client_credentials("moe", "moe@example.com")))
    end
  end

  context "Auto-registration" do
    setup do
      @ssl = Gitorious::Authentication::SSLAuthentication.new({
          "login_field" => "Email",
          "login_strip_domain" => true,
          "login_replace_char" => "",
        })
      @cn = 'John Doe'
      @email = 'j.doe@example.com'
    end

    should "create a new user with information from the SSL client certificate" do
      user = @ssl.authenticate(valid_client_credentials(@cn, @email))

      assert_equal "jdoe", user.login
      assert_equal @email, user.email
      assert_equal @cn, user.fullname

      assert user.valid?
    end
  end
end
