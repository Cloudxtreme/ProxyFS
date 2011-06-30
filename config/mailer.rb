
require "action_mailer"

class ActionMailer::Base
  def from
    "ProxyFS@no-reply.com"
  end

  def recipients
    "vetter@flakks.com"
  end
end

ActionMailer::Base.template_root = File.dirname(__FILE__)

ActionMailer::Base.sendmail_settings = { 
  :location => "/usr/sbin/sendmail",
  :arguments => "-i -t"
}

ActionMailer::Base.delivery_method = :sendmail

