# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test AuthenticateAccount service' do
  before do
    DatabaseHelper.wipe_database

    DATA[:accounts].each do |account_data|
      UCCMe::Account.create(account_data)
    end
  end

  it 'HAPPY: should authenticate with valid account credentials' do
    credentials = DATA[:accounts].first
    account = UCCMe::AuthenticateAccount.call(
      username: credentials['username'],
      password: credentials['password']
    )

    _(account).wont_be_nil
  end

  it 'SAD: will not authenticate with invalid password' do
    credentials = DATA[:accounts].first
    _(proc {
      UCCMe::AuthenticateAccount.call(
        username: credentials['username'],
        password: 'wrongpassword'
      )
    }).must_raise UCCMe::AuthenticateAccount::UnauthorizedError
  end

  it 'BAD: will not authenticate with invalid credentials' do
    _(proc {
      UCCMe::AuthenticateAccount.call(
        username: 'nonexistentuser',
        password: 'wrongpassword'
      )
    }).must_raise UCCMe::AuthenticateAccount::UnauthorizedError
  end
end
