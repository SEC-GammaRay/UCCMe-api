# frozen_string_literal: true

require_relative '../spec_helper'

describe 'Test File Sharing' do
  include Rack::Test::Methods

  before do
    DatabaseHelper.wipe_database

    @owner_data = DATA[:accounts][0]
    @share_with_data = DATA[:accounts][1]
    @other_data = DATA[:accounts][2]

    @owner = UCCMe::Account.create(@owner_data)
    @share_with = UCCMe::Account.create(@share_with_data)
    @other = UCCMe::Account.create(@other_data)

    @folder = @owner.add_owned_folder(DATA[:folders][0])
    @file = @folder.add_stored_file(DATA[:stored_files][0])

    header 'CONTENT_TYPE', 'application/json'
  end

  describe 'Sharing files' do
    it 'HAPPY: should share a file with view permission' do
      share_data = {
        share_with_email: @share_with.email,
        permissions: ['view']
      }

      header 'AUTHORIZATION', auth_header(@owner_data)
      post "api/v1/shares/files/#{@file.id}", share_data.to_json

      _(last_response.status).must_equal 201
      
      result = JSON.parse(last_response.body)
      _(result['message']).must_equal 'File shared successfully'
      
      # Verify share was created
      share = UCCMe::FileShare.last
      _(share.stored_file_id).must_equal @file.id
      _(share.shared_with_id).must_equal @share_with.id
      _(JSON.parse(share.permissions)).must_equal ['view']
    end

    it 'HAPPY: should share a file with view and copy permissions' do
      share_data = {
        share_with_email: @share_with.email,
        permissions: ['view', 'copy']
      }

      header 'AUTHORIZATION', auth_header(@owner_data)
      post "api/v1/shares/files/#{@file.id}", share_data.to_json

      _(last_response.status).must_equal 201
      
      share = UCCMe::FileShare.last
      _(JSON.parse(share.permissions)).must_include 'view'
      _(JSON.parse(share.permissions)).must_include 'copy'
    end

    it 'HAPPY: should share with expiration date' do
      future_date = Time.now + (24 * 60 * 60) # 1 day from now
      share_data = {
        share_with_email: @share_with.email,
        permissions: ['view'],
        expires_at: future_date.iso8601
      }

      header 'AUTHORIZATION', auth_header(@owner_data)
      post "api/v1/shares/files/#{@file.id}", share_data.to_json

      _(last_response.status).must_equal 201
      
      share = UCCMe::FileShare.last
      _(share.expires_at).wont_be_nil
      _(share.active?).must_equal true
    end

    it 'SAD: should not share without authorization' do
      share_data = {
        share_with_email: @share_with.email,
        permissions: ['view']
      }

      post "api/v1/shares/files/#{@file.id}", share_data.to_json

      _(last_response.status).must_equal 403
    end

    it 'BAD: non-owner should not be able to share' do
      share_data = {
        share_with_email: @other.email,
        permissions: ['view']
      }

      header 'AUTHORIZATION', auth_header(@share_with_data)
      post "api/v1/shares/files/#{@file.id}", share_data.to_json

      _(last_response.status).must_equal 403
    end

    it 'BAD: should not share with self' do
      share_data = {
        share_with_email: @owner.email,
        permissions: ['view']
      }

      header 'AUTHORIZATION', auth_header(@owner_data)
      post "api/v1/shares/files/#{@file.id}", share_data.to_json

      _(last_response.status).must_equal 403
    end
  end

  describe 'Viewing shares' do
    before do
      @share = UCCMe::FileShare.create(
        stored_file_id: @file.id,
        owner_id: @owner.id,
        shared_with_id: @share_with.id,
        permissions: JSON.generate(['view']),
        share_token: SecureRandom.urlsafe_base64(32)
      )
    end

    it 'HAPPY: owner should see all shares for their file' do
      header 'AUTHORIZATION', auth_header(@owner_data)
      get "api/v1/shares/files/#{@file.id}"

      _(last_response.status).must_equal 200
      
      result = JSON.parse(last_response.body)
      _(result['data'].count).must_equal 1
      _(result['data'][0]['attributes']['shared_with_username']).must_equal @share_with.username
    end

    it 'SAD: non-owner should not see shares' do
      header 'AUTHORIZATION', auth_header(@share_with_data)
      get "api/v1/shares/files/#{@file.id}"

      _(last_response.status).must_equal 403
    end
  end

  describe 'Deleting shares' do
    before do
      @share = UCCMe::FileShare.create(
        stored_file_id: @file.id,
        owner_id: @owner.id,
        shared_with_id: @share_with.id,
        permissions: JSON.generate(['view']),
        share_token: SecureRandom.urlsafe_base64(32)
      )
    end

    it 'HAPPY: owner should delete share' do
      header 'AUTHORIZATION', auth_header(@owner_data)
      delete "api/v1/shares/#{@share.id}"

      _(last_response.status).must_equal 200
      
      # Verify share was deleted
      _(UCCMe::FileShare.first(id: @share.id)).must_be_nil
    end

    it 'SAD: non-owner should not delete share' do
      header 'AUTHORIZATION', auth_header(@share_with_data)
      delete "api/v1/shares/#{@share.id}"

      _(last_response.status).must_equal 403
      
      # Verify share still exists
      _(UCCMe::FileShare.first(id: @share.id)).wont_be_nil
    end
  end

  describe 'File access with shares' do
    before do
      @share = UCCMe::FileShare.create(
        stored_file_id: @file.id,
        owner_id: @owner.id,
        shared_with_id: @share_with.id,
        permissions: JSON.generate(['view', 'copy']),
        share_token: SecureRandom.urlsafe_base64(32)
      )
    end

    it 'HAPPY: shared user should access file' do
      header 'AUTHORIZATION', auth_header(@share_with_data)
      get "api/v1/files/#{@file.id}"

      _(last_response.status).must_equal 200
      
      result = JSON.parse(last_response.body)
      _(result['data']['policies']['can_view']).must_equal true
      _(result['data']['policies']['can_copy']).must_equal true
      _(result['data']['policies']['can_edit']).must_equal false
      _(result['data']['policies']['can_delete']).must_equal false
    end

    it 'SAD: non-shared user should not access file' do
      header 'AUTHORIZATION', auth_header(@other_data)
      get "api/v1/files/#{@file.id}"

      _(last_response.status).must_equal 403
    end

    it 'SAD: shared user should not delete file' do
      header 'AUTHORIZATION', auth_header(@share_with_data)
      delete "api/v1/files/#{@file.id}"

      _(last_response.status).must_equal 403
    end

    it 'HAPPY: owner should delete file' do
      header 'AUTHORIZATION', auth_header(@owner_data)
      delete "api/v1/files/#{@file.id}"

      _(last_response.status).must_equal 200
      
      # Verify file and shares were deleted
      _(UCCMe::StoredFile.first(id: @file.id)).must_be_nil
      _(UCCMe::FileShare.where(stored_file_id: @file.id).count).must_equal 0
    end
  end
end
