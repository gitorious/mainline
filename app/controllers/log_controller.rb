class LogController < ApplicationController
  def index
    @log = LogReader.new.read
  end
end