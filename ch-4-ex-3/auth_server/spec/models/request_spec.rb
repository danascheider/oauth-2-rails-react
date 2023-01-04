# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request, type: :model do
  describe 'validations' do
    let(:req) { build(:request) }

    it 'is invalid without a reqid' do
      req.reqid = nil
      req.validate
      expect(req.errors[:reqid]).to include "can't be blank"
    end

    it 'is invalid with a duplicate reqid' do
      create(:request, reqid: 'duplicate')
      req.reqid = 'duplicate'
      req.validate
      expect(req.errors[:reqid]).to include 'has already been taken'
    end

    it 'is invalid without a scope' do
      req.scope = nil
      req.validate
      expect(req.errors[:scope]).to include "can't be blank"
    end

    it 'is valid with an empty scope' do
      req.scope = []
      expect(req).to be_valid
    end

    it 'is invalid without a redirect URI' do
      req.redirect_uri = nil
      req.validate
      expect(req.errors[:redirect_uri]).to include "can't be blank"
    end
  end

  describe '#state' do
    let(:req) { create(:request, query: { 'state' => 'foobar' }) }

    it 'returns the state value from the query string' do
      expect(req.state).to eq 'foobar'
    end
  end

  describe '#response_type' do
    let(:req) { create(:request, query: { 'response_type' => 'code' }) }

    it 'returns the response type value from the query string' do
      expect(req.response_type).to eq 'code'
    end
  end
end
