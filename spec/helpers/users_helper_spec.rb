require File.dirname(__FILE__) + '/../spec_helper'

describe UsersHelper do
  it "should encode email" do
    message = %{
      mail_to_encoded passes :replace_at and :replace_dot
      values to mail_to (a rails helper), which should
      obfuscate the email address, but it apparently does
      NOT do that if :encode => 'javascript'
      
      Need to investigate if this is a Rails bug and
      either fix it there or let go of obfuscation.
    }
    pending(message) do
      email = "aAT@NOSPAM@bDOTcom"
      encoded = (0...email.length).inject("") do |result, index|
        result << sprintf("%%%x",email[index])
      end
      helper.encoded_mail_to("a@b.com").should match(/#{encoded}/)
    end
  end
end
