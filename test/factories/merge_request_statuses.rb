Factory.define(:merge_request_status) do |ms|
  ms.name "Open"
  ms.color "#000000"
  ms.state ::MergeRequest::STATUS_OPEN
  ms.association :project
end
