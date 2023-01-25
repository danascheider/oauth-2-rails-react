# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request, type: :model do
  describe 'validations' do
    subject(:request) { build(:request) }

    it 'is invalid without a reqid' do
      request.reqid = nil
      request.validate
      expect(request.errors[:reqid]).to include "can't be blank"
    end

    it 'is invalid with a non-unique reqid' do
      create(:request, reqid: 'foo')
      request.reqid = 'foo'
      request.validate
      expect(request.errors[:reqid]).to include 'has already been taken'
    end

    it 'is invalid with a duplicate state' do
      create(:request, state: 'foo')
      request.state = 'foo'
      request.validate
      expect(request.errors[:state]).to include 'has already been taken'
    end

    it 'is valid without a state' do
      create(:request, state: nil)
      request.state = nil
      expect(request).to be_valid
    end

    it 'is invalid without a scope' do
      request.scope = nil
      request.validate
      expect(request.errors[:scope]).to include "can't be blank"
    end

    it 'is valid with an empty scope' do
      request.scope = []
      expect(request).to be_valid
    end

    it 'is invalid without a redirect URI' do
      request.redirect_uri = nil
      request.validate
      expect(request.errors[:redirect_uri]).to include "can't be blank"
    end
  end
end
