# frozen_string_literal: true

require_relative '../spec_helper'
# require_relative '../../app/services/add_collaborator_to_folder'

describe 'Test AddCollaborator service' do
  before do
    DatabaseHelper.wipe_database

    DATA[:accounts].each do |account_data|
      UCCMe::Account.create(account_data)
    end

    folder_data = DATA[:folders].first

    @owner_data = DATA[:accounts][0]
    @owner = UCCMe::Account.all[0]
    @collaborator = UCCMe::Account.all[1]
    @folder = @owner.add_owned_folder(folder_data)
  end

  it 'HAPPY: should be able to add a collaborator to a folder' do
    auth = authorization(@owner_data)

    UCCMe::AddCollaborator.call(
      auth: auth,
      folder_id: @folder.id,
      collab_email: @collaborator.email
    )

    _(@collaborator.folder_collaborations.count).must_equal 1
    _(@collaborator.folder_collaborations.first).must_equal @folder
  end

  it 'BAD: should not add owner as a collaborator' do
    auth = authorization(@owner_data)

    _(proc {
      UCCMe::AddCollaborator.call(
        auth: auth,
        folder_id: @folder.id,
        collab_email: @owner.email
      )
    }).must_raise UCCMe::AddCollaborator::ForbiddenError
  end
end
