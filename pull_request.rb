require "delegate"
require "set"

class PullRequest < SimpleDelegator
  alias_method :octokit_pr, :__getobj__

  class Action
    attr_reader :text, :urls, :html_class

    def initialize(text, urls, options = {})
      @text = text
      @urls = Array(urls)
      @html_class = options.fetch(:class, "default")
    end

    def url
      urls.first
    end
  end

  def repo_name
    base.repo.full_name
  end

  def checks
    status.statuses
  end

  def overall_status
    status.state
  end

  def latest_reviews
    @latest_reviews ||= reviews.group_by {|review| review.user.login }.map do |_, user_reviews|
      user_reviews.sort_by(&:submitted_at).last
    end
  end

  def next_action
    if checks_for(:pending).any?
      Action.new "Wait for checks", checks_for(:pending).map(&:target_url)
    elsif checks_for(:failure).any?
      Action.new "Fix issues", checks_for(:failure).map(&:target_url), class: "danger"
    elsif reviews.none?
      Action.new "Add a review", "#{html_url}/files", class: "primary"
    # Assumes users always review latest commit
    # TODO: check if pending reviews have been superceded by approval
    elsif pending_reviews.any? {|review| head.sha != review.commit_id }
      Action.new "Re-review updates", html_url, class: "warning"
    elsif pending_reviews.any?
      Action.new "Address changes", html_url, class: "warning"
    elsif merge_status.nil?
      Action.new "Waiting for merge check", "javascript:window.location.reload()"
    elsif merge_status == false
      Action.new "Resolve merge conflicts", html_url, class: "danger"
    elsif issue_label_names.include?("status: demo")
      Action.new "Do a demo", html_url, class: "primary"
    elsif merged_at.nil?
      Action.new "Merge it!", "#{html_url}#partial-pull-merging", class: "success"
    elsif issue_label_names.include?("rework needed")
      Action.new "Remove rework label", html_url, class: "primary"
    end
  end

  private

  def full_object
    @full_object ||= Octokit.pull_request(repo_name, number)
  end

  def status
    @status ||= Octokit.status(repo_name, head.ref)
  end

  def checks_by_state
    @checks_by_state ||= checks.group_by {|check| check.state.to_sym }
  end

  def checks_for(state)
    return [] unless checks_by_state.key?(state)

    checks_by_state[state].reject {|check| ignore_check?(check) }
  end

  def ignore_check?(check)
    check.context == "codeclimate"
  end

  def reviews
    @reviews ||= Octokit.pull_request_reviews(repo_name, number).reject do |review|
      # Ignore reviews from the submitter of the PR
      user.id == review.user.id
    end
  end

  def pending_reviews
    @pending_reviews ||= latest_reviews.select {|review| review.state == "CHANGES_REQUESTED" }
  end

  def merge_status
    full_object.mergeable
  end

  def issue_numbers
    @issue_numbers ||= body.scan(/connects?\s+#(\d+)/i).flatten
  end

  def issue_label_names
    @issue_label_names ||= issue_numbers.inject(Set.new) do |names, number|
      names + Octokit.labels_for_issue(repo_name, number).map(&:name)
    end
  end
end
