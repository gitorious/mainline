require File.dirname(__FILE__) + '/setup'

class ProjectsController < ActionController::Base
  layout 'default'

  def index
    respond_to do |format|
      format.html {
        #
      }
      format.rss{
        render :layout => false
      }
    end
  end
end

class LocalizedTemplatesTest < Test::Unit::TestCase

  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_render_without_localization
    I18n.locale = 'en-US'
    get :index

    assert_response 200
    assert_equal "<none>\n  none index view\n</none>", @response.body
  end

  def test_render_rss_without_localization
    I18n.locale = 'pt-BR'
    @request.env['CONTENT_TYPE'] = Mime::EXTENSION_LOOKUP['rss'].to_s
    get :index

    assert_response 200
    assert_equal "<none>text</none>\n", @response.body
  end

  def test_render_with_localization
    I18n.locale = 'pt-BR'
    get :index

    assert_response 200
    assert_equal "<pt-BR>\n  pt-BR index view\n</pt-BR>", @response.body
  end

  def test_render_rss_with_localization
    I18n.locale = 'en-US'
    @request.env['CONTENT_TYPE'] = Mime::EXTENSION_LOOKUP['rss'].to_s
    get :index

    assert_response 200
    assert_equal "<en_US>text</en_US>\n", @response.body
  end

end