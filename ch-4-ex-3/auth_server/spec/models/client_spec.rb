# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'validations' do
    let(:client) { build(:client) }

    it 'is invalid without a client ID' do
      client.client_id = nil
      client.validate
      expect(client.errors[:client_id]).to include "can't be blank"
    end

    it 'is invalid with a duplicate client ID' do
      create(:client, client_id: client.client_id)
      client.validate
      expect(client.errors[:client_id]).to include 'has already been taken'
    end

    it 'is invalid without a client secret' do
      client.client_secret = nil
      client.validate
      expect(client.errors[:client_secret]).to include "can't be blank"
    end

    it 'is invalid without at least one redirect URI' do
      client.redirect_uris = []
      client.validate
      expect(client.errors[:redirect_uris]).to include "can't be blank"
    end

    it 'is invalid with a blank scope' do
      client.scope = nil
      client.validate
      expect(client.errors[:scope]).to include "can't be blank"
    end

    it 'is valid with an empty scope array' do
      client.scope = []
      expect(client).to be_valid
    end
  end
end