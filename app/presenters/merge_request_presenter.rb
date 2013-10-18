class MergeRequestPresenter < SimpleDelegator
  attr_reader :view
  private :view

  def initialize(merge_request, view)
    super(merge_request)
    @view = view
  end

  def status_label_tag
    options = { :class => 'label gts-mr-status-label' }
    options.update(:style => status_color_style) if status_color
    view.content_tag(:span, status_string, options)
  end

  private

  def status_color_style
    "background-color: #{status_color}" if status_color
  end

  def status_color
    status_tag.color if status_tag
  end
end
