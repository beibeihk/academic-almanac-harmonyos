import http from 'node:http';

const port = Number.parseInt(process.argv[2] ?? '', 10);
if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error('Usage: node ipv6-callback-proxy.mjs <port>');
}

const server = http.createServer((request, response) => {
  const headers = { ...request.headers, host: `localhost:${port}` };
  const upstream = http.request({
    host: '127.0.0.1',
    port,
    path: request.url,
    method: request.method,
    headers
  }, upstreamResponse => {
    response.writeHead(upstreamResponse.statusCode ?? 502, upstreamResponse.headers);
    upstreamResponse.pipe(response);
  });
  upstream.on('error', error => {
    response.writeHead(502, { 'content-type': 'text/plain; charset=utf-8' });
    response.end(`Callback bridge error: ${error.message}`);
  });
  request.pipe(upstream);
});

server.listen({ host: '::1', port, ipv6Only: true }, () => {
  console.log(`IPv6 callback bridge listening on [::1]:${port}`);
});

