class Array
  def to_sentence(options={})
    super({:skip_last_comma => true}.merge(options))
  end
end