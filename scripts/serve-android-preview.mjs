import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';

const root = new URL('../android/app/src/main/assets/', import.meta.url);
const allowed = new Map([
  ['/', ['index.html', 'text/html; charset=utf-8']],
  ['/index.html', ['index.html', 'text/html; charset=utf-8']],
  ['/corpus-data.js', ['corpus-data.js', 'text/javascript; charset=utf-8']]
]);
const port = Number(process.env.ACADEMIC_PREVIEW_PORT || 8765);
const server = createServer(async (request, response) => {
  const file = allowed.get(new URL(request.url || '/', 'http://localhost').pathname);
  if (!file) {
    response.writeHead(404);
    response.end('Not found');
    return;
  }
  try {
    const body = await readFile(new URL(file[0], root));
    response.writeHead(200, {
      'Content-Type': file[1],
      'Cache-Control': 'no-store',
      'Content-Security-Policy': "default-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'"
    });
    response.end(body);
  } catch {
    response.writeHead(500);
    response.end('Preview unavailable');
  }
});
server.listen(port, '127.0.0.1', () => console.log(`Android preview http://127.0.0.1:${port}`));
