module DataBuilderHelpers
  def create_web_hook(params = {})
    web_hook = build_web_hook(params)
    web_hook.save!
    web_hook
  end

  def build_web_hook(params = {})
    Service.new(:repository => params[:repository],
                :user => params[:user],
                :service_type => Service::WebHook.service_type,
                :data => { :url => params[:url] })
  end
end
