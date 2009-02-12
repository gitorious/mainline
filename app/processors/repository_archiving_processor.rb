require "fileutils"

class RepositoryArchivingProcessor < ApplicationProcessor
  subscribes_to :archive_repo

  def on_message(message)
    msg = ActiveSupport::JSON.decode(message)
    
    return if File.exist?(msg["output_path"])
    
    Dir.chdir(msg["full_repository_path"]) do
      case msg["format"]
      when "tar.gz"
        run("git archive --format=tar #{e(msg['commit_sha'])} | gzip > #{e(msg['work_path'])}")
      end
    end
    
    if run_successful?
      FileUtils.mv(msg["work_path"], msg["output_path"])
    end
  end
  
  def run_successful?
    $? && $?.success?
  end
  
  def run(cmd)
    `#{cmd}`
  end
  
  protected
    def e(string)
      string.gsub("'", '').gsub('"', '')
    end
end