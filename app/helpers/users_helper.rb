module UsersHelper
  def encoded_mail_to(email)
    mail_to(email, nil, :replace_at => "AT@NOSPAM@", 
      :replace_dot => "DOT", :encode => "javascript")
  end
end