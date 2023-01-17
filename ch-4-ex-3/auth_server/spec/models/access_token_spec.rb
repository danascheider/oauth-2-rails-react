# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  describe 'validations' do
    subject(:access_token) { build(:access_token) }

    it 'is invalid without a token' do
      access_token.token = nil
      access_token.validate
      expect(access_token.errors[:token]).to include "can't be blank"
    end

    it 'is invalid with a duplicate token' do
      create(:access_token, token: 'foobar')
      access_token.token = 'foobar'
      access_token.validate
      expect(access_token.errors[:token]).to include 'has already been taken'
    end

    it 'is invalid without a token type' do
      access_token.token_type = nil
      access_token.validate
      expect(access_token.errors[:token_type]).to include "can't be blank"
    end

    it 'is invalid with an invalid token type' do
      access_token.token_type = 'invalid'
      access_token.validate
      expect(access_token.errors[:token_type]).to include 'is not included in the list'
    end

    it 'is invalid without a scope' do
      access_token.scope = nil
      access_token.validate
      expect(access_token.errors[:scope]).to include "can't be blank"
    end

    it 'is allowed to have an empty scope' do
      access_token.scope = []
      expect(access_token).to be_valid
    end

    it 'is invalid without an expiration time' do
      access_token.expires_at = nil
      access_token.validate
      expect(access_token.errors[:expires_at]).to include "can't be blank"
    end
  end

  it 'can be saved without a user' do
    expect { create(:access_token, user: nil) }.not_to raise_error
  end
end
