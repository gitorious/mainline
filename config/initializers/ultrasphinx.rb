# Ultrasphinx::Search.query_defaults.merge({
#   "per_page" => 10,
#   "sort_mode" => 'relevance',
#   "weights" => { "title" => 2.0, "name" => 2.0 }
# })

Ultrasphinx::Search.query_defaults = HashWithIndifferentAccess.new({
  :query => nil,
  :page => 1,
  :per_page => 10,
  :sort_by => nil,
  :sort_mode => 'relevance',
  :indexes => [
      Ultrasphinx::MAIN_INDEX, 
      (Ultrasphinx::DELTA_INDEX if Ultrasphinx.delta_index_present?)
    ].compact,
  :weights => { "title" => 3.0, "name" => 2.0 },
  :class_names => [],
  :filters => {},
  :facets => []
})

Ultrasphinx::Search.excerpting_options = HashWithIndifferentAccess.new({
  :before_match => %Q{<strong class="highlight">}, :after_match => "</strong>",
  :chunk_separator => "...",
  :limit => 256,
  :around => 3,
  # Results should respond to one in each group of these, in precedence order, for the 
  # excerpting to fire
  :content_methods => [['title'], ['description', 'stripped_description', 'body']]
})

Ultrasphinx::Search.client_options['ignore_missing_records'] = true
