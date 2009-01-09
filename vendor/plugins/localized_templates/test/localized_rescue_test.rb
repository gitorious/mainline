require File.dirname(__FILE__) + '/setup'

class LocalizedRescueController < ActionController::Base
  def index
    render_optional_error_file params[:id]
  end
end

class LocalizedRescueTest < Test::Unit::TestCase

  def setup
    @controller = LocalizedRescueController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_render_optional_error_file_without_localization
    I18n.locale = 'en-US'
    get :index, :id => 500

    assert_response 500
    body = File.read("#{FIXTURES_PATH}/public/500.html")
    assert_equal body, @response.body
  end

  def test_render_optional_error_file_with_localization
    I18n.locale = 'en-US' 
    get :index, :id => 404

    assert_response 404
    body = File.read("#{FIXTURES_PATH}/public/en-US/404.html")
    assert_equal body, @response.body

    I18n.locale = 'pt-BR' 
    get :index, :id => 404

    assert_response 404
    body = File.read("#{FIXTURES_PATH}/public/pt-BR/404.html")
    assert_equal body, @response.body
  end

end