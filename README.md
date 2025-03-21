jcp: Jason's rsync-like copy
============================

`jcp` is an rsync-like library and command line tool written Go. 

The library, in `jcp/jsync` is the main thing. The command line `jcp`
is mostly there to test it, but it can be used
standalone against the `jsrv` server program.

It is up to 3x faster than regular C rsync.

`jcp` was written to harden my RPC system, 
https://github.com/glycerine/rpc25519 ,
whose features and high-performance are leveraged.

installation
------------

~~~
$ go install github.com/glycerine/jcp/cmd/jsrv@latest
$ go install github.com/glycerine/jcp/cmd/jcp@latest
~~~

-----
Author: Jason E. Aten, Ph.D.

License: 2-clause BSD, the same as Go.

