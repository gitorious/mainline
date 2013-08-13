class ServicesPresenter
  attr_reader :repository, :services, :view_context, :invalid_service

  def initialize(repository, view_context, invalid_service = nil)
    @repository = repository
    @services = repository.services
    @view_context = view_context
    @invalid_service = invalid_service
  end

  def render
    Service.types.map do |type|
      render_for_type(type)
    end.join.html_safe
  end

  private

  def render_for_type(type)
    service = service_for_form(type)
    locals = { :repository => repository, :params => service.params, :service_url => service_url(type) }

    locals.merge!(:services => services_of_type(type))

    view_context.partial("/services/#{type.service_type}", locals)
  end

  def service_for_form(type)
    return invalid_service if invalid_service_is_of?(type)
    Service.new(:service_type => type.service_type)
  end

  def service_url(type)
    view_context.create_project_repository_services_path(repository.project, repository, type.service_type)
  end

  def services_of_type(type)
    services.select{|s| s.service_type == type.service_type }.map {|s| ServiceStatsPresenter.new(s) }
  end

  def invalid_service_is_of?(type)
    invalid_service && invalid_service.service_type == type.service_type
  end
end
