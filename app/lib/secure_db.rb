# frozen_string_literal: true

require 'rbnacl'
require 'base64'

# SecureDB, library for encrypt and decrypt database
class SecureDB
  class NoDBKeyError < StandardError; end

  def self.generate_key
    key = RbNaCl::Random.random_bytes(RbNaCl::SecretBox.key_bytes)
    Base64.strict_encode64(key)
  end

  def self.setup(base_key)
    raise NoDBKeyError unless base_key

    @key = Base64.strict_decode64(base_key)
  end

  def self.encrypt(plaintext)
    return nil unless plaintext

    simple_box = RbNaCl::SimpleBox.from_secret_key(@key)
    ciphertext = simple_box.encrypt(plaintext)
    Base64.strict_encode64(ciphertext)
  end

  def self.decrypt(ciphertext)
    return nil unless ciphertext

    ciphertext = Base64.strict_decode64(ciphertext)
    simple_box = RbNaCl::SimpleBox.from_secret_key(@key)
    simple_box.decrypt(ciphertext).force_encoding(Encoding::UTF_8)
  end
end
