# frozen_string_literal: true

class AccessToken < SharedModel
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'
  belongs_to :user, optional: true

  def expired?
    expires_at < Time.now
  end
end