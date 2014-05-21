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
          result[:success].should == true
          result[:exitcode].should == 0
          result[:stdout].should == "flirble wirble\n" * 8000
        end

        it 'should cope with large amounts of output on both channels' do
          result = agent.send(:run_command, :command => %{ruby -e '8000.times { STDOUT.puts "flirble wirble"; STDERR.puts "flooble booble" }'})
          result[:success].should == true
          result[:exitcode].should == 0
          result[:stdout].should == "flirble wirble\n" * 8000
          result[:stderr].should == "flooble booble\n" * 8000
        end

        context 'timeout' do
          it 'should not timeout commands that exit quickly enough' do
            result = agent.send(:run_command, {
              :command => %{ruby -e 'puts "started"; sleep 1; puts "finished"'},
              :timeout => 2.0,
            })
            result[:success].should == true
            result[:exitcode].should == 0
            result[:stdout].should == "started\nfinished\n"
            result[:stderr].should == ''
          end

          it 'should timeout long running commands' do
            start = Time.now()
            result = agent.send(:run_command, {
              :command => %{ruby -e 'STDOUT.sync = true; puts "started"; sleep 2; puts "finished"'},
              :timeout => 1.0,
            })
            elapsed = Time.now() - start
            elapsed.should <= 1.5
            result[:success].should == false
            result[:exitcode].should == nil
            result[:stdout].should == "started\n"
            result[:stderr].should == ''
          end
        end
      end
    end
  end
end
