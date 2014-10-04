site_cookbooks_dir = ::File.join(node[:tabula_rasa][:home_dir], 'site-cookbooks')

directory site_cookbooks_dir do
  action :delete
  recursive true

  only_if do
    ::File.directory?(site_cookbooks_dir)
  end
end

include_recipe "tabula_rasa::prepare_cookbooks"
