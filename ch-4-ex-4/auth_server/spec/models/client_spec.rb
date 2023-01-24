# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'validations' do
    subject(:client) { build(:client) }

    it 'is invalid without a client_id' do
      client.client_id = nil
      client.validate
      expect(client.errors[:client_id]).to include "can't be blank"
    end

    it 'is invalid with a duplicate client_id' do
      create(:client, client_id: 'foobar')
      client.client_id = 'foobar'
      client.validate
      expect(client.errors[:client_id]).to include 'has already been taken'
    end

    it 'is invalid without a client secret' do
      client.client_secret = nil
      client.validate
      expect(client.errors[:client_secret]).to include "can't be blank"
    end

    it 'is invalid with a missing scope' do
      client.scope = nil
      client.validate
      expect(client.errors[:scope]).to include "can't be blank"
    end

    it 'is valid with an empty scope' do
      client.scope = []
      expect(client).to be_valid
    end

    it 'is invalid with missing redirect URIs' do
      client.redirect_uris = nil
      client.validate
      expect(client.errors[:redirect_uris]).to include "can't be blank"
    end

    it 'must have at least one redirect URI' do
      client.redirect_uris = []
      client.validate
      expect(client.errors[:redirect_uris]).to include "can't be blank"
    end
  end
end
