class LogReader
  NUMBER_OF_LINES = 100
  
  def read
    log_file = "#{RAILS_ROOT}/log/#{RAILS_ENV}.log"
    content = ""
    File::Tail::Logfile.tail(log_file, :backward => NUMBER_OF_LINES, :return_if_eof => true) do |line|
      content << line
    end
    content
  end
end
