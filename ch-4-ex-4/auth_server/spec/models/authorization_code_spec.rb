# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationCode, type: :model do
  describe 'validations' do
    let(:auth_code) { build(:authorization_code) }

    it 'is invalid without a code' do
      auth_code.code = nil
      auth_code.validate
      expect(auth_code.errors[:code]).to include "can't be blank"
    end

    it 'is invalid with a non-unique code' do
      create(:authorization_code, code: 'foobar')
      auth_code.code = 'foobar'
      auth_code.validate
      expect(auth_code.errors[:code]).to include 'has already been taken'
    end

    it 'is invalid without a scope' do
      auth_code.scope = nil
      auth_code.validate
      expect(auth_code.errors[:scope]).to include "can't be blank"
    end

    it 'is valid with an empty scope' do
      auth_code.scope = []
      expect(auth_code).to be_valid
    end

    it 'is invalid with scopes not available to the client' do
      auth_code.client = create(:client, scope: %w[movies])
      auth_code.scope = %w[movies foods]
      auth_code.validate
      expect(auth_code.errors[:scope]).to include "can't include scopes not available to associated client"
    end
  end
end
