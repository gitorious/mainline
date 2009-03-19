require File.join(File.dirname(__FILE__), "..", "test_helper")

class GitHttpCloningTest < ActionController::IntegrationTest
  context 'Requesting without git clone' do
#    get '/', :host => 'www.example.org'
  end
  
  context 'Request with git clone' do
    should 'set X-Sendfile headers' do
      get '/johans-project/johansprojectrepos.git/HEAD'
      assert_response :success
      assert_not_nil(headers['X-Sendfile'])
    end
  end
end
