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
      sender_name = Setting.plugin_redmine_multi_sender["custom_field_name"]
      if project.present? && project.custom_field_value(CustomField.find_by_name(sender_name)).present?
         email_sender = project.custom_field_value(CustomField.find_by_name(sender_name))
         Setting.mail_from = Setting.plugin_redmine_multi_sender["#{email_sender}_from_email"]
        delivery_options = { user_name: Setting.plugin_redmine_multi_sender["#{email_sender}_from_email"],
                       password: Setting.plugin_redmine_multi_sender["#{email_sender}_password"],
                       domain: Setting.plugin_redmine_multi_sender["#{email_sender}_domain"],
                       address: Setting.plugin_redmine_multi_sender["#{email_sender}_host"] }
        self.smtp_settings.merge!(delivery_options)
      end
      mail_without_helpdesk(headers, &block)
    end      
  end # module InstanceMethods
end # module MultiSenderMailerPatch

# Add module to Mailer class
Mailer.send(:include, MultiSenderMailerPatch)
