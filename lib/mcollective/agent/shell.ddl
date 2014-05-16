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

    output  :stdout,
            :description => "stdout from the command",
            :display_as  => "stdout"

    output  :stderr,
            :description => "stderr from the command",
            :display_as  => "stderr"

    output  :exitcode,
            :description => "exit code of the command",
            :display_as  => "exitcode"
end
