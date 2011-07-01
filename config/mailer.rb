
require "action_mailer"

ActionMailer::Base.template_root = File.dirname __FILE__

class ActionMailer::Base
  def from
    "ProxyFS@no-reply.com"
  end

  def recipients
    "vetter@flakks.com"
  end
end

ActionMailer::Base.sendmail_settings = { 
  :location => "/usr/sbin/sendmail",
  :arguments => "-i -t"
}

if defined?(PROXYFS_ENV) && PROXYFS_ENV == :test
  ActionMailer::Base.delivery_method = :test
else
  ActionMailer::Base.delivery_method = :sendmail
end

