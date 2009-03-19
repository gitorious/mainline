require File.join(File.dirname(__FILE__), "..", "test_helper")

class GitHttpCloningTest < ActionController::IntegrationTest
  context 'Request with git clone' do
    setup do
      @repository = repositories(:johans)
      @request_uri = '/johans-project/johansprojectrepos.git/HEAD'
    end

    should 'set X-Sendfile headers for subdomains allowing HTTP cloning' do
      ['git.gitorious.org','git.gitorious.local','git.foo.com'].each do |host|
        assert_incremented_by(@repository.cloners, :count, 1) do
          get @request_uri, {}, :host => host, :remote_addr => '192.71.1.2'
          last_cloner = @repository.cloners.last
          assert_equal('192.71.1.2', last_cloner.ip)
          assert_equal('http', last_cloner.protocol)
        end
        assert_response :success
        assert_not_nil(headers['X-Sendfile'])
        assert_equal(File.join(GitoriousConfig['repository_base_path'], @repository.real_gitdir, "HEAD"), headers['X-Sendfile'])
      end
    end
    
    should 'not set X-Sendfile for hosts that do not allow HTTP cloning' do
      ['gitorious.local','foo.local'].each do |host|
        get @request_uri, {}, :host => host
        assert_response :not_found
        assert_nil(headers['X-Sendfile'])
      end
    end
  end
end
