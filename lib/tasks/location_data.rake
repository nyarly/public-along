namespace :db do
  namespace :populate do
    desc 'populate currency table with standard data'
    task :currencies => :environment do
      standard_currencies = [
        { name: 'Australian Dollar', iso_alpha_code: 'AUD' },
        { name: 'Canadian Dollar', iso_alpha_code: 'CAD' },
        { name: 'Euro', iso_alpha_code: 'EUR' },
        { name: 'Pound Sterling', iso_alpha_code: 'GBP' },
        { name: 'Indian Rupee', iso_alpha_code: 'INR' },
        { name: 'Japanese Yen', iso_alpha_code: 'JPY' },
        { name: 'Mexican Peso', iso_alpha_code: 'MXN' },
        { name: 'United States Dollar', iso_alpha_code: 'USD' }
      ]

      ActiveRecord::Base.transaction do
        standard_currencies.each do |attrs|
          currency = Currency.find_or_create_by(
            name: attrs[:name],
            iso_alpha_code: attrs[:iso_alpha_code])
          currency.update_attributes(attrs)
          currency.save!
        end
      end
    end

    desc 'populate countries table with standard data'
    task :countries => :environment do
      standard_countries = [
        { name: 'Australia', iso_alpha_2_code: 'AU' },
        { name: 'Canada', iso_alpha_2_code: 'CA' },
        { name: 'Germany', iso_alpha_2_code: 'DB' },
        { name: 'Great Britain', iso_alpha_2_code: 'GB' },
        { name: 'Ireland', iso_alpha_2_code: 'IE' },
        { name: 'India', iso_alpha_2_code: 'IN' },
        { name: 'Japan', iso_alpha_2_code: 'JP' },
        { name: 'Mexico', iso_alpha_2_code: 'MX' },
        { name: 'United States', iso_alpha_2_code: 'US' }
      ]

      ActiveRecord::Base.transaction do
        standard_countries.each do |attrs|
          country = Country.find_or_create_by(
            name: attrs[:name],
            iso_alpha_2_code: attrs[:iso_alpha_2_code]
          )
          country.update_attributes(attrs)
          country.save!
        end
      end
    end

    desc 'associate currency with country'
    task :country_currency => :environment do
      ActiveRecord::Base.transaction do
        aus_dollar = Currency.find_by(name: 'Australian Dollar')
        aus = Country.find_by(name: 'Australia')
        aus.currency = aus_dollar
        aus.save!

        can_dollar = Currency.find_by(name: 'Canadian Dollar')
        can = Country.find_by(name: 'Canada')
        can.currency = can_dollar
        can.save!

        eur = Currency.find_by(name: 'Euro')
        ir = Country.find_by(name: 'Ireland')
        ir.currency = eur
        ir.save!

        ger = Country.find_by(name: 'Germany')
        ger.currency = eur
        ger.save!

        gbp = Currency.find_by(name: 'Pound Sterling')
        gb = Country.find_by(name: 'Great Britain')
        gb.currency = gbp
        gb.save!

        ru = Currency.find_by(name: 'Indian Rupee')
        ind = Country.find_by(name: 'India')
        ind.currency = ru
        ind.save!

        yen = Currency.find_by(name: 'Japanese Yen')
        jp = Country.find_by(name: 'Japan')
        jp.currency = yen
        jp.save!

        peso = Currency.find_by(name: 'Mexican Peso')
        mex = Country.find_by(name: 'Mexico')
        mex.currency = peso
        mex.save!

        dollar = Currency.find_by(name: 'United States Dollar')
        us = Country.find_by(name: 'United States')
        us.currency = dollar
        us.save!
      end
    end

    desc 'create address record for location and assign country'
    task :location_address => :environment do
      ActiveRecord::Base.transaction do
        Location.find_each do |location|
          country = location.country
          std_country = Country.find_by(iso_alpha_2_code: country)

          if location.country.present? && std_country.present?
            location.build_address(
              country: std_country
            ).save!
          end
        end
      end
    end

    desc 'create address records for workers with address'
    task :worker_addresses => :environment do
      ActiveRecord::Base.transaction do
        Employee.find_each do |employee|
          if employee.home_address_1.present?
            line_1 = employee.home_address_1
            line_2 = employee.home_address_2
            city = employee.home_city
            state = employee.home_state
            zip = employee.home_zip

            employee.addresses.build(
              line_1: line_1,
              line_2: line_2,
              city: city,
              state_territory: state,
              postal_code: zip
            ).save!
          end
        end
      end
    end
  end
end
