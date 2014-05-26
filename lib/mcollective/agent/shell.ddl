metadata    :name        => "shell",
            :description => "Run commands with the local shell",
            :author      => "Richard Clamp",
            :license     => "ASL 2.0",
            :version     => "0.0.1",
            :url         => "https://github.com/puppetlabs/mcollective-shell-agent",
            :timeout     => 180

action "run", :description => "Run a command" do
    input   :command,
            :prompt      => "Command",
            :description => "Command to run",
            :type        => :string,
            :validation  => '.*',
            :maxlength   => 10 * 1024,
            :optional    => false

    input   :user,
            :prompt      => "User",
            :description => "User to run command as",
            :type        => :string,
            :validation  => '.*',
            :maxlength   => 1024,
            :optional    => true

    input   :timeout,
            :prompt      => "Timeout",
            :description => "Timeout to wait for the command to complete",
            :type        => :float,
            :optional    => true
            # TODO(richardc): validate positive.  May need another validator class

    output  :stdout,
            :description => "stdout from the command",
            :display_as  => "stdout"

    output  :stderr,
            :description => "stderr from the command",
            :display_as  => "stderr"

    output  :success,
            :description  => "did the process exit successfully",
            :display_as   => "success"

    output  :exitcode,
            :description => "exit code of the command",
            :display_as  => "exitcode"
end

action "start", :description => "Spawn a command" do
    input   :command,
            :prompt      => "Command",
            :description => "Command to run",
            :type        => :string,
            :validation  => '.*',
            :maxlength   => 10 * 1024,
            :optional    => false

    input   :user,
            :prompt      => "User",
            :description => "User to run command as",
            :type        => :string,
            :validation  => '.*',
            :maxlength   => 1024,
            :optional    => true

    output  :handle,
            :description => "identifier to a running command",
            :display_as  => "handle"
end

action "status", :description => "Get status of managed command" do
    input   :handle,
            :prompt      => "Handle",
            :description => "Handle of the command",
            :type        => :string,
            :validation  => '^[0-9a-z]*$',
            :maxlength   => 15,
            :optional    => false

    # Running, Exited
    output :status,
        :description => "status of the command",
        :display_as  => "status"

    # Stdout to this point - resets internal state
    output :stdout,
        :description => "stdout of the command",
        :display_as  => "stdout"

    # Stderr to this point - resets internal state
    output :stderr,
        :description => "stderr of the command",
        :display_as  => "stderr"

    # Only meaningful if status == Exited
    output :exitcode,
        :description => "exitcode of the command",
        :display_as  => "exitcode"

end

action "list", :description => "Get a list of all running commands" do
    output   :jobs,
        :description => "state of managed jobs",
        :display_as  => "jobs"

end

action "kill", :description => "Kill a command by handle" do
    input   :handle,
            :prompt      => "Handle",
            :description => "Handle of the command",
            :type        => :string,
            :validation  => '^[0-9a-z]*$',
            :maxlength   => 15,
            :optional    => false
end
