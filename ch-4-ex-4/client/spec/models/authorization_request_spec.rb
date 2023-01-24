# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationRequest, type: :model do
  describe 'validations' do
    subject(:auth_request) { build(:authorization_request) }

    it 'is invalid without a state' do
      auth_request.state = nil
      auth_request.validate
      expect(auth_request.errors[:state]).to include "can't be blank"
    end

    it 'is invalid with a non-unique state' do
      create(:authorization_request, state: 'foo')
      auth_request.state = 'foo'
      auth_request.validate
      expect(auth_request.errors[:state]).to include 'has already been taken'
    end

    it 'is invalid without a response_type' do
      auth_request.response_type = nil
      auth_request.validate
      expect(auth_request.errors[:response_type]).to include "can't be blank"
    end

    it 'is invalid without a redirect_uri' do
      auth_request.redirect_uri = nil
      auth_request.validate
      expect(auth_request.errors[:redirect_uri]).to include "can't be blank"
    end

    describe 'redirect_uri format' do
      it 'is invalid with a redirect_uri that is not a uri' do
        auth_request.redirect_uri = 'good morning'
        auth_request.validate
        expect(auth_request.errors[:redirect_uri]).to include 'must be a valid URI'
      end

      it 'is invalid with special characters in the domain name' do
        auth_request.redirect_uri = 'https://%#*$(!$.com'
        auth_request.validate
        expect(auth_request.errors[:redirect_uri]).to include 'must be a valid URI'
      end

      it 'is valid if the URI has hyphens or underscores' do
        auth_request.redirect_uri = 'http://www.this_is-a_uri.com'
        expect(auth_request).to be_valid
      end

      it 'is valid with a URI ending in a .' do
        auth_request.redirect_uri = 'https://has.subdomains.and.ends.with.dot.com.'
        expect(auth_request).to be_valid
      end

      it 'is valid with a URI ending in a /' do
        auth_request.redirect_uri = 'https://example.com.au/'
        expect(auth_request).to be_valid
      end

      it 'is valid with path extensions' do
        auth_request.redirect_uri = 'https://example.com.au/oauth/callback'
        expect(auth_request).to be_valid
      end

      it 'is valid with no path extensions and a query string' do
        auth_request.redirect_uri = 'https://example.com?foo=bar&baz=qux'
        expect(auth_request).to be_valid
      end

      it 'is valid with path extensions and a query string' do
        auth_request.redirect_uri = 'https://example.com/callback?foo=bar&baz=q%20x'
        expect(auth_request).to be_valid
      end

      it 'is valid with no path extensions or query strings and a search' do
        auth_request.redirect_uri = 'https://example.com#search'
        expect(auth_request).to be_valid
      end

      it 'is valid with path extensions but no query string and a search' do
        auth_request.redirect_uri = 'https://example.com/callback#search'
        expect(auth_request).to be_valid
      end

      it 'is valid with a query string and a search' do
        auth_request.redirect_uri = 'http://example.com?foo=bar&baz=qux#search'
        expect(auth_request).to be_valid
      end

      it 'is valid with path extensions, a query string, and search' do
        auth_request.redirect_uri = 'https://example.com./callback?foo=bar&baz=qux#search'
        expect(auth_request).to be_valid
      end

      it 'is valid with a port specified' do
        auth_request.redirect_uri = 'http://localhost:4003/authorize'
        expect(auth_request).to be_valid
      end

      it 'is invalid if the port is non-numeric' do
        auth_request.redirect_uri = 'http://localhost:abcd/authorize'
        auth_request.validate
        expect(auth_request.errors[:redirect_uri]).to include 'must be a valid URI'
      end
    end
  end
end
