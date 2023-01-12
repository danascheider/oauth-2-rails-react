# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  describe 'validations' do
    subject(:token) { build(:access_token) }

    it 'is invalid without an access token' do
      token.access_token = nil
      token.validate
      expect(token.errors[:access_token]).to include "can't be blank"
    end

    it 'is invalid with a duplicate access token' do
      create(:access_token, access_token: 'foobar')
      token.access_token = 'foobar'
      token.validate
      expect(token.errors[:access_token]).to include 'has already been taken'
    end

    it 'is invalid with no scope' do
      token.scope = nil
      token.validate
      expect(token.errors[:scope]).to include "can't be blank"
    end

    it 'is valid with an empty scope' do
      token.scope = []
      expect(token).to be_valid
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

    it 'is invalid without a user' do
      token.user = nil
      token.validate
      expect(token.errors[:user]).to include "can't be blank"
    end

    it 'is invalid with a duplicate user' do
      create(:access_token, user: 'user')
      token.user = 'user'
      token.validate
      expect(token.errors[:user]).to include 'has already been taken'
    end
  end
end
