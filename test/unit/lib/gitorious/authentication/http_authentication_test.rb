require "test_helper"

class Gitorious::Authentication::HTTPAuthenticationTest < ActiveSupport::TestCase
  def make_credentials(env)
    credentials = Gitorious::Authentication::Credentials.new
    credentials.env = env
    credentials
  end

  context "Authentication (REMOTE_USER)" do
    setup do
      @ssl = Gitorious::Authentication::HTTPAuthentication.new({})
	  @credentials = make_credentials({'REMOTE_USER' => 'moe'})
    end

    should "return the actual user" do
      assert_equal(users(:moe), @ssl.authenticate(@credentials))
    end
  end

  context "Authentication (SSL)" do
    setup do
      @ssl = Gitorious::Authentication::HTTPAuthentication.new({
        'login_variable' => 'SSL_CLIENT_S_DN_Email',
        'login_strip_domain' => true,
      })
	  @credentials = make_credentials({
        'SSL_CLIENT_S_DN_Email' => 'moe@example.com',
      })
    end

    should "return the actual user" do
      assert_equal(users(:moe), @ssl.authenticate(@credentials))
    end
  end

  context "Auto-registration" do
    setup do
      @ssl = Gitorious::Authentication::HTTPAuthentication.new({
          'login_variable' => 'SSL_CLIENT_S_DN_Email',
          'login_strip_domain' => true,
          'login_replace_char' => '',
          'email_domain' => 'example.com',
          'variable_mapping' => {
            'SSL_CLIENT_S_DN_CN' => 'fullname',
            'SSL_CLIENT_S_DN_Email' => 'email',
          },
        })
	  @credentials = make_credentials({
        'SSL_CLIENT_S_DN_CN' => 'John Doe',
        'SSL_CLIENT_S_DN_Email' => 'j.doe@localhost',
      })
    end

    should "create a new user with information from server variables" do
      user = @ssl.authenticate(@credentials)

      assert_equal "jdoe", user.login
      assert_equal "j.doe@example.com", user.email
      assert_equal "John Doe", user.fullname

      assert user.valid?
    end
  end
end
