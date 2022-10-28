# frozen_string_literal: true

require 'cgi'

class Request < ApplicationRecord
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'
  has_one :authorization_code, dependent: :destroy

  validates :reqid, presence: true, uniqueness: true
  validates :redirect_uri, presence: true
  validates :scope, presence: true, unless: :empty_scope?

  def response_type
    query[:response_type]
  end

  private

  def empty_scope?
    scope == []
  end
end
