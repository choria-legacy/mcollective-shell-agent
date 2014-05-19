require 'spec_helper'

module MCollective
  module Agent
    describe Shell do
      let(:agent_file) { File.join('lib', 'mcollective', 'agent', 'shell.rb')}
      let(:agent) { MCollective::Test::LocalAgentTest.new('shell', :agent_file => agent_file).plugin }

      describe '#run' do
        it 'should delegate to #run_command' do
          agent.expects(:run_command).with({:command => 'echo foo'}).returns({
            :exitcode => 0,
            :stdout => "foo\n",
            :stderr => '',
          })
          result = agent.call(:run, :command => 'echo foo')
          result.should be_successful
        end
      end

      describe '#run_command' do
        it 'should run cleanly' do
          result = agent.send(:run_command, :command => 'echo foo')
          result[:exitcode].should == 0
          result[:stdout].should == "foo\n"
        end

        it 'should cope with large amounts of output' do
          result = agent.send(:run_command, :command => %{ruby -e '8000.times { puts "flirble wirble" }'})
          result[:exitcode].should == 0
          result[:stdout].should == "flirble wirble\n" * 8000
        end
      end
    end
  end
end
