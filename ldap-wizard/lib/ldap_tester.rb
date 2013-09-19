class LdapTester
  def initialize(configuration, credentials)
    configuration = configuration
    @authentication = Gitorious::Authentication::LDAPAuthentication.new(configuration.options)
    @credentials = credentials
  end

  def execute
    results = []
    check_credentials(results)
    failed_count = results.count {|k,v| v}
    success_count = results.size - failed_count
    status = {:failed => failed_count, :succeeded => success_count, :details => results}
    status
  end

  def success?
    results = execute
    return results[:details].all? {|result| result.success == :ok}
  end

  def check_credentials(results)
    begin
      success = @authentication.valid_credentials?(@credentials.username, @credentials.password)
      attempted_username = @authentication.build_username(@credentials.username)
      message = "Tried #{attempted_username}"
      message << (@authentication.use_authenticated_bind? ? " using authenticated bind" : " using direct bind")
      results << TestResult.new("Authentication", success ? :ok : :failed, message)
    rescue StandardError => e
      results << TestResult.new("Authentication", :error, "An error occurred: #{e.message}")
    end
  end

  class TestResult
    attr_reader :title, :success, :details
    def initialize(title, success, details)
      @title = title
      @success = success
      @details = details
    end

    def css_class
      case success
      when :ok
        "success"
      when :failed
        "warning"
      when :error
        "error"
      end
    end
  end
end
