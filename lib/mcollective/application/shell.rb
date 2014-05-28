class MCollective::Application::Shell < MCollective::Application
  description 'Run shell commands innit'

  usage <<-END_OF_USAGE
mco shell [OPTIONS] [FILTERS] <ACTION> [ARGS]
Usage: mco shell tail [COMMAND]
END_OF_USAGE

  def post_option_parser(configuration)
    configuration[:command] = ARGV.shift
  end

  def main
    send("#{configuration[:command]}_command")
  end

  private

  class TailState

    attr_reader :node, :handle
    attr_reader :stdout_offset, :stderr_offset

    def initialize(response)
      @node = response[:sender]
      @handle = response[:data][:handle]
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

    private

    class PrefixStreamBuf
      def initialize(prefix)
        @buffer = ''
        @prefix = prefix
      end

      def display(data)
        @buffer += data
        chunks = @buffer.lines.to_a
        return if chunks.empty?

        if chunks[-1][-1] != "\n"
          @buffer = chunks[-1]
          chunks.pop
        else
          @buffer = ''
        end

        chunks.each do |chunk|
          puts "#{@prefix}#{chunk}"
        end
      end

      def flush
        if @buffer.size > 0
          display("\n")
        end
      end
    end
  end

  def tail_command
    command = ARGV.join(' ')
    client = rpcclient('shell')

    processes = []
    client.start(:command => command).each do |response|
      next unless response[:statuscode] == 0
      processes << TailState.new(response)
    end

    client.progress = false

    state = :running
    trap('SIGINT') do
      puts "Attempting to stopping cleanly, interrupt again to kill"
      state = :stopping

      # if we're double-tapped, just quit (may leave a mess)
      trap('SIGINT') do
        puts "OK you meant it; bye"
        exit 1
      end
    end

    while !processes.empty?
      processes.each do |process|
        #puts process.inspect
        client.filter["identity"].clear
        client.identity_filter process.node

        if state == :stopping
          puts "Sending kill to #{process.node} #{process.handle}"
          client.kill(:handle => process.handle)
        end

        client.status({
          :handle => process.handle,
          :stdout_offset => process.stdout_offset,
          :stderr_offset => process.stderr_offset,
        }).each do |response|
          #puts response.inspect

          if response[:statuscode] != 0
            process.flush
            processes.delete(process)
            break
          end

          process.status(response)

          if response[:data][:status] == :stopped
            process.flush
            processes.delete(process)
          end
        end
      end
    end
  end
end
