# frozen_string_literal: true

def require_app(folders = %w[lib models services controllers], config: true)
  app_list = Array(folders).map { |folder| "app/#{folder}" }
  app_list = ['config', app_list] if config
  full_list = app_list.flatten.join(',')

  Dir.glob("./{#{full_list}}/**/*.rb").each do |file|
    require file
  end
end
