require File.expand_path("../../spec_helper", __FILE__)

module Rews
  describe Client do
    it "should create new DistinguishedFolderIds for arbitrary mailboxes" do
      client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")

      mock(Folder::DistinguishedFolderId).new(client, 'inbox', 'foo@bar.com')

      client.distinguished_folder_id('inbox', 'foo@bar.com')
    end

    it "should create new DistinguishedFolderIds for the default mailbox" do
      client = Client.new("https://foo/EWS/Exchange.asmx", :ntlm, "EXCHDOM\\foo", "password")

      mock(Folder::DistinguishedFolderId).new(client, 'inbox', nil)

      client.distinguished_folder_id('inbox')
    end
  end
end
