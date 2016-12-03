require 'mail'

class MailSender
  
  def initialize
    Mail.defaults do
      delivery_method :smtp, :address    => "smtp.gmail.com",
                              :port      => 587,
                              :user_name => 'itsjusttestforartec@gmail.com',
                              :password  => '1tsjustt3stforart3c',
                              :domain    => "smtp.gmail.com" ,
                              :authentication => :plain,
                              :enable_starttls_auto => true  
    end
  end
  
  def send_mail(address, text)
    mail = Mail.new do
      from     'ResourceMonitoring'
      to       address
      subject  'Resource MOnitoring'
      body     text
    end

    mail.deliver!
  end
end