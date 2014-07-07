require 'mcollective/application/shell/prefix_stream_buf'

module MCollective
  class Application
    class Shell < Application
      class Watcher
        # TODO(richardc): explain what this class is for
        attr_reader :node, :handle
        attr_reader :stdout_offset, :stderr_offset

        def initialize(node, handle)
          @node = node
          @handle = handle
          @stdout = PrefixStreamBuf.new("#{node} stdout: ")
          @stderr = PrefixStreamBuf.new("#{node} stderr: ")
          @stdout_offset = 0
          @stderr_offset = 0
        end

        def status(response)
          @stdout_offset += response[:data][:stdout].size
          @stdout.display(response[:data][:stdout])
          @stderr_offset += response[:data][:stderr].size
          @stderr.display(response[:data][:stderr])
        end

        def flush
          @stdout.flush
          @stderr.flush
        end
      end
    end
  end
end
