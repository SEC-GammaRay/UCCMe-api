# frozen_string_literal: true

# frozen_string_literal

def require_app(folders = %w[models controllers])
  app_list = Array(folders).map { |folder| "app/#{folder}" }
  full_list = ['config', app_list].flatten.join(',')

  Dir.glob("./{#{full_list}}/**/*.rb").each do |file|
    require file
  end
end
