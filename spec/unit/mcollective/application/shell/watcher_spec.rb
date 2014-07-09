require 'spec_helper'
require 'mcollective/application/shell/watcher'

module MCollective
  class Application
    class Shell < Application
      describe Watcher do
        let(:watcher) { Watcher.new('test-node', 'test-handle') }

        describe '#initalize' do
          it 'should record the node, handle, and zero the offsets' do
            watcher.node.should == 'test-node'
            watcher.handle.should == 'test-handle'
            watcher.stdout_offset.should == 0
            watcher.stderr_offset.should == 0
          end
        end

        describe '#status' do
          it 'should increment the offsets' do
            watcher.status({ :data => { :stdout => "four", :stderr => "five " } })
            watcher.stdout_offset.should == 4
            watcher.stderr_offset.should == 5
          end
        end

        describe '#flush' do
          it 'should flush the managed PrefixStreamBufs' do
            watcher.instance_variable_get(:@stdout).expects(:flush)
            watcher.instance_variable_get(:@stderr).expects(:flush)
            watcher.flush
          end
        end
      end
    end
  end
end
