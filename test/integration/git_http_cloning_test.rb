require File.join(File.dirname(__FILE__), "..", "test_helper")

class GitHttpCloningTest < ActionController::IntegrationTest
  context 'Request with git clone' do
    setup {@request_uri = '/johans-project/johansprojectrepos.git/HEAD'}

    should 'set X-Sendfile headers for subdomains allowing HTTP cloning' do
      ['git.gitorious.org','git.gitorious.local','git.foo.com'].each do |host|
        get @request_uri, {}, :host => host
        assert_response :success
        assert_not_nil(headers['X-Sendfile'])
      end
    end
    
    should 'not set X-Sendfile for hosts that do not allow HTTP cloning' do
      ['gitorious.local','foo.local'].each do |host|
        get @request_uri, {}, :host => host
        assert_response 404
        assert_nil(headers['X-Sendfile'])
      end
    end
  end
end
