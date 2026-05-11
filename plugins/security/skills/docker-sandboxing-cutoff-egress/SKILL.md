---
name: docker-sandboxing-cutoff-egress
description: Sandbox a Docker container so only an explicit allowlist of outside hosts is reachable. Use when running an untrusted/AI agent container and you want a hard egress cutoff with optional inbound port forwarding.
---

# Docker sandboxing — egress allowlist for a container

## Goal

Run a container (typically an AI agent) with **zero direct internet access**, allowing only an explicit allowlist of outside hosts via a vetted proxy. Inbound port publishing keeps working through a sidecar.

## Architecture

Three services on two networks:

```
host:PORT ──> ingress (socat) ──┐
                                │ docker_locked (internal: true, no gateway)
                  agent ────────┤
                                │
                  egress (tinyproxy) ───> docker_outside (bridge) ───> internet
```

- **agent**: only on `docker_locked` (`internal: true`). No route to the internet.
- **egress**: dual-homed on `locked` + `outside`. Runs tinyproxy with `FilterDefaultDeny Yes` and a host-allowlist filter file. Only it can reach the internet.
- **ingress**: dual-homed on `locked` + `outside`. Runs socat: `TCP-LISTEN:PORT,fork,reuseaddr TCP:agent:PORT`. Required because `internal: true` silently breaks Docker's port publishing.

The agent gets `HTTPS_PROXY=http://egress:8888` so proxy-aware tools route through the filter. Anything that ignores the env var simply has no route out — the network-layer cutoff is the real enforcer; the proxy is just the controlled gap.

## Gotchas (learned the hard way)

1. **`internal: true` silently drops port publishing.** Docker accepts the `ports:` declaration but never actually binds the host port (`docker inspect` shows `PortBindings` requested but `NetworkSettings.Ports` empty). Fix: add an ingress sidecar on a non-internal network and forward inward. There is no compose flag to override this.

2. **`docker compose run` doesn't set service-name aliases.** Without `--use-aliases`, sidecars on the same network can't resolve `agent` via Docker DNS (`nslookup agent` returns NXDOMAIN, socat logs "Name does not resolve"). Always pass `--use-aliases` for `run` when other containers need to dial in.

3. **Don't bind-mount tinyproxy configs into `monokal/tinyproxy`.** Its entrypoint `sed`-rewrites `/etc/tinyproxy/tinyproxy.conf` at startup, which fails on bind-mounted single files (`sed: can't move ... Resource busy`) and the container crashloops. Build your own minimal image (`alpine + apk add tinyproxy + COPY config`) to avoid third-party entrypoint magic.

4. **`Group nogroup` doesn't exist on alpine.** The default tinyproxy.conf uses `User nobody / Group nogroup`; alpine ships `nobody:nobody` instead. Set `Group nobody`.

5. **`HTTPS_PROXY` is voluntary.** `HTTP_PROXY`/`HTTPS_PROXY` are env conventions, not enforcement. Each app/library chooses whether to honor them — curl, git, gh, npm, most language stdlibs do; raw socket code, DNS-based protocols, and many native clients don't. The proxy alone is **not** a sandbox. Always pair it with `internal: true` so non-proxy-aware traffic has no route at all.

6. **DNS works via the proxy.** The locked agent has no public DNS. For HTTPS CONNECT this is fine: the client sends `CONNECT host:443` literally, and tinyproxy resolves it. So you don't need to also run a DNS resolver on the locked net.

7. **`docker compose down --remove-orphans` is dangerous.** It will also remove containers from *other* compose projects that happen to be on a shared network/space. Use without `--remove-orphans` unless you really mean it.

8. **Filter file is baked into the image** if you copy it in the Dockerfile. Editing `tinyproxy.filter` requires rebuilding the egress image (`docker compose build egress`) and restarting it.

## Reference implementation

### Compose override (apply with `-f`, leaving base untouched)

```yaml
# docker-compose.locked.yml
services:
  agent:
    networks: [locked]
    environment:
      - HTTPS_PROXY=http://egress:8888
      - HTTP_PROXY=http://egress:8888
      - NO_PROXY=localhost,127.0.0.1,egress
    depends_on: [egress, ingress]   # makes `compose run agent` start both sidecars

  egress:
    build:
      context: .
      dockerfile: tinyproxy.Dockerfile
    networks: [locked, outside]
    restart: unless-stopped

  ingress:
    image: alpine/socat
    command: TCP-LISTEN:3027,fork,reuseaddr TCP:agent:3027
    ports:
      - "3027:3027"
    networks: [locked, outside]
    restart: unless-stopped

networks:
  locked:
    internal: true
  outside:
    driver: bridge
```

### Egress image

```dockerfile
# tinyproxy.Dockerfile
FROM alpine:3.20
RUN apk add --no-cache tinyproxy
COPY tinyproxy.conf   /etc/tinyproxy/tinyproxy.conf
COPY tinyproxy.filter /etc/tinyproxy/filter
EXPOSE 8888
CMD ["tinyproxy", "-d", "-c", "/etc/tinyproxy/tinyproxy.conf"]
```

### Proxy config

```conf
# tinyproxy.conf
User nobody
Group nobody              # alpine has no `nogroup`
Port 8888
Listen 0.0.0.0
Timeout 600
LogLevel Info
MaxClients 100

Filter "/etc/tinyproxy/filter"
FilterDefaultDeny Yes     # whitelist mode
FilterExtended On
FilterURLs Off

ConnectPort 443           # HTTPS CONNECT — add 80 only if you need plain HTTP
```

### Allowlist file (POSIX extended regex, anchored)

```
# tinyproxy.filter
^api\.anthropic\.com$
^example\.com$
```

### Launcher

```bash
# run.sh
COMPOSE_FILES="-f docker-compose.yml"
if [ "${1:-}" != "+internet" ]; then
  COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.locked.yml"
fi
docker compose $COMPOSE_FILES run --service-ports --use-aliases --rm agent
```

`./run.sh` → locked. `./run.sh +internet` → full internet.

## Verification recipe

Always test **both** the proxy filter and the network-layer cutoff. The filter alone is not a sandbox; you must prove that bypassing the proxy fails at TCP, not at HTTP.

From inside the agent container:

```bash
# 1. Proxy whitelist
curl -sS -o /dev/null -w "allowed: %{http_code}\n" --max-time 8 https://<allowlisted-host>/
curl -sS -o /dev/null -w "denied:  %{http_code}\n" --max-time 8 https://www.google.com/ || echo "denied: blocked"

# 2. Network-layer cutoff — strip proxy env to bypass the filter.
# MUST fail with "Could not connect", NOT with HTTP 4xx. If it returns ANY
# HTTP code, the agent has a direct internet route and the sandbox is broken.
env -u HTTPS_PROXY -u HTTP_PROXY curl --max-time 5 -sS -o /dev/null \
  -w "direct: %{http_code}\n" https://1.1.1.1/ || echo "direct: blocked at network layer"
```

Expected when locked:

| target                      | result                                |
|-----------------------------|---------------------------------------|
| allowlisted host via proxy  | reaches origin (any HTTP code)        |
| non-allowlisted via proxy   | `CONNECT tunnel failed, response 403` |
| direct IP without proxy     | TCP connect failure                   |

If "direct" returns any HTTP code, the agent is not contained — re-check that its `networks:` block contains **only** the internal network and no bridge.

## When NOT to use this pattern

- If you need the agent to reach many varying hosts at runtime (development with cold caches doing `npm install`, `clojure -P`, `git clone`, etc.) the whitelist becomes a maintenance burden. Either pre-warm caches in named volumes, or maintain a broader whitelist (registry.npmjs.org, repo1.maven.org, repo.clojars.org, github.com, codeload.github.com, api.github.com, raw.githubusercontent.com).
- For TCP protocols other than HTTPS/HTTP, tinyproxy won't help. Use a TCP-aware proxy (e.g. dante for SOCKS) or per-protocol allowlisting.
- If your threat model requires SNI/host header verification, tinyproxy's regex filter on the CONNECT host is enough but is **not** a TLS-terminating inspector. For that, use mitmproxy with explicit `--allow-hosts`.
