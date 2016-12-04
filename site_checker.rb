require 'uri'
require 'net/http'
require "httparty"
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
    @settings = {
      minutes:        (minutes|extra_messages.keys).sort,
      extra_messages: extra_messages,
      pause:           1
    }
    @settings.merge!(get_settings_from_file)
  end

  def resource
    @settings[:resource]
  end

  def minutes
    @settings[:minutes]
  end

  def pause
    @settings[:pause]
  end

  def get_extra_message minute
    @settings[:extra_messages][minute]
  end

  def get_settings_from_file
    stngs = YAML.load_file(SETTINGS_PATH)
    stngs[:minutes] = (stngs[:minutes] | stngs[:extra_messages].keys).sort
    stngs
  rescue Exception => err
    puts "Can't read settings file'#{SETTINGS_PATH}'!\n#{err.backtrace.join("\n")}"
    {}
  end

  def start_monitoring
    if resource && !resource.empty?
      start_checking_loop(resource, pause)
    else
      puts "Адрес ресурса не задан или пустой!"
    end
  end

  def start_checking_loop url_text, pause
    @url_text = url_text
    while true
      if check_site(@url_text)
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
      sleep pause * MINUTE
    end
  end

  def check_site uri
    response = HTTParty.get(uri, :verify => false).code == 200
  rescue
    false
  end

  def update_time
    @available_last_time = Time.now
  end

  def send_message
    if msg = message_text
      MailSender.new.send_mail(@settings[:email], msg)
      puts msg
    end
  end

  def message_text
    if @state
      "Работа ресурса #{@url_text} восстановлена"
    elsif minute_for_alert
      msg = get_extra_message(@last_alert_minutes)
      unless msg
        msg = "Ресурс #{@url_text} недоступен более #{@last_alert_minutes} минут#{'ы' if (@last_alert_minutes % 10 == 1) && (@last_alert_minutes % 100 != 11) }"
        msg << ". Дальнейшие уведомления отключены." if minutes.last == @last_alert_minutes
      end
      msg
    end
  end

  def minute_for_alert
    unavailable_time = (Time.now - @available_last_time).to_i / MINUTE
    alert_minute = minutes.find{|m| @last_alert_minutes < m && unavailable_time >= m}
    @last_alert_minutes = alert_minute if alert_minute
  end
end

SiteChecker.new.start_monitoring