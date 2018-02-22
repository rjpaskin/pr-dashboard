require "logger"
require_relative "./repo"

module PRDashboard
  def self.config
    @config ||= YAML.load_file("config.yml")
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.repos
    config["repos"].map {|name| Repo.new(name) }
  end
end
