require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  describe 'validations' do
    subject(:token) { build(:access_token) }

    it 'is invalid without a token' do
      token.token = nil
      token.validate
      expect(token.errors[:token]).to include "can't be blank"
    end

    it 'is invalid with a non-unique token' do
      create(:access_token, token: 'foo')
      token.token = 'foo'
      token.validate
      expect(token.errors[:token]).to include 'has already been taken'
    end

    it 'is invalid without a token type' do
      token.token_type = nil
      token.validate
      expect(token.errors[:token_type]).to include "can't be blank"
    end

    it 'is invalid with an invalid token type' do
      token.token_type = 'foo'
      token.validate
      expect(token.errors[:token_type]).to include 'is not included in the list'
    end

    it 'is invalid without a scope' do
      token.scope = nil
      token.validate
      expect(token.errors[:scope]).to include "can't be blank"
    end

    it 'is valid with an empty scope' do
      token.scope = []
      expect(token).to be_valid
    end

    it 'is invalid with scopes unavailable to the client' do
      token.client = create(:client, scope: %w[foods])
      token.scope = %w[foods movies]
      token.validate
      expect(token.errors[:scope]).to include 'cannot include scopes not available to client'
    end

    it 'is invalid without an expiration' do
      token.expires_at = nil
      token.validate
      expect(token.errors[:expires_at]).to include "can't be blank"
    end
  end
end
