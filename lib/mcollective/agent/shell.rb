module MCollective
  module Agent
    class Shell<RPC::Agent
      action 'run' do
        result = run_command(request.data)
        result.each do |k,v|
          reply[k] = v
        end
      end

      private

      def run_command(request = {})
        # a timeout of 0 waits forever
        timeout = request[:timeout] || 0

        reply = {}
        stdout_rd, stdout_wr = IO.pipe
        stderr_rd, stderr_wr = IO.pipe
        options = {
          :chdir => "/",
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
        success = true
        exitcode = nil

        Log.warn("timeout is #{timeout}")

        begin
          Timeout::timeout(timeout) do
            rd_fds = [ stdout_rd, stderr_rd ]
            while !rd_fds.empty?
              rds, = IO.select(rd_fds)
              rds.each do |readable|
                case readable
                when stdout_rd
                  begin
                    #stdout += stdout_rd.readpartial(1024)
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
          end
        rescue Timeout::Error
          success = false
          ::Process.kill('TERM', pid)
        ensure
          waited_pid = Process.waitpid(pid)
          Log.warn("waitpid(#{pid}) -> #{waited_pid}")

          if Util.windows?
            # On win32 $? doesn't seem to get set - probably need to call GetExitCode
            exitcode = 0
          else
            exitcode = $?.exitstatus
          end
        end

        return {
          :stdout => stdout,
          :stderr => stderr,
          :success => success,
          :exitcode => exitcode,
        }
      end
    end
  end
end
