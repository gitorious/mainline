require "test_helper"

class ServicesAdminTest < ActionDispatch::IntegrationTest
  include CapybaraTestCase

  def login_as(name)
    user = users(name)
    visit(new_sessions_path)
    fill_in 'Email or login', :with => user.email
    fill_in 'Password', :with => 'test'
    click_button 'Log in'
  end

  def web_hook(params)
    create_web_hook(params.merge(:repository => @repository))
  end

  setup do
    @user       = users(:johan)
    @repository = repositories(:johans)
    @project    = @repository.project
  end

  context 'saving a web hook' do
    setup do
      login_as(:johan)
      visit project_repository_services_path(@project, @repository)
      click_on 'Web hooks'
    end

    context 'with valid url' do
      should 'save the service and display stats' do
        find('#service_url').set('http://somewhere.test')
        find('#new_web_hook_service input[type=submit]').click

        page.must_have_selector(".service-stats tbody tr", :count => 1)

        find('#service_url').set('http://somewhere-else.test')
        find('#new_web_hook_service input[type=submit]').click

        page.must_have_selector(".service-stats tbody tr", :count => 2)
      end
    end

    context 'with invalid url' do
      should 'display errors' do
        find('#service_url').set('')
        find('#new_web_hook_service input[type=submit]').click
        page.must_have_content("can't be blank")
      end
    end
  end

  context 'deleting a web hook' do
    setup do
      @service = web_hook(:url => 'http://somewhere.test', :user => @user)
      login_as(:johan)
    end

    should 'remove the stats' do
      visit project_repository_services_path(@project, @repository)

      url = project_repository_service_path(@project, @repository, @service)

      click_on 'Web hooks'

      find("a[data-method=delete][href=#{url.inspect}]").click

      refute page.has_selector?('.service-stats')
    end
  end

  should 'not allow access for non-admin users' do
    login_as(:moe)
    visit project_repository_services_path(@project, @repository)
    page.must_have_content("Action requires login")
  end
end
