# frozen_string_literal: true

class Request < ApplicationRecord
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  validates :reqid, presence: true, uniqueness: true
  validates :scope, presence: true, unless: :empty_scope?
  validates :redirect_uri, presence: true

  def state
    query['state']
  end

  private

  def empty_scope?
    scope == []
  end
end
