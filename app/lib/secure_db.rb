# frozen_string_literal: true

require_relative 'securable'

# SecureDB, library for encrypt and decrypt database
class SecureDB
  extend Securable

  def self.encrypt(plaintext)
    return nil unless plaintext

    ciphertext = base_encrypt(plaintext)
    Base64.strict_encode64(ciphertext)
  end

  def self.decrypt(ciphertext)
    return nil unless ciphertext64

    ciphertext = Base64.strict_decode64(ciphertext64)
    base_decrypt(ciphertext)
  end
end
