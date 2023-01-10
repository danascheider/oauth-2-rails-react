# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshToken, type: :model do
  describe 'validations' do
    let(:refresh_token) { build(:refresh_token) }

    it 'is invalid without a token' do
      refresh_token.token = nil
      refresh_token.validate
      expect(refresh_token.errors[:token]).to include "can't be blank"
    end

    it 'is invalid with a duplicate token' do
      create(:refresh_token, token: 'foobar')
      refresh_token.token = 'foobar'
      refresh_token.validate
      expect(refresh_token.errors[:token]).to include 'has already been taken'
    end

    it 'is invalid without a scope' do
      refresh_token.scope = nil
      refresh_token.validate
      expect(refresh_token.errors[:scope]).to include "can't be blank"
    end

    it 'is invalid with a non-unique client-user combination' do
      client = create(:client)
      user = create(:user)
      create(:refresh_token, client:, user:)
      refresh_token.client = client
      refresh_token.user = user
      refresh_token.validate
      expect(refresh_token.errors[:user_id]).to include 'must be unique per client'
    end

    it 'is valid with an empty scope' do
      refresh_token.scope = []
      expect(refresh_token).to be_valid
    end
  end

  describe 'scopes' do
    describe '::for_client_and_user' do
      subject(:for_client_and_user) { described_class.for_client_and_user(client:, user:) }

      let!(:refresh_token) { create(:refresh_token, client:, user:) }
      let(:client) { create(:client) }
      let(:user) { create(:user) }

      before do
        # One with same client but different user
        create(:refresh_token, client:)

        # One with same user but different client
        create(:refresh_token, user:)

        # One with different client and user
        create(:refresh_token)
      end

      it 'returns the refresh token for the specified client and user' do
        expect(for_client_and_user).to eq refresh_token
      end
    end
  end
end
