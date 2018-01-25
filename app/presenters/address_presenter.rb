class AddressPresenter < Presenter
  attr_reader :model

  delegate :line_1,
           :line_2,
           :line_3,
           :city,
           :postal_code,
           :state_territory,
           :country_id,
           to: :model

  def complete_region
    format_address([city, state_territory])
  end

  def country_name
    country.present? ? country.name : nil
  end

  private

  def country
    Country.find(country_id)
  end

  def format_address(items=[])
    items.compact.join(', ')
  end
end
