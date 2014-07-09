require 'spec_helper'
require 'mcollective/application/shell/prefix_stream_buf'

module MCollective
  class Application
    class Shell < Application
      describe PrefixStreamBuf do
        let(:buf) { PrefixStreamBuf.new('test: ') }

        describe '#initialize' do
          it 'should record a prefix and null the buffer' do
            buf.instance_variable_get(:@buffer).should == ''
            buf.instance_variable_get(:@prefix).should == 'test: '
          end
        end

        describe '#display' do
          it 'should print an entire line' do
            buf.expects(:puts).with("test: line\n")
            buf.display("line\n")
          end

          it 'should not print a partial line' do
            buf.expects(:puts).never
            buf.display('partial')
          end

          it 'should print two complete lines and not a partial' do
            buf.expects(:puts).with("test: one\n")
            buf.expects(:puts).with("test: two\n")
            buf.display("one\ntwo\nthree")
          end

          it 'should buffer until it has a complete line' do
            buf.expects(:puts).with("test: one two\n")
            buf.display("one ")
            buf.display("two\n")
          end
        end

        describe '#flush' do
          it 'should print partial lines when flushed' do
            buf.expects(:puts).with("test: partial\n")
            buf.display("partial")
            buf.flush
          end
        end
      end
    end
  end
end
