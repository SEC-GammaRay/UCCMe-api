# frozen_string_literal: true

module UCCMe
  # Helper methods for email operations
  module EmailHelper
    TEMPLATE_DIR = File.join(__dir__, 'mail_templates')
    LAYOUT_PATH = File.join(TEMPLATE_DIR, 'layout.erb')
    LOGO_URL = 'https://raw.githubusercontent.com/SEC-GammaRay/UCCMe-api/main/app/services/mail_templates/images/logo.png'

    def self.render(body_name:, variables: {})
      layout = File.read(LAYOUT_PATH)
      body = File.read(File.join(TEMPLATE_DIR, body_name))

      # 加入 layout 預設變數（如 logo_url）
      full_vars = variables.merge('logo_url' => LOGO_URL)

      full_vars.each do |key, value|
        body.gsub!("{{#{key}}}", value)
        layout.gsub!("{{#{key}}}", value)
      end

      layout.gsub('{{email_body}}', body)
    end
  end
end
