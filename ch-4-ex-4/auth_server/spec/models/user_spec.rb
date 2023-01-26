# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    let(:user) { build(:user) }

    it 'is invalid without a sub' do
      user.sub = nil
      user.validate
      expect(user.errors[:sub]).to include "can't be blank"
    end

    it 'is invalid with a non-unique sub' do
      create(:user, sub: 'foo')
      user.sub = 'foo'
      user.validate
      expect(user.errors[:sub]).to include 'has already been taken'
    end

    it 'is invalid without a name' do
      user.name = nil
      user.validate
      expect(user.errors[:name]).to include "can't be blank"
    end

    it 'is invalid without an email' do
      user.email = nil
      user.validate
      expect(user.errors[:email]).to include "can't be blank"
    end

    it 'is invalid with a non-unique email' do
      create(:user, email: 'foo@bar.com')
      user.email = 'foo@bar.com'
      user.validate
      expect(user.errors[:email]).to include 'has already been taken'
    end
  end
end
