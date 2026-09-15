import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import {
  fnv1a32,
  generateAlmanac,
  hasSevereConflict,
  localDateKey
} from '../entry/src/main/ets/model/AlmanacEngine.ts';

const dataUrl = new URL('../entry/src/main/resources/rawfile/almanac.json', import.meta.url);
const moduleUrl = new URL('../entry/src/main/module.json5', import.meta.url);
const generatedDataUrl = new URL('../entry/src/main/ets/model/AlmanacData.ts', import.meta.url);
const indexUrl = new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url);
const raw = await readFile(dataUrl, 'utf8');
const database = JSON.parse(raw);

test('JSON 文案库可完整解析且规模符合 V1', () => {
  assert.equal(database.version, '1.0.0');
  assert.ok(database.yi.length >= 50 && database.yi.length <= 60);
  assert.ok(database.ji.length >= 50 && database.ji.length <= 60);
  assert.ok(database.quotes.length >= 35 && database.quotes.length <= 40);
  assert.ok(database.times.length >= 20 && database.times.length <= 30);
  const total = database.yi.length + database.ji.length + database.quotes.length +
    database.times.length + database.fortunes.length;
  assert.ok(total >= 160 && total <= 200, `unexpected copy count: ${total}`);

  const ids = [];
  for (const group of [database.yi, database.ji, database.quotes, database.times, database.fortunes]) {
    for (const item of group) {
      assert.ok(item.id);
      ids.push(item.id);
    }
  }
  assert.equal(new Set(ids).size, ids.length, 'all ids must be unique');
});

test('稳定 hash 与日期键结果固定', () => {
  assert.equal(fnv1a32('AcademicAlmanac-v1-20260913'), 2048715165);
  assert.equal(localDateKey(new Date(2026, 8, 13, 12, 0, 0)), '20260913');
});

test('同一自然日反复生成完全一致', () => {
  const date = new Date(2026, 8, 13, 8, 30, 0);
  const first = generateAlmanac(database, date);
  for (let i = 0; i < 20; i++) {
    assert.deepEqual(generateAlmanac(database, date), first);
  }
});

test('连续 365 天生成稳定、无重复标题、无严重标签冲突', () => {
  const seenDays = new Set();
  const start = new Date(2026, 0, 1, 12, 0, 0);
  for (let offset = 0; offset < 365; offset++) {
    const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + offset, 12, 0, 0);
    const result = generateAlmanac(database, date);
    assert.equal(result.yi.length, 2);
    assert.equal(result.ji.length, 2);
    assert.equal(new Set(result.yi.map(item => item.title)).size, 2);
    assert.equal(new Set(result.ji.map(item => item.title)).size, 2);
    const yiTitles = new Set(result.yi.map(item => item.title));
    for (const item of result.ji) {
      assert.equal(yiTitles.has(item.title), false);
    }
    assert.equal(hasSevereConflict(result.yi, result.ji), false,
      `conflict on ${result.dateKey}`);
    assert.ok(result.quote.text.length > 0);
    assert.ok(result.time.time.length > 0);
    assert.ok(result.fortune.level.length > 0);
    seenDays.add(result.dateKey);
  }
  assert.equal(seenDays.size, 365);
});

test('应用模块未声明网络或敏感权限', async () => {
  const moduleText = await readFile(moduleUrl, 'utf8');
  assert.equal(/requestPermissions|ohos\.permission\./.test(moduleText), false);
});

test('首屏数据编译进 ArkTS，不依赖运行时资源读取', async () => {
  const generatedText = await readFile(generatedDataUrl, 'utf8');
  const indexText = await readFile(indexUrl, 'utf8');
  const digest = createHash('sha256').update(raw).digest('hex');
  assert.match(generatedText, new RegExp(`ALMANAC_DATA_SHA256: string = '${digest}'`));
  assert.match(indexText, /generateAlmanac\(ALMANAC_DATABASE, now\)/);
  assert.equal(/resourceManager|getRawFileContentSync|TextDecoder/.test(indexText), false);
});

test('首次启动必须明确取得并持久保存隐私同意', async () => {
  const indexText = await readFile(indexUrl, 'utf8');
  assert.match(indexText, /PersistentStorage\.persistProp\(PRIVACY_CONSENT_KEY, false\)/);
  assert.match(indexText, /@StorageLink\('privacyConsentV1'\)/);
  assert.match(indexText, /id\('privacy_overlay'\)/);
  assert.match(indexText, /id\('privacy_view_policy'\)/);
  assert.match(indexText, /id\('privacy_reject'\)/);
  assert.match(indexText, /id\('privacy_accept'\)/);
  assert.match(indexText, /if \(!this\.privacyAccepted\)/);
  assert.match(indexText, /不收集、存储、上传或共享任何个人信息/);
});
