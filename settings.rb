require 'uri'
require 'net/http'
require "httparty"
require 'yaml'
require './mail_sender'


class Settings
  MINUTE = 60
  SETTINGS_PATH = "./settings.yml"
  
  def initialize
    minutes = [3,10,50,100,500]
    extra_messages = {}
    @settings = {
      minutes:        (minutes|extra_messages.keys).sort,
      extra_messages: extra_messages,
      pause:           1
    }
    @settings.merge!(get_settings_from_file)
    [:email, :email2sms_email].each do |k|
      @settings.delete(k) unless check_string(@settings[k])
    end
    puts @settings
  end

  def resource
    @settings[:resource]
  end

  def email
    @settings[:email]
  end

  def email2sms_email
    @settings[:email2sms_email]
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

  def check_settings
    err_msg = ""
      err_msg << "Адрес ресурса не задан\n" unless check_string(resource)
      err_msg << "Email для отправки уведомлений некорренктен\n" if email && check_email(email).nil?
      err_msg << "Email для отправки sms-уведомлений некорренктен\n" if email2sms_email && check_email(email2sms_email).nil?
      err_msg << "Не задано ни одного email для отправки уведомлений\n" unless check_string(email) || check_string(email2sms_email)
      puts err_msg unless err_msg.empty?
      err_msg.empty? 
  end

  def check_email(txt)
    txt[/^([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})$/]
  end

  def check_string(txt)
    txt && !txt.empty?
  end

end
