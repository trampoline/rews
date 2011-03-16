$: << File.expand_path("..", __FILE__)

require 'net/ntlm'
# require 'httpclient' # don't need httpclient now ntlm-http is fixed too
require 'savon'
require 'fetch_in'

# Ruby Exchange Web Services
module Rews
  WSDL = File.expand_path("../../Services.wsdl", __FILE__)
  SCHEMA_MESSAGES = "http://schemas.microsoft.com/exchange/services/2006/messages"
  SCHEMA_TYPES = "http://schemas.microsoft.com/exchange/services/2006/types"
end

require 'rews/util'
require 'rews/restriction'
require 'rews/shape'
require 'rews/sort_order'
require 'rews/view'
require 'rews/folder'
require 'rews/item'
require 'rews/client'

