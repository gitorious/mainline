class Service::Adapter
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :data

  def initialize(data)
    @data = data.presence || {}
  end

  def self.service_type
    name.split(':').last.underscore
  end
end
