module MessagesHelper
  def link_to_notifiable(a_notifiable)
    case a_notifiable
    when MergeRequest
      link_to("a merge request", [a_notifiable.target_repository.project, a_notifiable.target_repository, a_notifiable], :class => "merge_request")
    else
    end
  end
end
