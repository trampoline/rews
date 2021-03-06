rews [![Build Status](https://travis-ci.org/trampoline/rews.png?branch=master)](https://travis-ci.org/trampoline/rews)
====

Rews has bitrotted and needs work to bring it up to date : This work will need an Exchange server to test against (ideally all of 2007, 2010 and 2013). I no longer have Exchange servers to test against, so someone else will have to take over the project, or users will have to migrate to another project.

Rews is a simple Ruby client for Exchange Web Services

Install
-------

    gem install rews

About
-----

* Find, Get and Delete of Items and Folders is supported.
* Filtering, ordering, and arbitrary property retrieval are supported.
* Bulk operations are supported
* Runs on both CRuby and JRuby

Method names generally follow the Exchange Web Services API
http://msdn.microsoft.com/en-us/library/bb409286(EXCHG.140).aspx

It has been tested against

* Exchange 2007 SP1 (Version 8.1, Build 240.6)
* Exchange 2010 SP1 (Version 14.1, Build 218.15)

Use
---

    # create a client
    c = Rews::Client.new("https://exchange.bar.com/EWS/Exchange.asmx", :ntlm, 'EXCHDOM\foo', 'password')

    # find a distinguished folder from one of the mailboxes the user has permissions for
    inbox=c.distinguished_folder_id('inbox', 'foo@bar.com')

    # find some message_ids,
    mids = inbox.find_item_id(:restriction=>[:<=, "item:DateTimeReceived",DateTime.now],
                              :sort_order=>[["item:DateTimeReceived", "Ascending"]],
                              :indexed_page_item_view=>{:max_entries_returned=>10, :offset=>0})

    # get some properties for a bunch of messages in one hit
    messages = c.get_item(mids, :item_shape=>{
                                  :base_shape=>:IdOnly,
                                  :additional_properties=>[
                                    [:field_uri, "item:Subject"],
                                    [:field_uri, "item:DateTimeReceived"],
                                    [:field_uri, "message:InternetMessageId"],
                                    [:field_uri, "message:IsRead"],
                                    [:field_uri, "message:IsReadReceiptRequested"]]})

    # suppress read receipts on any messages which have requested them
    c.suppress_read_receipt(messages)

    # delete the items to the DeletedItems folder
    c.delete_item(mids, :delete_type=>:MoveToDeletedItems)

Note on Patches/Pull Requests
-----------------------------

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
---------

Copyright (c) 2011 Trampoline Systems Ltd. See LICENSE for details.
