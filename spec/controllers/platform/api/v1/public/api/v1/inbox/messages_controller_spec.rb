require 'rails_helper'

RSpec.describe 'Public Inbox Contact Conversation Messages API', type: :request do
  let!(:api_channel) { create(:channel_api) }
  let!(:contact) { create(:contact) }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: api_channel.inbox)}
  let!(:conversation)  { create(:conversation, contact: contact, contact_inbox: contact_inbox) }

  describe 'GET /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations/{conversation_id}/messages' do
    it 'return the messages for that conversation' do
      2.times.each { create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation) }

      get "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/messages"
          
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data.length).to eq 2
    end
  end

  describe 'POST /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations/{conversation_id}/messages' do
    it 'creates a message in the conversation' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/messages",
        params: { content: "hello" }
          
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data['content']).to eq("hello")
    end

    it 'creates attachment message in conversation' do
      file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/messages",
        params: { content: "hello", attachments: [file] }
          
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data['content']).to eq("hello")

      expect(conversation.messages.last.attachments.first.file.present?).to eq(true)
      expect(conversation.messages.last.attachments.first.file_type).to eq('image')
    end
  end

  describe 'PATCH /public/api/v1/inboxes/{identifier}/contact/{source_id}/conversations/{conversation_id}/messages/{id}' do
    it 'creates a message in the conversation' do
      message = create(:message, account: conversation.account, inbox: conversation.inbox, conversation: conversation)
      patch "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}/conversations/#{conversation.display_id}/messages/#{message.id}",
        params: { submitted_values: [{title: "test"}] }
          
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data['content_attributes']['submitted_values'].first['title']).to eq "test"
    end
  end
end
