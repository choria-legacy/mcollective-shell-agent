# Shell agent

## Deprecation Notice

This repository holds legacy code related to The Marionette Collective project.  That project has been deprecated by Puppet Inc and the code donated to the Choria Project.

Please review the [Choria Project Website](https://choria.io) and specifically the [MCollective Deprecation Notice](https://choria.io/mcollective) for further information and details about the future of the MCollective project.

## Overview

The shell agent allows you to start and manage shell commands via
mcollective.

It allows the running of long-running processes with a mechanism to check in
on the output from these long-running processes, which is independent of the
mcollective daemon process (the daemon can be restarted without interrupting
the processes)

To use this agent you need at least:

* MCollective 2.2.4
* Ruby 1.9 (for Process#spawn)

Please report any errors or make feature requests in the [MCOP jira project][MCOP]

Please note: we do not recommend this agent as a way of building out your
automation, for that you're still better off writing your own tailored
[agents][writing-agents] that fit your use case.  This agent is targeted
at the ad-hoc needs that people occasionally have.

[writing-agents]: http://docs.puppetlabs.com/mcollective/simplerpc/agents.html
[MCOP]: http://tickets.puppetlabs.com/browse/MCOP

## Installation

Follow the [basic plugin install guide][install guide], taking all
the code from lib and adding it to your MCollective $libdir

[install guide]: https://docs.puppet.com/mcollective/deploy/plugins.html


## Configuring the agent

The agent should work without any additional configuration, though there are
some options you can tune the mcollective server.cfg.

### `plugin.shell.state_directory`

This is where the state used to track processes will live.  By default this
will be /var/run/mcollective-shell on Unix systems.

```
plugin.shell.state_directory = /opt/run/mcollective-shell
```


## Application usage

The `mco shell` application has several subcommands to start and manage
processes.

### mco shell run

Runs a command and reports back.  Use this for discrete short-living commands.

For long-running commands look at `start` or `run --tail`.

```
$ mco shell run dir

 * [ ============================================================> ] 2 / 2

master:
bin   dev  home  lib64       media  opt   root  selinux  srv  tmp  vagrant
boot  etc  lib   lost+found  mnt    proc  sbin  src      sys  usr  var

server2008r2a:
 Volume in drive C has no label.
 Volume Serial Number is DADF-75F9

 Directory of C:\

09/22/2012  11:45 AM    <SYMLINKD>     manifests [\\vboxsrv\manifests]
09/22/2012  11:45 AM    <SYMLINKD>     modules [\\vboxsrv\modules]
07/13/2009  08:20 PM    <DIR>          PerfLogs
09/22/2012  11:42 AM    <DIR>          Program Files
03/27/2014  06:52 AM    <DIR>          Program Files (x86)
07/03/2014  07:42 AM    <SYMLINKD>     src [\\vboxsrv\C:_src]
03/27/2014  06:39 AM    <DIR>          Users
07/03/2014  07:42 AM    <SYMLINKD>     vagrant [\\vboxsrv\vagrant]
03/27/2014  06:41 AM    <DIR>          Windows
               0 File(s)              0 bytes
               9 Dir(s)  34,565,091,328 bytes free


Finished processing 2 / 2 hosts in 221.28 ms
```

### mco shell run --tail

Starts a command, shows you the output from it, kills the command when you
interrupt with control-c, exits normally when the command exits.

```
$ mco shell -I /master/ run --tail vmstat 1

 * [ ============================================================> ] 1 / 1

master stdout: procs -----------memory---------- ---swap-- -----io---- --system-- -----cpu-----
master stdout:  r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
master stdout:  0  1 445812 120584   5808  37348   34   29    52    48   39   47  6  1 93  0  0
master stdout:  1  0 445112 122692   5824  37332 2692    0  2692    84  911 2089 47  9 40  4  0
master stdout:  1  0 444848 122576   5824  37344  288    0   288     0  773 1914 48  5 47  0  0
master stdout:  0  0 444012 121320   5824  37348 1212    0  1212     0  823 1917 47  6 45  1  0
master stdout:  0  0 443984 121204   5824  37372    0    0     0     0  797 1796 52  5 43  0  0
master stdout:  0  0 438800 117244   5824  37360 3896    0  3896     0  910 2123 49  6 45  0  0
master stdout:  1  0 438768 117136   5840  37368    0    0     0   136  811 1926 48  6 45  0  0
^CAttempting to stopping cleanly, interrupt again to kill
Sending kill to master 6dad5cb9-57f7-46e0-bad7-07ab117369a5
```


### mco shell start

Starts a command in the background and tells you the id that has been assigned
to it.  You can then use `mco shell watch`, `mco shell kill`, `mco shell list`
to monitor this process and observe its output

```
$ mco shell -I /master/ start vmstat 1

 * [ ============================================================> ] 1 / 1

master: 0dd67fac-734f-4824-8b4d-03100d4f9d07

Finished processing 1 / 1 hosts in 76.37 ms
```


### mco shell watch

Shows you the output of a command you previously started with `mco shell start`

```
$ mco shell watch 0dd67fac-734f-4824-8b4d-03100d4f9d07

 * [ ============================================================> ] 2 / 2

master stdout: procs -----------memory---------- ---swap-- -----io---- --system-- -----cpu-----
master stdout:  r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
master stdout:  2  0 431448 110704   8484  40644   34   29    52    48   40   47  6  1 93  0  0
```

### mco shell list

Show a list of running jobs.

```
$ mco shell list -v

 * [ ============================================================> ] 2 / 2

master:
    0dd67fac-734f-4824-8b4d-03100d4f9d07
    1fd3961a-f48d-4119-b988-146b490a5ca3
    d174e20b-9cdb-4c14-9f34-fd29995f30cb
    ea809b20-3123-46b4-bf59-10ff7251ca9b

Finished processing 2 / 2 hosts in 142.34 ms
```

### mco shell kill

Kill a running job.

```
$ mco shell kill 0dd67fac-734f-4824-8b4d-03100d4f9d07

 * [ ============================================================> ] 2 / 2


Finished processing 2 / 2 hosts in 170.17 ms
```
