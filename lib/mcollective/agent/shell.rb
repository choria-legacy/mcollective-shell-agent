module MCollective
  module Agent
    class Shell<RPC::Agent
      action 'run' do
        result = run_command(request.data)
        reply[:exitcode] = result[:exitcode]
        reply[:stdout] = result[:stdout]
        reply[:stderr] = result[:stderr]
      end

      private

      def run_command(request = {})
        reply = {}
        stdout_rd, stdout_wr = IO.pipe
        stderr_rd, stderr_wr = IO.pipe
        options = {
          #:chdir => "/",
          :out => stdout_wr,
          :err => stderr_wr,
        }

        Log.warn("spawning '#{request[:command]} with #{options.inspect}")

        pid = Process.spawn(request[:command], options)
        stdout_wr.close
        stderr_wr.close
        Log.warn("spawned pid #{pid}")

        stdout = ''
        stderr = ''
        rd_fds = [ stdout_rd, stderr_rd ]
        while !rd_fds.empty?
          rds, = IO.select(rd_fds)
          rds.each do |readable|
            case readable
            when stdout_rd
              begin
                stdout += stdout_rd.readpartial(1024)
              rescue EOFError
                rd_fds.delete(stdout_rd)
              end
            when stderr_rd
              begin
                stderr += stderr_rd.readpartial(1024)
              rescue EOFError
                rd_fds.delete(stderr_rd)
              end
            else
              Log.error("Unexpected fd #{readable.inspect}")
            end
          end
        end

        Log.warn("drained output")

        waited_pid = Process.waitpid(pid)
        Log.warn("waitpid(#{pid}) -> #{waited_pid}")

        reply[:stdout] = stdout
        reply[:stderr] = stderr

        # On win32 $? doesn't seem to get set
        if Util.windows?
          reply[:exitcode] = 0
        else
          reply[:exitcode] = $?.exitstatus
        end
        return reply
      end
    end
  end
end
