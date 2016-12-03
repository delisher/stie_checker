require 'uri'
require 'net/http'
require 'yaml'
require './mail_sender'


class SiteChecker
  MINUTE = 60
  SETTINGS_PATH = "./settings.yml"
  
  def initialize
    update_time
    @state = true
    @last_alert_minutes = 0
    minutes = [3,10,50,100,500]
    extra_messages = {}
    @settings ||= {
      minutes:        (minutes|extra_messages.keys).sort,
      extra_messages: extra_messages,
      pause:           1
    }
    @settings.merge!(get_settings_from_file)
    puts @settings
  end

  def get_settings_from_file
    settings = YAML.load_file(SETTINGS_PATH)
    settings[:minutes] = (settings[:minutes] | settings[:extra_messages].keys).sort
    settings
  rescue Exception => err
    puts "Can't read settings file'#{SETTINGS_PATH}'!\n#{err.backtrace.join("\n")}"
    {}
  end

  def check_site uri
    response = Net::HTTP.get_response(uri)
    response.is_a? Net::HTTPSuccess
  rescue Exception => err
    false
  end

  def update_time
    @available_last_time = Time.now
  end

  def minute_for_alert
    unavailable_time = (Time.now - @available_last_time).to_i / MINUTE
    alert_minute = @settings[:minutes].find{|m| @last_alert_minutes < m && unavailable_time >= m}
    @last_alert_minutes = alert_minute if alert_minute
  end

  def message_text
    if @state
      "Работа ресурса #{@url_text} восстановлена"
    elsif minute_for_alert
      msg = @settings[:extra_messages][@last_alert_minutes]
      unless msg
        msg = "Ресурс #{@url_text} недоступен более #{@last_alert_minutes} минут#{'ы' if (@last_alert_minutes % 10 == 1) && (@last_alert_minutes % 100 != 11) }"
        msg << ". Дальнейшие уведомления отключены." if @settings[:minutes].last == @last_alert_minutes
      end
      msg
    end
  end

  def send_message
    if msg = message_text
      MailSender.new.send_mail(@settings[:email], msg)
      puts msg
    end
  end

  def start_checking_loop url_text, pause
    @url_text = url_text
    uri = URI.parse(url_text)
    while true
      if check_site(uri)
        update_time
        unless @state
          @state = true
          send_message
        end
        @last_alert_minutes = 0
      else
        @state = false if @state
        send_message
      end
      sleep @settings[:pause] * MINUTE
    end
  end
end

chkr = SiteChecker.new
chkr.start_checking_loop "http://localhost:3000/", 1