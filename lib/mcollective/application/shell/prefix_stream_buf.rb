# PrefixStreamBuf is a utility class used my
# MCollective::Application::Shell::Watcher.

# PrefixStreambuf#display takes chunks of input, and on complete lines will
# emit that line with the prefix.  Incomplete lines are kept internally for
# the next call to display, unless #flush is called to flush the buffer.

module MCollective
  class Application
    class Shell < Application
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
  end
end
