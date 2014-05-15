require 'spec_helper'

module MCollective
  module Agent
    describe Shell do
      let(:agent_file) { File.join('lib', 'mcollective', 'agent', 'shell.rb')}
      let(:agent) { MCollective::Test::LocalAgentTest.new('shell', :agent_file => agent_file).plugin }

      describe '#run' do
        it 'should run cleanly' do
          result = agent.call(:run, :command => 'echo foo')
          result.should be_successful
          result.should have_data_items(:exitcode => 0, :stdout => "foo\n")
        end
      end
    end
  end
end
