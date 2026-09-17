import fs from 'node:fs';
import path from 'node:path';

const [output, port = '40110'] = process.argv.slice(2);
if (!output || !/^\d+$/.test(port)) throw new Error('Usage: node capture-arkui-preview.mjs <output.jpg> [port]');
const socket = new WebSocket(`ws://127.0.0.1:${port}`);
socket.binaryType = 'arraybuffer';
const timeout = setTimeout(() => {
  console.error('No native preview image received within 10 seconds');
  socket.close();
  process.exitCode = 1;
}, 10000);
socket.addEventListener('error', () => {
  clearTimeout(timeout);
  process.exitCode = 1;
});
socket.addEventListener('message', (event) => {
  if (typeof event.data === 'string') return;
  const frame = Buffer.from(event.data);
  const start = frame.indexOf(Buffer.from([0xff, 0xd8, 0xff]));
  if (start < 0) return;
  fs.mkdirSync(path.dirname(path.resolve(output)), { recursive: true });
  fs.writeFileSync(output, frame.subarray(start));
  clearTimeout(timeout);
  socket.close();
  console.log(`${path.resolve(output)}\t${frame.readUInt32BE(4)}x${frame.readUInt32BE(8)}`);
});
