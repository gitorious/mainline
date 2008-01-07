class RepositoryObserver < ActiveRecord::Observer
  
  def after_create(repository)
    unless repository.parent.blank?
      Mailer.deliver_new_repository_clone(repository)
    end
  end
  
end