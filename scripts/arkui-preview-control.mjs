// Official OpenHarmony Previewer named-pipe protocol:
// https://github.com/openharmony/ide_previewer/tree/master/cli
import net from 'node:net';
import path from 'node:path';
import fs from 'node:fs';
import readline from 'node:readline';
import { spawn } from 'node:child_process';

const [root, sdk, port = '40111'] = process.argv.slice(2);
if (!root || !sdk) throw new Error('Usage: node arkui-preview-control.mjs <preview project> <openharmony SDK> [port]');
const session = `almanac_${process.pid}`;
let connection;
let latestFrame;
let imageSocket;
function connectImages() {
  imageSocket = new WebSocket(`ws://127.0.0.1:${port}`);
  imageSocket.binaryType = 'arraybuffer';
  imageSocket.addEventListener('error', () => setTimeout(connectImages, 500), { once: true });
  imageSocket.addEventListener('message', (event) => {
    if (typeof event.data !== 'string') {
      const frame = Buffer.from(event.data);
      const start = frame.indexOf(Buffer.from([0xff, 0xd8, 0xff]));
      if (start >= 0) latestFrame = frame.subarray(start);
    }
  });
}
const server = net.createServer((socket) => {
  connection = socket;
  let buffered = '';
  socket.setEncoding('utf8');
  socket.on('data', (data) => {
    buffered += data;
    let end;
    while ((end = buffered.indexOf('\0')) >= 0) {
      const message = buffered.slice(0, end);
      buffered = buffered.slice(end + 1);
      try {
        const result = JSON.parse(message);
        if (result.command === 'inspector' || result.MessageType === 'inspector') {
          fs.writeFileSync(path.join(root, 'native-inspector.json'), message);
          console.log('Inspector saved: native-inspector.json');
        } else if (message.length < 1200) console.log(message);
      } catch { if (message.length < 1200) console.log(message); }
    }
  });
  console.log('Native command pipe connected');
});
await new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(`\\\\.\\pipe\\${session}_commandPipe`, resolve);
});
const bin = path.join(sdk, 'previewer/common/bin');
const intermediate = path.join(root, 'entry/.preview/default/intermediates');
const child = spawn(path.join(bin, 'Previewer.exe'), [
  '-j', path.join(intermediate, 'loader_out/default/ets'), '-s', session,
  '-cpm', 'false', '-device', 'phone', '-shape', 'rect', '-sd', '480',
  '-or', '1080', '1920', '-cr', '1080', '1920',
  '-f', path.join(root, 'entry/phoneSettingConfig_Phone.json'),
  '-n', 'entry', '-av', 'ACE_2_0', '-url', 'pages/Index', '-pages', 'main_pages',
  '-arp', path.join(intermediate, 'res/default'), '-pm', 'Stage', '-l', 'zh_CN',
  '-cm', 'light', '-o', 'portrait', '-ljPath', path.join(intermediate, 'loader/default/loader.json'),
  '-lws', port
], { cwd: bin, stdio: 'ignore', windowsHide: true });
child.on('exit', (code) => { console.log(`Previewer exited: ${code}`); process.exit(code ?? 0); });
setTimeout(connectImages, 1500);
const send = (command, args = {}, type = 'action') => {
  if (!connection) throw new Error('Native command pipe is not connected yet');
  connection.write(JSON.stringify({ version: '1.0.1', type, command, args }) + '\0');
};
console.log('Input JSON: {"click":[x,y]}, {"command":"inspector"}, or {"command":"KeyPress","args":...}');
for await (const line of readline.createInterface({ input: process.stdin })) {
  try {
    const input = JSON.parse(line);
    if (input.capture) {
      if (!latestFrame) throw new Error('No rendered image received yet');
      fs.mkdirSync(path.dirname(path.resolve(input.capture)), { recursive: true });
      fs.writeFileSync(input.capture, latestFrame);
      console.log(`Native image saved: ${path.resolve(input.capture)}`);
    } else if (input.text) {
      for (const character of input.text) {
        if (/^[a-z]$/.test(character)) {
          const keyCode = 2017 + character.charCodeAt(0) - 97;
          for (const keyAction of [0, 1]) send('KeyPress', {
            isInputMethod: false, keyCode, keyAction, pressedCodes: [keyCode], keyString: character
          });
        } else send('KeyPress', { isInputMethod: true, codePoint: character.codePointAt(0) });
        await new Promise((resolve) => setTimeout(resolve, 30));
      }
    } else if (input.click) {
      const [x, y] = input.click;
      send('MousePress', { x, y });
      await new Promise((resolve) => setTimeout(resolve, 80));
      send('MouseRelease', { x, y });
    } else send(input.command, input.args, input.type ?? 'action');
  } catch (error) { console.error(error.message); }
}
child.kill();
server.close();
