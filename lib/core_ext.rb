class Array
  def to_sentence(options={})
    super({:skip_last_comma => true}.merge(options))
  end
end

module Enumerable
  # http://dev.rubyonrails.org/changeset/8516
  def group_by
    inject([]) do |groups, element|
      value = yield(element)
      if (last_group = groups.last) && last_group.first == value
        last_group.last << element
      else
        groups << [value, [element]]
      end
      groups
    end
  end if RUBY_VERSION < '1.9'
end