class EmailSender
	OFFICE_CLIENT_ID = "1b1efc2e-4972-41a6-8b04-bef2b750a49b"
	OFFICE_CLIENT_SECRET = "p6-8Q~K59DTIb86rhmGPCaNSVcnZ7FYzY8TRGbW5"
	TENANT_ID = "e01c2ead-9e0c-4ba9-abc5-65637df647a9"
	class << self
		def fetch_access_token!(sender_type, scope_type)
    		sender_service_provider = Setting.plugin_redmine_multi_sender["#{sender_type}_service_provider"]
    		return nil unless defined?("fetch_#{sender_service_provider}_token!".to_sym)
    		return send "fetch_#{sender_service_provider}_token!".to_sym, sender_type, scope_type
        end

        def fetch_sender_type(username)
        	sender_type = ''
        	sender_hash = Setting.plugin_redmine_multi_sender
        	sender_keys = sender_hash.keys
        	sender_keys.each do |key|
        		if sender_hash[key].downcase == username.downcase
        			sender_type = key.split('_').first
        			break
        		end
        	end
        end

        def fetch_office365_token!(sender_type, scope_type = 'email')
        	client_id = Setting.plugin_redmine_multi_sender["#{sender_type}_client_id"]
        	client_secret = Setting.plugin_redmine_multi_sender["#{sender_type}_client_secret"]
        	tenant_id = Setting.plugin_redmine_multi_sender["#{sender_type}_tenant_id"]
        	from_email = Setting.plugin_redmine_multi_sender["#{sender_type}_from_email"]
        	password = Setting.plugin_redmine_multi_sender["#{sender_type}_password"]
        	scope = scope_type == 'email' ? "https://outlook.office.com/SMTP.Send" : "https://outlook.office.com/IMAP.AccessAsUser.All"
        	# scope = scope_type == 'email' ? "https://outlook.office.com/SMTP.Send" : "https://outlook.office.com/SMTP.Send"
        	form_params = {:client_id=> client_id, :username => from_email, :password=> password, :scope=>scope, :client_secret=> client_secret, :grant_type=>"password"}
        	uri = URI.parse("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token")
        	https = Net::HTTP.new(uri.host, uri.port)
        	req = Net::HTTP::Post.new(uri)
        	req.set_form_data(form_params)
        	https.use_ssl = true
        	https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        	resp = https.start { |cx| cx.request(req) }
        	res_hash = JSON.parse(resp.body)
        	if res_hash.present? && res_hash['access_token'].present?
        		return res_hash['access_token']
        	end
        	return nil
        # rescue
        # 	return nil
      	end
	end
end