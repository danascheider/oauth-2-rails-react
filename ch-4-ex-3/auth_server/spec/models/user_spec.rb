require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    let(:user) { build(:user) }

    it 'is invalid without a sub' do
      user.sub = nil
      user.validate
      expect(user.errors[:sub]).to include "can't be blank"
    end

    it 'is invalid with a duplicate sub' do
      create(:user, sub: 'foobar')
      user.sub = 'foobar'
      user.validate
      expect(user.errors[:sub]).to include 'has already been taken'
    end

    it 'is invalid with a duplicate email' do
      create(:user, email: 'foo@bar.com')
      user.email = 'foo@bar.com'
      user.validate
      expect(user.errors[:email]).to include 'has already been taken'
    end

    it 'is valid without an email' do
      user.email = nil
      expect(user).to be_valid
    end

    it 'is invalid with a duplicate username' do
      create(:user, username: 'foobar')
      user.username = 'foobar'
      user.validate
      expect(user.errors[:username]).to include 'has already been taken'
    end

    it 'is valid with no username' do
      user.username = nil
      expect(user).to be_valid
    end
  end
end
