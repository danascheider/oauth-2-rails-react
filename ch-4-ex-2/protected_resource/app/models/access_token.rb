# frozen_string_literal: true

class AccessToken < SharedModel
  def expired?
    expires_at < Time.now
  end
end