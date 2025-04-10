jcp: an rsync-like filesystem sync Go library/CLI
============================

`jcp` in Go, doing parallel file scanning and syncing, 
can be up to 3x faster than regular rsync (a single threaded C program).

`jcp` is an rsync-like library and command line tool written in Go. 
Like rsync, it uses a Content-Defined-Chunking (CDC) algorithm,
as they have become known in the literature,
to efficiently transfer only the diffs between filesystems.

Currently a parallelized version of the FastCDC 
algorithm with a Gear table is used [1] [2].
Other chunking algorithms are implemented in the jcdc/ sub-directory,
but our optimization studies arrived at FastCDC
using the min: 2KB, target: 8KB, max: 64KB settings.

The library, in `jcp/jsync` is the main thing here.
The command line `jcp` is mostly there to test it, but it can be used
standalone against the `jsrv` server program.

`jcp` was written to harden and polish my RPC system, https://github.com/glycerine/rpc25519 ,
whose high-performance and novel Peer/Circuit/Fragment
paradigm is featured here. In this evolution
of RPC, peers communicate fragments of infinite 
data streams over any number of persistent circuits. Since
the roles are peer-to-peer rather than client-server,
any peer can run the code for any service
(as here, in the jcp case, either end can give or take a
stream of filesystem updates).

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
..._but_ the default cert name expected by the tools is `node`, 
so, for now, do this instead to minimize the flags we pass later:
~~~
me@local ~ $ selfy -k node -e george@example.com -nopass
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
now we keep things simple.


step 2: run the client, jcp
-------------

On the local box, run `jcp <from> <to>` to transfer directories/files.

Either location can have a `host:` prefix (but not both).

If `<to>` is omitted then we assume the current directory.

Example: to copy the remote directory to the local directory:
~~~
me@local $ jcp remote:
~~~

Example: to copy the local directory `send_this_dir` to the remote:
~~~
me@local $ jcp send_this_dir remote:
~~~

A progress bar will report on the transfer and give an ETA.

verifying your transfer
-----------------------
Fast cryptographic checksums are automatically used to verify
the transfer. If you want to 
double-check it yourself, you can use my
`b3` tool: https://github.com/glycerine/b3 which
does parallel and hardware accelerated Blake3 
cryptographic hashing of whole file systems.

local-to-local efficient backups?
----------------------

Question: can `jcp` efficiently update incremental backups from 
primary to secondary local storage, e.g. daily backup of a 
home dir to an attached memory stick or an alternate folder on the same filesystem?

Answer: `jcp` can and does copy local-to-local disk, but it is missing
the obvious optimization of skipping the network stack in this case.

It might still be fast (enough) for your purposes. You
would have to benchmark it to see. See below for demonstration. 

It is pretty convenient to try local-to-local, because when 
jcp detects it is doing a local disk-to-local disk transfer, 
it starts the receiver for you (the jsrv part is run in-process,
on a goroutine). It already did this for testing convenience,
but now (I added this small feature in response to this question)
it also automatically turns off the encryption+decryption part of the
transport, since there's no point in wasting cycles doing
encryption just to decrypt it a moment later so it can be written
to disk unencrypted.  

More broadly, `jcp` certainly doesn't aim to provide encrypted
backups. That is a much bigger lift, and there are alot of
specialized backup programs out there that do that already (e.g. plakar.io).

Demonstration:

~~~
~/go/src/github.com/glycerine/jcp (master) $ jcp src target

no ':' in src/target: starting local rsync server to receive files...

(001)version.go                [==============================] 100%  684.0 B     38.3 MB/s   00:00 ETA

jcp.go:474 [pid 9073] 2025-03-29 09:20:47.705 -0500 CDT giver total file sizes: 43_651_011

jcp.go:475 [pid 9073] 2025-03-29 09:20:47.705 -0500 CDT bytes read = 53_715 ; bytes sent = 12_412_130 (out of 43_651_011). (28.4%) ratio: 3.5x speedup

~/go/src/github.com/glycerine/jcp (master) $ jcp src target

no ':' in src/target: starting local rsync server to receive files...

jcp.go:474 [pid 9300] 2025-03-29 09:21:18.856 -0500 CDT giver total file sizes: 43_649_411

jcp.go:475 [pid 9300] 2025-03-29 09:21:18.856 -0500 CDT bytes read = 693 ; bytes sent = 8_491 (out of 43_649_411). (0.0%) ratio: 5140.7x speedup

~/go/src/github.com/glycerine/jcp (master) $
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

references
----------
[1] https://joshleeb.com/posts/fastcdc.html

[2] https://www.usenix.org/conference/atc16/technical-sessions/presentation/xia

-----
Author: Jason E. Aten, Ph.D.

License: 2-clause BSD, the same as Go.
