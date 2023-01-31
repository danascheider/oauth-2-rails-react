# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshToken, type: :model do
  describe 'validations' do
    subject(:token) { build(:refresh_token) }

    it 'is invalid without a token' do
      token.token = nil
      token.validate
      expect(token.errors[:token]).to include "can't be blank"
    end

    it 'is invalid with a non-unique token' do
      create(:refresh_token, token: 'foo')
      token.token = 'foo'
      token.validate
      expect(token.errors[:token]).to include 'has already been taken'
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
      token.scope = %w[movies animals]
      token.validate
      expect(token.errors[:scope]).to include 'cannot include scopes not available to client'
    end
  end
end
