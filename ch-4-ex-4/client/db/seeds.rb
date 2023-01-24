# frozen_string_literal: true

module Seeds
  module_function

  def seed!
    seed_access_token
  end

  def seed_access_token!
    AccessToken.create!(
      access_token: 'b9e8751afa57554688a147dd589ad5cb7e525ab74e6477c96f116eaf9b920094',
      refresh_token: 'c25da5afe8e67df9d398c0ff080a85b8',
      scope: %w[movies foods music],
      token_type: 'Bearer',
      user: '9XE3-JI34-00132A'
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.full_messages
  end
end

Seeds.seed_access_token!