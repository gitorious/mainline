# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  session :session_key => '_ks1_session_id', 
    # TODO: Read from conf file or something
    :secret => "imcerBupbitjahalCauncafiakbyFrecowphoadmodUtNakNipnuepbyRumatmor" 
  include AuthenticatedSystem
end
