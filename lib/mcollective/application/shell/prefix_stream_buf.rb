module MCollective
  class Application
    class Shell < Application
      class PrefixStreamBuf
        # TODO(richardc): explain what this class is for
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
