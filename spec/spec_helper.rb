require 'mocha'
require 'mcollective'
require 'mcollective/test'

RSpec.configure do |config|
  config.mock_with :mocha
  config.include(MCollective::Test::Matchers)

  config.before :each do
    MCollective::PluginManager.clear
  end
end
