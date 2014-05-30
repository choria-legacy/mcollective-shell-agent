require 'securerandom'

module MCollective
  module Agent
    class Shell<RPC::Agent
      class Job
        attr_reader :command
        attr_reader :stdout, :stderr
        attr_reader :io_thread
        def initialize(command)
          @command = command
          @stdout = ''
          @stderr = ''
          @stdout_rd, stdout_wr = IO.pipe
          @stderr_rd, stderr_wr = IO.pipe
          options = {
            :chdir => "/",
            :out => stdout_wr,
            :err => stderr_wr,
          }

          @pid = Process.spawn(command, options)
          stdout_wr.close
          stderr_wr.close
          @io_thread = Thread.new { io_loop }
        end

        def io_loop
          rd_fds = [ @stdout_rd, @stderr_rd ]
          while !rd_fds.empty?
            rds, = IO.select(rd_fds)
            rds.each do |readable|
              case readable
              when @stdout_rd
                begin
                  @stdout += @stdout_rd.readpartial(1024)
                rescue EOFError
                  rd_fds.delete(@stdout_rd)
                end
              when @stderr_rd
                begin
                  @stderr += @stderr_rd.readpartial(1024)
                rescue EOFError
                  rd_fds.delete(@stderr_rd)
                end
              else
                Log.error("Unexpected fd #{readable.inspect}")
              end
            end
          end
        end

        def status
          if io_thread.alive?
            return :running
          else
            return :stopped
          end
        end

        def kill
          io_thread.kill
          ::Process.kill('TERM', @pid)
        end

        def exitcode
          Process.waitpid(@pid)

          if Util.windows?
            # On win32 $? doesn't seem to get set - probably need to call GetExitCode
            exitcode = 0
          else
            exitcode = $?.exitstatus
          end
        end
      end

      @@jobs = {}

      action 'run' do
        run_command(request.data)
      end

      action 'start' do
        start_command(request.data)
      end

      action 'status' do
        handle = request[:handle]
        process = @@jobs[handle]
        stdout_offset = request[:stdout_offset] || 0
        stderr_offset = request[:stderr_offset] || 0

        reply[:status] = process.status
        reply[:stdout] = process.stdout.byteslice(stdout_offset..-1)
        reply[:stderr] = process.stderr.byteslice(stderr_offset..-1)
        if process.status == :stopped
          reply[:exitcode] = process.exitcode
          @@jobs.delete(handle)
        end
      end

      action 'kill' do
        handle = request[:handle]
        job = @@jobs[handle]

        job.kill
      end

      action 'list' do
        list
      end

      private

      def run_command(request = {})
        process = Job.new(request[:command])
        timeout = request[:timeout] || 0
        reply[:success] = true
        begin
          Timeout::timeout(timeout) do
            process.io_thread.join
          end
        rescue Timeout::Error
          reply[:success] = false
          process.kill
        end

        reply[:stdout] = process.stdout
        reply[:stderr] = process.stderr
        reply[:exitcode] = process.exitcode
      end

      def start_command(request = {})
        id = SecureRandom.uuid
        @@jobs[id] = Job.new(request[:command])
        reply[:handle] = id
      end

      def list
        list = {}
        @@jobs.each do |id,job|
          list[id] = {
            :id      => id,
            :command => job.command,
            :status  => job.status,
          }
        end

        reply[:jobs] = list
      end
    end
  end
end
