docker-sshagent-socket
======================

```
docker run -v /run:/new/run -d --name=dsshagent dsshagent UNIX:/new$SSH_AUTH_SOCK
```

```
ENV SSH_AUTH_SOCK /tmp/ssh/auth.sock
RUN dir=$(dirname $SSH_AUTH_SOCK) && mkdir -p $dir && chmod 777 $dir
RUN mkdir .ssh && printf "Host *\n\
  StrictHostKeyChecking no\n\
  ProxyCommand setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,unlink-early,mode=777 TCP:ssh_auth:5522 >/dev/null 2>&1 & sleep 0.5 && nc %%h %%p\n\
" > .ssh/config
```

Additional help at https://gist.github.com/d11wtq/8699521
