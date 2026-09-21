import { readFile, writeFile } from 'node:fs/promises';

const commonUrl = new URL('../entry/src/main/resources/rawfile/almanac.json', import.meta.url);
const disciplineUrl = new URL('../entry/src/main/resources/rawfile/discipline-corpus.json', import.meta.url);
const targetUrl = new URL('../android/app/src/main/assets/corpus-data.js', import.meta.url);

const common = JSON.parse(await readFile(commonUrl, 'utf8'));
const disciplines = JSON.parse(await readFile(disciplineUrl, 'utf8'));
if (disciplines.disciplines?.length !== 14) throw new Error('Expected 14 disciplines');

const javascript = `// Generated from the canonical offline corpus. Do not edit manually.\n` +
  `window.ALMANAC_BASE = ${JSON.stringify(common)};\n` +
  `window.DISCIPLINE_CORPUS = ${JSON.stringify(disciplines)};\n`;
await writeFile(targetUrl, javascript, 'utf8');
console.log(`Generated ${targetUrl.pathname}`);
