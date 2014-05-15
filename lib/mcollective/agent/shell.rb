module MCollective
  module Agent
    class Shell<RPC::Agent
      action 'run' do
        reply[:stdout] = "foo\n"
        reply[:exitcode] = 0
      end
    end
  end
end
