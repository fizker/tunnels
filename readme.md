# tunnels

Create tunnels between local servers and a remote server, so that requests
against the remote server are passed on to the local servers.

Both the Tunnel server and a CLI client is included. A DNS server is also included,
so that the Tunnel setup can function without internet access.


## Tunnel Server

Start it with `swift run tunnel-server`. It binds to port 8110 per default. This
can be changed by setting the `PORT` environment variable before starting the server.

If it is to receive normal HTTP requests, it will need to bind to port 80.
Since this is a restricted port, it might be necessary to start the server with `sudo`.

All options can also be put into a dotenv file. The system automatically loads
any file named `.env` or `env-tunnel-server`, or the name can be customized by
setting `settings_file` env var. See [env-tunnel-server-example](env-tunnel-server-example) for an example file.


## Tunnel Client

Start it with `swift run tunnel-client --proxies example.com=8080 foo.example.com=8081`
to have a client that proxies those two domains to the given local ports.

The client will automatically connect to a server running on localhost:8110.
To change this, pass the `--server` option followed by the full address to the TunnelServer.


## DNS Server

The DNS server checks against requests for a limited set of known hosts. Any other
requests are proxied to another server. The default proxy server is the
[CloudFlare public DNS resolver](https://developers.cloudflare.com/1.1.1.1/).

See `sudo swift run dns-server --help` for a full set of options.

`sudo` is typically required because it is necessary to bind against port 53, and
once it have been compiled with `sudo`, build artifacts are owned by `root` so
non-`sudo` builds will fail since the files cannot be overwritten by the compiler.


### Starting the server

`sudo swift run dns-server [<port>] -d example.com=127.0.0.1 foo.example.com=168.192.1.2`

The server defaults to run on port 53, which is the default DNS port. This is a
restricted port, so in order to bind to this port, the server must be started with
root access (or `sudo`).

Since it is not possible to configure which port to aim DNS requests at, it should
typically be bound to port 53.


### Sending DNS requests

To send a request against a DNS server running on localhost:

- `nslookup foo.example.com 127.0.0.1`
- `dig @127.0.0.1  -4 +noedns foo.example.com`
