Repo = Struct.new(:name) do
  def open_prs
    @open_prs ||= Octokit.pull_requests(name, state: 'open').map do |pr|
      PullRequest.new(pr)
    end
  end
end
