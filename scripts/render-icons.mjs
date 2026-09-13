import { mkdir, readFile } from 'node:fs/promises';
import sharp from 'sharp';

const outputs = [
  ['artwork/icon-background.svg', 'AppScope/resources/base/media/background.png'],
  ['artwork/icon-foreground.svg', 'AppScope/resources/base/media/foreground.png'],
  ['artwork/icon-background.svg', 'entry/src/main/resources/base/media/background.png'],
  ['artwork/icon-foreground.svg', 'entry/src/main/resources/base/media/foreground.png'],
  ['artwork/app-icon.svg', 'entry/src/main/resources/base/media/startIcon.png'],
  ['artwork/app-icon.svg', 'release-assets/app-icon-1024.png']
];

for (const [source, destination] of outputs) {
  const parent = destination.slice(0, destination.lastIndexOf('/'));
  await mkdir(parent, { recursive: true });
  const svg = await readFile(source);
  await sharp(svg).resize(1024, 1024).png().toFile(destination);
}

console.log(`Rendered ${outputs.length} icon assets.`);

