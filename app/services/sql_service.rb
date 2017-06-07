require 'tiny_tds'
require 'connection_pool'

class SqlService
  attr_accessor :results

  def initialize
    @results = []
    @log_connection = log_connection
  end

  def deactivate_all(employee)
    deactivate_charm(employee)
    deactivate_otanywhere(employee)
    deactivate_roms(employee)

    close_pool(@log_connection)
    @results
  end

  def deactivate_charm(employee)
    databases = [{ database: "Admin", host: SECRETS.sql_na_host },
                 { database: "Admin_EU", host: SECRETS.sql_eu_host },
                 { database: "Admin_Asia", host: SECRETS.sql_asia_host }]
    user_account = "opentable.com\\" + employee.email[/[^@]+/]
    proc_name = "dbo.User_ActivationByDomainLogin"
    proc_str = "EXEC #{proc_name} @DomainLogin = '#{user_account}', @Activate = 0"

    databases.each do |db|
      log_str = "EXEC dbo.Log_LogServiceAction @UserAccount = '#{user_account}', @UserActivated = 0, @ProcExecuted = '#{proc_name}', @Server = '#{db[:database]}', @Status = 0"
      connection = connect(db[:host], db[:database])
      deactivate(connection, proc_str, log_str)
      close_connection(connection)
    end
    @results
  end

  def deactivate_otanywhere(employee)
    databases = [{ database: 'OTAnywhere', host: SECRETS.sql_na_host },
                 { database: 'OTAnywhere_EU', host: SECRETS.sql_eu_host },
                 { database: 'OTAnywhere_Asia', host: SECRETS.sql_asia_host }]
    proc_name = "dbo.User_Activation"
    proc_str = "EXEC #{proc_name} @Email = '#{employee.email}', @Activate = 0"

    databases.each do |db|
      log_str = "EXEC dbo.Log_LogServiceAction @UserAccount = '#{employee.email}', @UserActivated = 0, @ProcExecuted = '#{proc_name}', @Server = '#{db[:database]}', @Status = 0"
      connection = connect(db[:host], db[:database])
      deactivate(connection, proc_str, log_str)
      close_connection(connection)
    end
    @results
  end

  def deactivate_roms(employee)
    user_account = "opentable.com\\" + employee.email[/[^@]+/]
    proc_name = "dbo.ROMS_EmployeeActivation"
    proc_str = "EXEC #{proc_name} @EmployeeLoginID = '#{user_account}', @Activate = 0"
    log_str = "EXEC dbo.Log_LogServiceAction @UserAccount = '#{user_account}', @UserActivated = 0, @ProcExecuted = '#{proc_name}', @Server = 'GOD', @Status = 0"
    connection = connect(SECRETS.roms_host, 'GOD')

    deactivate(connection, proc_str, log_str)
    close_connection(connection)
    @results
  end

  private

  def deactivate(connection, data, log)
    send_log(log)

    begin
      deactivation = connection.execute(data)
      deactivation.do
      deactivation_status = deactivation.return_code

      # all sql stored proc success codes return 0
      if deactivation_status == 0
        #update sql server log entry on success
        send_log(log)
      end

      Rails.logger.info "SQL SERVER RETURNED: #{deactivation_status} WITH INFO: #{data}"
      @results << deactivation_status
    rescue => e
      # execeptions push return code -1 for failure
      Rails.logger.error "SQL SERVER ERROR: #{e} WITH INFO: #{data}"
      TechTableMailer.alert_email("ERROR: Could not deactivate #{data} because #{e}").deliver_now
      @results << -1
    end

    @results
  end

  def send_log(data)
    begin
      @pool.with do |conn|
        if conn.active?
          log = conn.execute(data)
          log.do
          log_status = log.return_code
          if log.return_code != 0
            raise "Logger did not register log correctly for unknown reason."
          end
          log_status
        else
          raise "Logger connection is not active."
        end
      end
    rescue => e
      Rails.logger.error "SQL SERVER LOGGING ERROR: #{e}"
      e
    end
  end

  def connect(host, database)
    username = SECRETS.sql_server_user
    password = SECRETS.sql_server_password

    begin
      client = TinyTds::Client.new host: host, username: username, password: password, database: database
      client
    rescue => e
      connection_err = "Could not connect to #{host} on #{database} as user #{username} because #{e}"
      Rails.logger.error "SQL SERVER CONNECTION ERROR: #{connection_err}"
      TechTableMailer.alert_email("ERROR: #{connection_err}").deliver_now
      e
    end
  end

  def log_connection
    @pool = ConnectionPool.new { connect(SECRETS.sql_na_host, "Admin") }
    @pool
  end

  def close_connection(connection)
    if connection && connection.active?
      connection.close
    end
  end

  def close_pool(pool)
    @pool.shutdown { |conn| conn.close }
  end

end
