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
        let(:reply) { {} }

        before :each do
          agent.stubs(:reply).returns(reply)
          @tmpdir = Dir.mktmpdir
          Shell::Job.stubs(:state_path).returns(@tmpdir)
        end

        after :each do
          FileUtils.remove_entry_secure @tmpdir
        end

        it 'should run cleanly' do
          agent.send(:run_command, :command => 'echo foo')
          reply[:exitcode].should == 0
          reply[:stdout].should == "foo\n"
        end

        it 'should cope with large amounts of output' do
          agent.send(:run_command, :command => %{ruby -e '8000.times { puts "flirble wirble" }'})
          reply[:success].should == true
          reply[:exitcode].should == 0
          reply[:stdout].should == "flirble wirble\n" * 8000
        end

        it 'should cope with large amounts of output on both channels' do
          agent.send(:run_command, :command => %{ruby -e '8000.times { STDOUT.puts "flirble wirble"; STDERR.puts "flooble booble" }'})
          reply[:success].should == true
          reply[:exitcode].should == 0
          reply[:stdout].should == "flirble wirble\n" * 8000
          reply[:stderr].should == "flooble booble\n" * 8000
        end

        it 'raise on a non-existent command' do
          expect {
            agent.send(:run_command, :command => 'i_really_should_not_exist')
          }.to raise_error(/No such file or directory - i_really_should_not_exist/)
        end

        context 'timeout' do
          it 'should not timeout commands that exit quickly enough' do
            agent.send(:run_command, {
              :command => %{ruby -e 'puts "started"; sleep 1; puts "finished"'},
              :timeout => 2.0,
            })
            reply[:success].should == true
            reply[:exitcode].should == 0
            reply[:stdout].should == "started\nfinished\n"
            reply[:stderr].should == ''
          end

          it 'should timeout long running commands' do
            start = Time.now()
            agent.send(:run_command, {
              :command => %{ruby -e 'STDOUT.sync = true; puts "started"; sleep 5; puts "finished"'},
              :timeout => 1.0,
            })
            elapsed = Time.now() - start
            elapsed.should <= 2
            reply[:success].should == false
            reply[:exitcode].should == nil
            reply[:stdout].should == "started\n"
            reply[:stderr].should == ''
          end
        end
      end
    end
  end
end
