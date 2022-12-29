module MultiSenderSmtpPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        # alias_method :start_smtp_session_without_patch, :start_smtp_session
        # alias_method :start_smtp_session, :start_smtp_session_with_patch
        alias_method :deliver_without_patch, :deliver!
        alias_method :deliver!, :deliver_with_patch
      end
    end

    module InstanceMethods

      def start_smtp_session_with_patch(&block)
        smtp = Net::SMTP.new(settings[:address], settings[:port])
        smtp.enable_starttls_auto
        smtp.start(settings[:domain], settings[:user_name], settings[:password], :xoauth2, &block)
      end

      def deliver_with_patch(mail)
        delivery_response = start_new_smtp_session(mail).start(settings[:domain], settings[:user_name], settings[:password], :xoauth2) do |smtp|
          Mail::SMTPConnection.new(:connection => smtp, :return_response => true).deliver!(mail)
        end

        settings[:return_response] ? delivery_response : self

      end

      def start_new_smtp_session(mail)
        smtp_from, smtp_to, message = Mail::CheckDeliveryParams.check(mail)
        smtp = Net::SMTP.new(settings[:address], settings[:port])
        if settings[:tls] || settings[:ssl]
          if smtp.respond_to?(:enable_tls)
            smtp.enable_tls(ssl_context)
          end
        elsif settings[:enable_starttls_auto]
          if smtp.respond_to?(:enable_starttls_auto)
            smtp.enable_starttls_auto(ssl_context)
          end
        end

        smtp.open_timeout = settings[:open_timeout] if settings[:open_timeout]
        smtp.read_timeout = settings[:read_timeout] if settings[:read_timeout]
        smtp
      end

      def ssl_context
        openssl_verify_mode = settings[:openssl_verify_mode]

        if openssl_verify_mode.kind_of?(String)
          openssl_verify_mode = "OpenSSL::SSL::VERIFY_#{openssl_verify_mode.upcase}".constantize
        end

        context = Net::SMTP.default_ssl_context
        context.verify_mode = openssl_verify_mode
        context.ca_path = settings[:ca_path] if settings[:ca_path]
        context.ca_file = settings[:ca_file] if settings[:ca_file]
        context
      end

  end # module MailerPatch
end # module MultiSender

# Add module to Mailer class
Mail::SMTP.send(:include, MultiSenderSmtpPatch)
