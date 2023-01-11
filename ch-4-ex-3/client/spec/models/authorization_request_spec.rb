# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationRequest, type: :model do
  describe 'validations' do
    subject(:authorization_request) { build(:authorization_request) }

    it 'is invalid without a state' do
      authorization_request.state = nil
      authorization_request.validate
      expect(authorization_request.errors[:state]).to include "can't be blank"
    end

    it 'is invalid with a duplicate state' do
      create(:authorization_request, state: 'foobar')
      authorization_request.state = 'foobar'
      authorization_request.validate
      expect(authorization_request.errors[:state]).to include 'has already been taken'
    end

    it 'is invalid without a response type' do
      authorization_request.response_type = nil
      authorization_request.validate
      expect(authorization_request.errors[:response_type]).to include "can't be blank"
    end

    it 'is invalid without a redirect URI' do
      authorization_request.redirect_uri = nil
      authorization_request.validate
      expect(authorization_request.errors[:redirect_uri]).to include "can't be blank"
    end
  end
end
