require_relative '../attribute'
require_relative 'option'

module CollectionJSON
  class Data < Attribute
    attribute :name
    attribute :value
    attribute :prompt
    attribute :options,
              transform:      lambda { |data| data.each.map { |d| Option.from_hash(d) }},
              default:        [],
              find_method:    {method_name: :datum, key: 'name'}
  end
end
