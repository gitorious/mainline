class ServicesPresenter
  attr_reader :repository, :services, :view_context

  def initialize(repository, view_context)
    @repository = repository
    @services = repository._services
    @view_context = view_context
  end

  def render
    Service.types.map do |type|
      render_for_type(type)
    end.join.html_safe
  end

  def render_for_type(type)
    service = Service.new(:service_type => type.service_type)
    locals = { :repository => repository, :params => service.params, :service_url => service_url(type) }

    if type.multiple?
      locals.merge!(:services => services_of_type(type))
    end

    view_context.partial("/services/#{type.service_type}", locals)
  end

  def service_url(type)
    view_context.create_project_repository_services_path(repository.project, repository, type.service_type)
  end

  def services_of_type(type)
    services.select{|s| s.service_type == type.service_type }.map(&:decorated)
  end
end
