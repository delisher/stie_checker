require 'uri'
require 'net/http'
require "httparty"
require './mail_sender'
require './settings'


class SiteChecker
  MINUTE = 60
  SETTINGS_PATH = "./settings.yml"
  attr_reader :settings

  def initialize
    update_time
    @state = true
    @last_alert_minutes = 0
    @settings = Settings.new
  end

  def start_monitoring
    start_checking_loop(settings.resource, settings.pause) if settings.check_settings
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
      MailSender.new.send_mail(settings.email, msg) if settings.email
      MailSender.new.send_mail(settings.email2sms_email, msg) if settings.email2sms_email
      puts msg
    end
  end

  def message_text
    if @state
      "Работа ресурса #{@url_text} восстановлена"
    elsif minute_for_alert
      msg = settings.get_extra_message(@last_alert_minutes)
      unless msg
        msg = "Ресурс #{@url_text} недоступен более #{@last_alert_minutes} минут#{'ы' if (@last_alert_minutes % 10 == 1) && (@last_alert_minutes % 100 != 11) }"
        msg << ". Дальнейшие уведомления отключены." if settings.minutes.last == @last_alert_minutes
      end
      msg
    end
  end

  def minute_for_alert
    unavailable_time = (Time.now - @available_last_time).to_i / MINUTE
    alert_minute = settings.minutes.find{|m| @last_alert_minutes < m && unavailable_time >= m}
    @last_alert_minutes = alert_minute if alert_minute
  end
end

SiteChecker.new.start_monitoring