require 'uri'
require 'net/http'
require 'yaml'


class SiteChecker
  MINUTE = 60
  
  def initialize
    update_time
    @last_alert_minutes = 0
    minutes = [29,11,47,21,33]
    extra_messages = {14 => "Extra message test!"}
    @settings ||= {
      minutes:        (minutes|extra_messages.keys).sort,
      extra_messages:  extra_messages,
      pause:           MINUTE
    }
  end

  def check_site url_text
    uri = URI.parse(url_text)
    response = Net::HTTP.get_response(uri)
    response.is_a? Net::HTTPSuccess
  rescue Exception => err
    false
  end

  def update_time
    @available_last = Time.now
  end

  def minute_for_alert
    unavailable_time = (Time.now - @available_last).to_i * MINUTE
    alert_minute = @settings[:minutes].find{|m| @last_alert_minutes < m && unavailable_time >= m}
    puts unavailable_time
    @last_alert_minutes = alert_minute if alert_minute
  end

  def send_message
    msg = if minute_for_alert
      @settings[:extra_messages][@last_alert_minutes] ||
      "Сервис недоступен более #{@last_alert_minutes} минут#{'ы' if (@last_alert_minutes % 10 == 1) && (@last_alert_minutes % 100 != 11) }"
    end
    puts msg if msg
  end

  def start_checking_loop url_text, pause
    while true
      if check_site(url_text)
        update_time
        @last_alert_minutes = 0
        puts "Все хорошо"
      else
        send_message
      end
      sleep @settings[:pause]
    end
  end
end

chkr = SiteChecker.new
chkr.start_checking_loop "http://localhost:3000/", 1