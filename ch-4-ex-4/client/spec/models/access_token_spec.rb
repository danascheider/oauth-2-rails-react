# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  describe 'validations' do
    subject(:access_token) { build(:access_token) }

    it 'is invalid without an access token' do
      access_token.access_token = nil
      access_token.validate
      expect(access_token.errors[:access_token]).to include "can't be blank"
    end

    it 'is invalid with a non-unique access token' do
      create(:access_token, access_token: 'foobar')
      access_token.access_token = 'foobar'
      access_token.validate
      expect(access_token.errors[:access_token]).to include 'has already been taken'
    end

    it 'is invalid with a non-unique refresh token' do
      create(:access_token, refresh_token: 'foobar')
      access_token.refresh_token = 'foobar'
      access_token.validate
      expect(access_token.errors[:refresh_token]).to include 'has already been taken'
    end

    it 'is valid with a null refresh token' do
      access_token.refresh_token = nil
      expect(access_token).to be_valid
    end

    it 'is invalid without a scope' do
      access_token.scope = nil
      access_token.validate
      expect(access_token.errors[:scope]).to include "can't be blank"
    end

    it 'is valid with an empty scope' do
      access_token.scope = []
      expect(access_token).to be_valid
    end

    it 'is invalid without a token type' do
      access_token.token_type = nil
      access_token.validate
      expect(access_token.errors[:token_type]).to include "can't be blank"
    end

    it 'is invalid with an unrecognized token type' do
      access_token.token_type = 'foo'
      access_token.validate
      expect(access_token.errors[:token_type]).to include 'is not included in the list'
    end

    it 'is invalid without a user' do
      access_token.user = nil
      access_token.validate
      expect(access_token.errors[:user]).to include "can't be blank"
    end
  end
end
