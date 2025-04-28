# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test SecureDB class' do
  it 'SECURITY: should encrypt text' do
    test_text = 'test text'
    text_secure = SecureDB.encrypt(test_text)
    _(text_secure).wont_equal test_text
  end

  it 'SECURITY: should decrypt encrypted ASCII' do
    test_text = 'test text ~ 1 & / n'
    text_secure = SecureDB.encrypt(test_text)
    decrypted_text = SecureDB.decrypt(text_secure)
    _(decrypted_text).must_equal test_text
  end

  it 'SECURITY: should decrypt encrypted UTF-8' do
    test_text = ' SEC 是我最喜歡的課'
    text_secure = SecureDB.encrypt(test_text)
    decrypted_text = SecureDB.decrypt(text_secure)
    _(decrypted_text).must_equal test_text
  end
end
