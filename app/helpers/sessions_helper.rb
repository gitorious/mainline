module SessionsHelper

  # determines which form to display for login
  def login_method
    if params[:method]=='openid'
      "<script  type=\"text/javascript\"> Event.observe(window, 'load',
      function() {
Element.toggle(\"regular_login_fields\");
Element.toggle(\"openid_login_fields\");
})
    </script>"
    end
  end

  def switch_login(title, action)
    link_to_function title do |page|
      page.toggle "regular_login_fields"
      page.toggle "openid_login_fields"
    end
  end
end
