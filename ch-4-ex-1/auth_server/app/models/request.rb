# frozen_string_literal: true

require 'cgi'

class Request < ApplicationRecord
  belongs_to :client, foreign_key: 'client_id', primary_key: 'client_id'

  validates :reqid, presence: true, uniqueness: true
  validates :redirect_uri, presence: true
  validates :scope, presence: true, unless: :empty_scope?

  # The query hash will be in the form of `key1=val1&key2=val2&key3=val3&key3=val4`, which will
  # parse to { 'key1' => ['val1'], 'key2' => ['val2'], 'key3' => ['val3', 'val4'] }. We want the
  # values to be in arrays only if there's actually more than one of them for a given key. The
  # final output of this method would then be:
  #   { 'key1' => 'val1', 'key2', => 'val2', 'key3' => ['val3', 'val4'] }
  def query_hash
    CGI.parse(query).map {|key, value| value.length == 1 ? [key, value[0]] : [key, value] }.to_h
  end

  private

  def empty_scope?
    scope == []
  end
end
