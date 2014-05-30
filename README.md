# Shell agent

The shell agent allows you to start and manage shell commands via
mcollective.

## Installation

Follow the [basic plugin install guide][install guide], taking all
the code from lib and adding it to your MCollective $libdir

[install guide]: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/InstalingPlugins


## Usage

### mco shell start

Starts a command.

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

### mco shell tail

Starts a command, shows you the output from it, kills the command when you interrupt with control-c.

```
$ mco shell -I /master/ tail vmstat 1

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

### mco shell list

Show a list of running jobs

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

Kill a running job

```
$ mco shell kill 0dd67fac-734f-4824-8b4d-03100d4f9d07

 * [ ============================================================> ] 2 / 2


Finished processing 2 / 2 hosts in 170.17 ms
```


