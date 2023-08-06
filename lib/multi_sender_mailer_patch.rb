module MultiSenderMailerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    
    base.class_eval do
      alias_method :mail_without_helpdesk, :mail
      alias_method :mail, :mail_with_helpdesk
    end
  end

  module InstanceMethods

    def mail_with_helpdesk(headers={}, &block)

      container = @issue || @news || @wiki_content || @message || @document || @attachments.try(:first)
      project = container.try(:project)
      Rails.logger.info "Container #{container.class} - #{container.id} project #{project.id} - #{project.name} "
      sender_name = Setting.plugin_redmine_multi_sender["custom_field_name"]
      email_sender = "default"
      sender_custom_field = CustomField.where(type: "ProjectCustomField", name: sender_name).first
      if project.present? && sender_custom_field.present? && project.custom_field_value(sender_custom_field).present?
         email_sender = project.custom_field_value(sender_custom_field)
      end
      Rails.logger.info "email_sender_name #{email_sender} Container #{container.class} - #{container.id} project #{project.id} - #{project.name} "
      user_name = Setting.plugin_redmine_multi_sender["#{email_sender}_from_email"]
      smtp_api_access_token =  EmailSender.fetch_access_token!(email_sender, 'email')
      domain = Setting.plugin_redmine_multi_sender["#{email_sender}_domain"]
      host = Setting.plugin_redmine_multi_sender["#{email_sender}_host"]
      port = Setting.plugin_redmine_multi_sender["#{email_sender}_port"]
      from_email = Setting.plugin_redmine_multi_sender["#{email_sender}_sender_email"]
      # if access_token.present?
      delivery_options = { user_name: user_name,
                       password: smtp_api_access_token,
                       domain: domain,
                       address: host,
                       authentication: :xoauth2,
                       port: port }
      Setting.mail_from = from_email.present? ? from_email : user_name
      self.smtp_settings.merge!(delivery_options)
      # end
      mail_without_helpdesk(headers, &block)
    end      
  end # module InstanceMethods
end # module MultiSenderMailerPatch

# Add module to Mailer class
Mailer.send(:include, MultiSenderMailerPatch)
