# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationCode, type: :model do
  describe 'validations' do
    let(:authorization_code) { build(:authorization_code) }

    it 'is invalid without a code' do
      authorization_code.code = nil
      authorization_code.validate
      expect(authorization_code.errors[:code]).to include "can't be blank"
    end

    it 'is invalid with a duplicate code' do
      create(:authorization_code, code: 'foo')
      authorization_code.code = 'foo'
      authorization_code.validate
      expect(authorization_code.errors[:code]).to include 'has already been taken'
    end

    it 'is invalid without a scope' do
      authorization_code.scope = nil
      authorization_code.validate
      expect(authorization_code.errors[:scope]).to include "can't be blank"
    end

    it 'is valid with an empty scope' do
      authorization_code.scope = []
      expect(authorization_code).to be_valid
    end
  end
end
