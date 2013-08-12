class ServiceStatsPresenter
  def initialize(service)
    @service = service
    @params = service.params
  end

  def user
    @service.user
  end

  def runs
    span("gts-pos", @service.successful_request_count) + "/" + span("gts-neg", @service.failed_request_count)
  end

  def last_response
    last_response = @service.last_response
    status_code = last_response.to_i
    successful = (200..299)
    error = (400..599)

    case status_code
    when successful
      strong("gts-pos", last_response)
    when error
      strong("gts-neg", last_response)
    else
      last_response
    end
  end

  def span(klass, content)
    tag("span", klass, content)
  end

  def strong(klass, content)
    tag("strong", klass, content)
  end

  def tag(tag_name, klass, content)
    %Q[<#{tag_name} class="#{klass}">].html_safe + content + "</#{tag_name}>".html_safe
  end

  def method_missing(name, *args, &block)
    @params.send(name, *args, &block)
  end
end
