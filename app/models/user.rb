# frozen_string_literal: true
class User < ApplicationRecord
  has_many :notifications, dependent: :delete_all

  ERRORS = {
    invalid_token: [:personal_access_token, 'is not a valid token for this github user'],
    missing_notifications_scope: [:personal_access_token, 'does not include the notifications scope'],
    missing_read_org_scope: [:personal_access_token, 'does not include the read:org scope'],
    disallowed_tokens: [:personal_access_token, 'is not allowed in this instance'],
    refresh_interval_size: [:refresh_interval, 'must be less than 1 day']
  }.freeze

  validates :github_id,    presence: true, uniqueness: true
  validates :access_token, presence: true, uniqueness: true
  validates :api_key, presence: true, uniqueness: true
  validates :github_login, presence: true
  validates :refresh_interval, numericality: {
    only_integer: true,
    allow_blank: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 86_400_000,
    message: ERRORS[:refresh_interval_size][1]
  }
  validate :personal_access_token_validator

  def refresh_interval=(val)
    val = nil if 0 == val
    super(val)
  end

  # For users who had zero values set before 20170111185505_allow_null_for_last_synced_at_in_users.rb
  # We want their zeros treated like nils
  def refresh_interval
    0 == super ? nil : super
  end

  def self.find_by_auth_hash(auth_hash)
    User.find_by(github_id: auth_hash['uid'])
  end

  def assign_from_auth_hash(auth_hash)
    github_attributes = {
      github_id: auth_hash['uid'],
      github_login: auth_hash['info']['nickname'],
      access_token: auth_hash.dig('credentials', 'token')
    }

    update_attributes(github_attributes)
  end

  def sync_notifications
    download_service.download
    Rails.logger.info("\n\n\033[32m[#{Time.now}] INFO -- #{github_login} synced their notifications\033[0m\n\n")
  end

  def download_service
    @download_service ||= DownloadService.new(self)
  end

  def github_client
    unless defined?(@github_client) && effective_access_token == @github_client.access_token
      @github_client = Octokit::Client.new(access_token: effective_access_token, auto_paginate: true)
    end
    @github_client
  end

  def github_avatar_url
    "#{Octobox.config.github_domain}/#{github_login}.png"
  end

  # Use the greater of the system minimum or the user's setting
  def effective_refresh_interval
    if Octobox.refresh_interval_enabled? && refresh_interval
      [Octobox.config.minimum_refresh_interval * 60_000, refresh_interval].max
    end
  end

  def effective_access_token
    Octobox.personal_access_tokens_enabled? && personal_access_token.present? ? personal_access_token : access_token
  end

  def personal_access_token_validator
    return unless personal_access_token.present?
    unless Octobox.personal_access_tokens_enabled?
      errors.add(*ERRORS[:disallowed_tokens])
      return
    end
    unless Octokit::Client.new.validate_credentials(access_token: effective_access_token)
      errors.add(*ERRORS[:invalid_token])
      return
    end
    unless github_id == github_client.user.id
      errors.add(*ERRORS[:invalid_token])
      return
    end
    unless github_client.scopes.include? 'notifications'
      errors.add(*ERRORS[:missing_notifications_scope])
    end
    if Octobox.restricted_access_enabled? && !github_client.scopes.include?('read:org')
      errors.add(*ERRORS[:missing_read_org_scope])
    end
  end

  def masked_personal_access_token
    personal_access_token.blank? ? '' :
    "#{'*' * 32}#{personal_access_token.slice(-8..-1)}"
  end

  def generate_api_key
      self.api_key = SecureRandom.hex
      self.save
  end
end
