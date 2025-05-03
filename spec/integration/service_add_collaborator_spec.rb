# frozen_string_literal: true

require_relative '../spec_helper'
# require_relative '../../app/services/add_collaborator_to_folder'

describe 'Test AddCollaboratorToFolder service' do
  before do
    wipe_database

    DATA[:accounts].each do |account_data|
      UCCMe::Account.create(account_data)
    end

    folder_data = DATA[:folders].first

    @owner = UCCMe::Account.all[0]
    @collaborator = UCCMe::Account.all[1]
    
    # Create folder with owner - fixed parameter structure
    @folder = UCCMe::CreateFolderForOwner.call(
      owner_id: @owner.id,
      folder_data: {
        foldername: folder_data['foldername'] || folder_data[:foldername],
        description: folder_data['description'] || folder_data[:description]
      }
    )
  end

  it 'HAPPY: should be able to add a collaborator to a folder' do
    UCCMe::AddCollaboratorToFolder.call(
      email: @collaborator.email,
      folder_id: @folder.id
    )

    _(@collaborator.folder_collaborations.count).must_equal 1
    _(@collaborator.folder_collaborations.first).must_equal @folder
  end

  it 'BAD: should not add owner as a collaborator' do
    _(proc {
      UCCMe::AddCollaboratorToFolder.call(
        email: @owner.email,
        folder_id: @folder.id
      )
    }).must_raise UCCMe::AddCollaboratorToFolder::OwnerNotCollaboratorError
  end
end
