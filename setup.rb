Octokit.configure do |c|
  c.access_token = ENV["GITHUB_ACCESS_TOKEN"]
end

Octokit.middleware = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache,
    serializer: Marshal, shared_cache: false, logger: PRDashboard.logger

  builder.use Octokit::Response::RaiseError
  builder.response :logger, PRDashboard.logger
  builder.adapter Faraday.default_adapter
end
