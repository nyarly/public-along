class Location < ActiveRecord::Base
  KINDS = ["Office", "Remote Location"]
  STATUS = ["Active", "Inactive"]
  TIMEZONES = [
    "(GMT-12:00) Eniwektok, Kwajalein",
    "(GMT-11:00) Midway Island, Samoa",
    "(GMT-10:00) Hawaii",
    "(GMT-09:00) Alaska",
    "(GMT-08:00) Pacific Time (US & Canada), Tijuana",
    "(GMT-07:00) Arizona",
    "(GMT-07:00) Mountain Time (US & Canada)",
    "(GMT-06:00) Saskatchewan",
    "(GMT-06:00) Mexico City, Tegucigalpa",
    "(GMT-06:00) Central Time (US & Canada)",
    "(GMT-06:00) Central America",
    "(GMT-05:00) Indiana (East)",
    "(GMT-05:00) Bogota, Lima, Quito",
    "(GMT-05:00) Eastern Time (US & Canada)",
    "(GMT-04:30) Caracas",
    "(GMT-04:00) Atlantic Time (Canada)",
    "(GMT-04:00) La Paz",
    "(GMT-03:30) Newfoundland",
    "(GMT-03:00) Buenos Aires, Georgetown",
    "(GMT-03:00) Brasilia",
    "(GMT-02:00) Mid-Atlantic",
    "(GMT-01:00) Azores, Cape Verde Is.",
    "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London",
    "(GMT) Monrovia, Liberia",
    "(GMT) Casablanca, Morocco",
    "(GMT+01:00) Belgrade, Bratislava, Ljubljana, Prague",
    "(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna",
    "(GMT+01:00) West Central Africa",
    "(GMT+01:00) Brussels, Copenhagen, Madrid, Paris",
    "(GMT+01:00) Sarajevo, Skopje, Sofija, Warsaw, Zagreb",
    "(GMT+02:00) Israel",
    "(GMT+02:00) Harare, Pretoria",
    "(GMT+02:00) Cairo",
    "(GMT+02:00) Athens, Istanbul, Minsk",
    "(GMT+02:00) Bucharest",
    "(GMT+02:00) Helsinki, Riga, Tallinn, Vilnius",
    "(GMT+03:00) Nairobi",
    "(GMT+03:00) Baghdad, Kuwait, Riyadh",
    "(GMT+03:00) Moscow, St. Petersburg, Volgograd",
    "(GMT+03:30) Tehran",
    "(GMT+04:00) Abu Dhabi, Muscat",
    "(GMT+04:00) Baku, Tbilisi",
    "(GMT+04:30) Kabul",
    "(GMT+05:00) Ekaterinburg",
    "(GMT+05:00) Islamabad, Karachi, Tashkent",
    "(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi",
    "(GMT+06:00) Colombo",
    "(GMT+06:00) Almaty, Dhaka",
    "(GMT+06:00) Novosibirsk",
    "(GMT+07:00) Bangkok, Hanoi, Jakarta",
    "(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi",
    "(GMT+08:00) Taipei",
    "(GMT+08:00) Perth",
    "(GMT+08:00) Singapore",
    "(GMT+09:00) Osaka, Sapporo, Tokyo",
    "(GMT+09:00) Yakutsk",
    "(GMT+09:00) Seoul",
    "(GMT+09:30) Darwin",
    "(GMT+09:30) Adelaide",
    "(GMT+10:00) Vladivostok",
    "(GMT+10:00) Guam, Port Moresby",
    "(GMT+10:00) Canberra, Melbourne, Sydney",
    "(GMT+10:00) Brisbane",
    "(GMT+10:00) Hobart",
    "(GMT+11:00) Magadan, Soloman Is, New Caledonia",
    "(GMT+12:00) Fiji, Kamchatka, Marshall Is.",
    "(GMT+12:00) Auckland, Wellington",
  ]

  validates :name,
            presence: true
  validates :code,
            presence: true,
            uniqueness: true,
            case_sensitive: false
  validates :kind,
            presence: true,
            inclusion: { in: KINDS + ["Pending Assignment"] }
  validates :status,
            presence: true,
            inclusion: { in: STATUS }
  validates :timezone,
            allow_nil: true,
            inclusion: { in: TIMEZONES + ["Pending Assignment"] }

  has_one :address, as: :addressable
  accepts_nested_attributes_for :address
  has_many :profiles
  has_many :employees, through: :profiles

  scope :name_collection, -> { where(status: 'Active').pluck(:name) }

  define_method :country do
    return nil if address.blank? || address.country.blank?
    address.country.iso_alpha_2_code
  end
end
