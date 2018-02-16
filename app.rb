require "sinatra/reloader" if development?
require_relative "./pr_dashboard"
require_relative "./setup"

if development?
  Dir["./*.rb"].each do |file|
    next if File.basename(file) == "app.rb"
    also_reload File.expand_path("./#{file}.rb", __dir__)
  end
end


helpers do
  def label(text)
    text = text.downcase

    type =
      case text
      when "approved", "success" then "success"
      when "changes_requested" then "warning"
      when "failure", "error" then "danger"
      else "default"
      end

    %Q{<span class="label label-#{type}">#{text.tr "_", " "}</span>}
  end

  def avatar(user, height: 32)
    %Q{<img src="#{user.avatar_url}" alt="#{user.login}" height="#{height}" class="avatar"/>}
  end

  def link_to(url, content)
    %Q{<a href="#{url}" target="_blank">#{content}</a>}
  end
end

get "/" do
  @repos = PRDashboard.repos

  haml :index
end
