# frozen_string_literal: false

module AccessTokens
  module_function

  def populate_access_token(scope = [], expiration = nil)
    create_table
    insert_access_token(scope, expiration)
  end

  def truncate_table
    SharedModel.connected_to(role: :reading) do
      ActiveRecord::Base.connection.execute('TRUNCATE access_tokens')
    end
  end

  def create_table
    query = <<~QUERY
    CREATE TABLE IF NOT EXISTS access_tokens (
      user_id integer,
      client_id varchar,
      token varchar UNIQUE NOT NULL,
      token_type varchar,
      scope varchar[],
      expires_at timestamp,
      created_at timestamp,
      updated_at timestamp
    )
    QUERY

    SharedModel.connected_to(role: :reading) do
      ActiveRecord::Base.connection.execute(query)
    end
  end

  def insert_access_token(scope = [], expires_at = Time.now + 1.minute)
    token = SecureRandom.hex(32)

    scope_str = ''
    scope.each_with_index do |str, index|
      if index == scope.length - 1
        scope_str << "'#{str}'"
      else
        scope_str << "'#{str}', "
      end
    end

    query = <<~QUERY
    INSERT INTO access_tokens (
        user_id,
        client_id,
        token,
        token_type,
        scope,
        expires_at,
        created_at,
        updated_at
      ) VALUES (
      42,
      'oauth-client-1',
      '#{token}',
      'Bearer',
      ARRAY [#{scope_str}],
      '#{expires_at}',
      '#{Time.now}',
      '#{Time.now}'
    )
    QUERY

    SharedModel.connected_to(role: :reading) do
      ActiveRecord::Base.connection.execute(query)
    end
  end

  def database_config
    {
      adapter: 'postgresql',
      encoding: 'unicode',
      pool: 5,
      database: 'protected_resource_test_shared_4_3'
    }
  end
end