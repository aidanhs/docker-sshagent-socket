docker-sshagent-socket
======================

When using the [secret server](https://github.com/aidanhs/docker-secret-server)
container it can be tiresome to manually manage SSH keys (or impossible if
they're password protected).

As of 1.8, names of containers are automatically inserted into /etc/hosts, so
if you run this container with

```
docker run -d -v $(dirname $SSH_AUTH_SOCK):/s$(dirname $SSH_AUTH_SOCK) --name=dsshagent aidanhs/sshagent-socket
```

you can add the following lines to a Dockerfile for an image with `socat`
installed

```
FROM myimage

ENV SSH_AUTH_SOCK /tmp/ssh/auth.sock
RUN dir=$(dirname $SSH_AUTH_SOCK) && mkdir -p $dir && chmod 777 $dir
RUN mkdir -p ~/.ssh && printf "Host *\n\
  StrictHostKeyChecking no\n\
  ProxyCommand setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,unlink-early,mode=777 TCP:dsshagent:5522 >/dev/null 2>&1 & \
    sleep 0.5 && socat - TCP:%%h:%%p\n\
" > ~/.ssh/config

RUN scp user@mysecretserver:~/data /data
```

And (in theory) you have flawless access to any ssh servers your host user
has access to! You should probably remove `StrictHostKeyChecking no` and
add known hosts into your image though.

This works by the SSH agent server exposing a single port (5522). Whenever
the container being built attempts to make an SSH connection, it will run
`socat` to connect to the SSH agent container and expose the port
as a Unix socket (as required by SSH).

Unfortunately there are some issues with the current approach:

 - you have to sleep a small amount of time to let `socat` start before you
   let SSH begin - assuming you're being good and not doing too much SSH, this
   shouldn't really impact your build times
 - executing a number of SSH connections in parallel may break as the `socat`
   instances step on the same socket - try adding `,fork` to the end of the
   UNIX-LISTEN argument to keep `socat` listening for *all* connections,
   which may help with race conditions (though you end up with one socat
   process per ssh connection during the layer)
 - different host/container combinations may break things in strange ways

Raise an issue if you hit any of these problems - they're easy to solve by
writing a small program, this is currently just intended as a PoC.

Boot2Docker users and people with more exotic setups may wish to read some of
the later comments on [this gist](https://gist.github.com/d11wtq/8699521).

Security
--------

Running this gives anyone on your machine access to your SSH agent (and
therefore access to all servers your keys give access to).

If they have the ability to run arbitrary containers, they already had this.
