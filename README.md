jcp: an rsync-like filesystem sync Go library/CLI
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
$ go install github.com/glycerine/rpc25519/cmd/selfy@latest
$ go install github.com/glycerine/jcp/cmd/jsrv@latest
$ go install github.com/glycerine/jcp/cmd/jcp@latest
~~~

getting started
---------------

A pre-requisite is having your certificates
generated, as rpc25519 is an authenticated
and encrypted RPC system. The `selfy` tool
generates self-signed certs for you, and is
the easiest way to get started.

step 0: Generate and distribute certs
-----------
If your name is George, you might generate a cert
for your username and email like this (-nopass is
not recommended, of course, but is a convenience
for testing).

~~~
me@local ~ $ selfy -k george -e george@example.com -nopass
~~~

Then distribute your certs and CA public key to the
remote host.
~~~
$ ssh remote mkdir -p .config/rpc25519 # ensure config dir exists first
$ rsync -avz ~/.config/rpc25519/certs remote:.config/rpc25519/
~~~

step 1: start the server, jsrv
---------

On the remote box, start `jsrv` in the directory
you want to receive files into (or send files from).

~~~
me@remote ~/remote_backup_dir $ jsrv
~~~
You might want to `nohup jsrv &> ~/logs/log.jsrv &` but for 
keep things simple.


step 2: run the client, jcp
-------------

On the local box, run jcp <from> <to> to transfer directories/files.

Either location can have a `host:` prefix (but not both).

If <to> is omitted then we assume the current directory.

Example:
~~~
me@local $ jcp remote:
~~~

jcp flag reference
------------------

~~~
$ jcp -h

Usage of jcp:
  -compress string
    	compression algo. other choices: none, s2, lz4, zstd:01, zstd:03, zstd:07, zstd:11 (default "s2")
  -dry
    	dry run, do not change anything really
  -memprof string
    	file to write memory profile 30 sec worth to
  -p int
    	port on server to connect to (default 8443)
  -q	quiet, no progress report
  -serial
    	serial single threaded file chunking, rather than parallel. Mostly for benchmarking
  -v	verbosely walk dir, showing paths
  -w	walk dir, to test walk.go
  -webprofile
    	start web pprof profiling on localhost:7070
~~~

jsrv flags reference
------------------

~~~
$ jsrv -h

  -big
    	turn off sending compression.
  -certs string
    	use this path for certs; instead of the local ./certs/ directory. (default "/Users/jaten/.config/rpc25519/certs")
  -echo
    	bistream echo everything
  -k string
    	specifies name of keypairs to use (certs/name.crt and certs/name.key); instead of the default certs/node.crt and certs/node.key for the server. (default "node")
  -max int
    	set runtime.GOMAXPROCS to this value.
  -press string
    	select sending compression algorithm; one of: s2, lz4, zstd:01, zstd:03, zstd:07, zstd:11 (default "s2")
  -prof string
    	host:port to start web profiler on. host can be empty for all localhost interfaces
  -psk string
    	path to pre-shared key file
  -q	use QUIC instead of TCP/TLS
  -quiet
    	for profiling, do not log answer
  -readfile
    	listen for files to write to disk; client should run -sendfile
  -rsync
    	act as an rsync reader/receiver of files; cli -rsync will send us the diffs of a file. We report what chunks we need to update a file beforehand. (default true)
  -s string
    	server address to bind and listen on (default "0.0.0.0:8443")
  -sec int
    	run for this many seconds
  -serial
    	serial single threaded file chunking, rather than parallel. Mostly for benchmarking
  -serve
    	serve downloads; client should run -download
  -skip-verify
    	do not require client certs be from our CA, nor remember client certs in a known_client_keys file for later lockdown
  -tcp
    	use TCP instead of the default TLS
  -v	verbose debugging compression settings per message
$ 
~~~

-----
Author: Jason E. Aten, Ph.D.

License: 2-clause BSD, the same as Go.
