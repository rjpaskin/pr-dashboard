require_relative "./repo"

module PRDashboard
  def self.config
    @config ||= YAML.load_file("config.yml")
  end

  def self.repos
    @repos ||= config["repos"].map {|name| Repo.new(name) }
  end
end
