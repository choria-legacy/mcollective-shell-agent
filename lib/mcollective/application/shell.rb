require 'mcollective/application/shell/watcher'

class MCollective::Application::Shell < MCollective::Application
  description 'Run shell commands'

  usage <<-END_OF_USAGE
mco shell [OPTIONS] [FILTERS] <ACTION> [ARGS]

  mco shell start [COMMAND]
  mco shell watch [HANDLE]
  mco shell tail [COMMAND]
  mco shell list
  mco shell kill [HANDLE]
END_OF_USAGE

  def post_option_parser(configuration)
    # TODO(richardc): cope with no command
    configuration[:command] = ARGV.shift
  end

  def main
    # TODO(richardc): cope with bad command
    send("#{configuration[:command]}_command")
  end

  private

  def start_command
    command = ARGV.join(' ')
    client = rpcclient('shell')

    responses = client.start(:command => command)
    responses.sort_by! { |r| r[:sender] }

    responses.each do |response|
      if response[:statuscode] == 0
        puts "#{response[:sender]}: #{response[:data][:handle]}"
      else
        puts "#{response[:sender]}: ERROR: #{response.inspect}"
      end
    end
    printrpcstats :summarize => true, :caption => "Started command: #{command}"
  end

  def list_command
    client = rpcclient('shell')

    responses = client.list
    responses.sort_by! { |r| r[:sender] }

    responses.each do |response|
      if response[:statuscode] == 0
        next if response[:data][:jobs].empty?
        puts "#{response[:sender]}:"
        response[:data][:jobs].keys.sort.each do |handle|
          puts "    #{handle}"

          if client.verbose
            puts "        command: #{response[:data][:jobs][handle][:command]}"
            puts "        status:  #{response[:data][:jobs][handle][:status]}"
            puts ""
          end
        end
      end
    end

    printrpcstats :summarize => true, :caption => "Command list"
  end

  def watch_command
    handles = ARGV
    client = rpcclient('shell')

    watchers = []
    client.list.each do |response|
      next if response[:statuscode] != 0
      response[:data][:jobs].keys.each do |handle|
        if handles.include?(handle)
          watchers << Watcher.new(response[:sender], handle)
        end
      end
    end

    watch_these(client, watchers)
  end

  def tail_command
    command = ARGV.join(' ')
    client = rpcclient('shell')

    processes = []
    client.start(:command => command).each do |response|
      next unless response[:statuscode] == 0
      processes << Watcher.new(response[:sender], response[:data][:handle])
    end

    watch_these(client, processes, true)
  end

  def kill_command
    handle = ARGV.shift
    client = rpcclient('shell')

    client.kill(:handle => handle)

    printrpcstats :summarize => true, :caption => "Command list"
  end

  def watch_these(client, processes, kill_on_interrupt = false)
    client.progress = false

    state = :running
    if kill_on_interrupt
      # trap sigint so we can send a kill to the commands we're watching
      trap('SIGINT') do
        puts "Attempting to stopping cleanly, interrupt again to kill"
        state = :stopping

        # if we're double-tapped, just quit (may leave a mess)
        trap('SIGINT') do
          puts "OK you meant it; bye"
          exit 1
        end
      end
    else
      # When we get a sigint we should just exit
      trap('SIGINT') do
        puts ""
        exit 1
      end
    end

    while !processes.empty?
      processes.each do |process|
        client.filter["identity"].clear
        client.identity_filter process.node

        if state == :stopping && kill_on_interrupt
          puts "Sending kill to #{process.node} #{process.handle}"
          client.kill(:handle => process.handle)
        end

        client.status({
          :handle => process.handle,
          :stdout_offset => process.stdout_offset,
          :stderr_offset => process.stderr_offset,
        }).each do |response|
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
