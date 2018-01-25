class Address < ActiveRecord::Base
  belongs_to :addressable, polymorphic: true
  belongs_to :country

  def complete_street
    [line_1, line_2, line_3].compact.join(', ')
  end
end
