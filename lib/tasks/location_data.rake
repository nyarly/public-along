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
          Currency.where(
            name: attrs[:name],
            iso_alpha_code: attrs[:iso_alpha_code]
            ).first_or_create!
        end
      end

      puts "Added #{Currency.count} currencies to database"
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
          Country.where(
            name: attrs[:name],
            iso_alpha_2_code: attrs[:iso_alpha_2_code]
          ).first_or_create!
        end
      end

      puts "Added #{Country.count} countries to database"
    end

    desc 'associate currency with country'
    task :country_currency => :environment do
      ActiveRecord::Base.transaction do
        aus_dollar = Currency.find_by(name: 'Australian Dollar')
        aus = Country.find_by(name: 'Australia')
        aus.currency = aus_dollar
        aus.save!

        puts 'Assigned currency for Australia'

        can_dollar = Currency.find_by(name: 'Canadian Dollar')
        can = Country.find_by(name: 'Canada')
        can.currency = can_dollar
        can.save!

        puts 'Assigned currency for Canada'

        eur = Currency.find_by(name: 'Euro')
        ir = Country.find_by(name: 'Ireland')
        ir.currency = eur
        ir.save!

        puts 'Assigned currency for Ireland'

        ger = Country.find_by(name: 'Germany')
        ger.currency = eur
        ger.save!

        puts 'Assigned currency for Germany'

        gbp = Currency.find_by(name: 'Pound Sterling')
        gb = Country.find_by(name: 'Great Britain')
        gb.currency = gbp
        gb.save!

        puts 'Assigned currency for Great Britain'

        ru = Currency.find_by(name: 'Indian Rupee')
        ind = Country.find_by(name: 'India')
        ind.currency = ru
        ind.save!

        puts 'Assigned currency for India'

        yen = Currency.find_by(name: 'Japanese Yen')
        jp = Country.find_by(name: 'Japan')
        jp.currency = yen
        jp.save!

        puts 'Assigned currency for Japan'

        peso = Currency.find_by(name: 'Mexican Peso')
        mex = Country.find_by(name: 'Mexico')
        mex.currency = peso
        mex.save!

        puts 'Assigned currency for Mexico'

        dollar = Currency.find_by(name: 'United States Dollar')
        us = Country.find_by(name: 'United States')
        us.currency = dollar
        us.save!

        puts 'Assigned currency for United States'
      end
    end

    desc 'create address record for location and assign country'
    task :location_address => :environment do
      ActiveRecord::Base.transaction do
        Location.all.each do |location|
          country_code = location.country
          std_country = Country.find_by(iso_alpha_2_code: country_code)

          if location.country.present? && std_country.present?
            location.build_address(
              country: std_country
            ).save!

            puts "Built address for #{location.name}"
          end
        end
      end
    end

    desc 'create address records for workers with address'
    task :worker_addresses => :environment do
      ActiveRecord::Base.transaction do
        Employee.all.each do |employee|
          if employee.del_home_address_1.present?
            line_1 = employee.del_home_address_1
            line_2 = employee.del_home_address_2
            city = employee.del_home_city
            state = employee.del_home_state
            zip = employee.del_home_zip

            employee.addresses.build(
              line_1: line_1,
              line_2: line_2,
              city: city,
              state_territory: state,
              postal_code: zip
            ).save!

            puts "Built address for #{employee.cn}"
          end
        end
      end
    end
  end
end
