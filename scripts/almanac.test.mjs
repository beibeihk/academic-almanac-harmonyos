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
import {
  addTask, appendFocus, calendarDays, decodeWorkspace, emptyWorkspace, parseDateInput,
  remainingSeconds, removeTask, saveReview, shiftDay, summarizeDay, summarizeWeek,
  toggleFavorite, toggleTask
} from '../entry/src/main/ets/model/ResearchWorkspace.ts';

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
  assert.match(indexText, /@StorageLink\('privacyConsentV2'\)/);
  assert.match(indexText, /id\('privacy_overlay'\)/);
  assert.match(indexText, /id\('privacy_view_policy'\)/);
  assert.match(indexText, /id\('privacy_reject'\)/);
  assert.match(indexText, /id\('privacy_accept'\)/);
  assert.match(indexText, /if \(!this\.privacyAccepted\)/);
  assert.match(indexText, /只保存在应用私有的本机存储内，不上传、出售或共享/);
  assert.match(indexText, /if \(this\.privacyAccepted\) this\.loadWorkspace\(\)/);
  assert.match(indexText, /if \(this\.privacyAccepted\) \{\s*if \(this\.showAbout\)/);
});

test('真实日期校验、跨月及闰年历法正确', () => {
  assert.equal(parseDateInput('2024-02-29'), '20240229');
  assert.equal(parseDateInput('2026-02-29'), '');
  assert.equal(parseDateInput('2026-13-01'), '');
  assert.equal(parseDateInput('2026-09--17'), '');
  assert.equal(shiftDay('20261231', 1), '20270101');
  assert.equal(shiftDay('20240301', -1), '20240229');
  const month = calendarDays('20240201');
  assert.equal(month.filter(day => day.day > 0).length, 29);
  assert.equal(month[3].dateKey, '20240201');
  assert.equal(new Set(month.map(day => day.id)).size, month.length);
});

test('本地计划支持新增、去重、完成、恢复与移除，不修改旧状态', () => {
  const empty = emptyWorkspace();
  const task = { id: 't1', dateKey: '20260917', title: '读一篇论文', category: '阅读', done: false };
  const added = addTask(empty, task);
  assert.equal(empty.tasks.length, 0);
  assert.equal(added.tasks.length, 1);
  assert.equal(addTask(added, { ...task, id: 't2' }).tasks.length, 1);
  assert.equal(addTask(added, { ...task, id: 't3', title: '  ' }).tasks.length, 1);
  const done = toggleTask(added, 't1');
  assert.equal(done.tasks[0].done, true);
  assert.equal(added.tasks[0].done, false);
  assert.equal(toggleTask(done, 't1').tasks[0].done, false);
  assert.equal(removeTask(done, 't1').tasks.length, 0);
  assert.deepEqual(decodeWorkspace(JSON.stringify(done)), done);
});

test('收藏与按日回顾可持久恢复，限长且日期相互隔离', () => {
  let data = toggleFavorite(emptyWorkspace(), '20260917');
  assert.deepEqual(data.favorites, ['20260917']);
  assert.deepEqual(toggleFavorite(data, '20260917').favorites, []);
  data = saveReview(data, '20260917', '今天推进了摘要。');
  data = saveReview(data, '20260918', '下一步处理图表。');
  data = saveReview(data, '20260917', '字'.repeat(500));
  assert.equal(data.reviews.length, 2);
  assert.equal(data.reviews[0].note.length, 400);
  assert.equal(data.reviews[1].note, '下一步处理图表。');
  assert.deepEqual(decodeWorkspace(JSON.stringify(data)), data);
});

test('专注以截止时间计算，过期归零、记录幂等、七日统计隔离', () => {
  assert.equal(remainingSeconds(10000, 1000), 9);
  assert.equal(remainingSeconds(10000, 9500), 1);
  assert.equal(remainingSeconds(10000, 20000), 0);
  let data = addTask(emptyWorkspace(),
    { id: 't1', dateKey: '20260917', title: '整理文献', category: '阅读', done: false });
  data = toggleTask(data, 't1');
  const session = { id: 'f1', dateKey: '20260917', minutes: 25, category: '阅读' };
  data = appendFocus(data, session);
  data = appendFocus(data, session);
  data = appendFocus(data, { ...session, id: 'bad', minutes: -1 });
  assert.equal(data.sessions.length, 1);
  assert.deepEqual(summarizeDay(data, '20260917'),
    { dateKey: '20260917', planned: 1, completed: 1, minutes: 25 });
  assert.equal(summarizeDay(data, '20260918').minutes, 0);
  const week = summarizeWeek(data, '20260918');
  assert.equal(week.length, 7);
  assert.equal(week[0].dateKey, '20260912');
  assert.equal(week.reduce((sum, day) => sum + day.minutes, 0), 25);
  assert.deepEqual(decodeWorkspace(JSON.stringify(data)), data);
});

test('损坏或未知版本数据安全降级，异常条目不会破坏有效记录', () => {
  for (const raw of ['', 'not-json', 'null', '{}', '{"version":2}']) {
    assert.deepEqual(decodeWorkspace(raw), emptyWorkspace());
  }
  const data = emptyWorkspace();
  data.tasks = [null, { id: 'ok', dateKey: '20260917', title: '有效计划', category: '写作', done: false },
    { id: 'bad', dateKey: '20260230', title: '无效日期', category: '写作', done: false }];
  data.favorites = ['20260917', '20260917', '20260230', null];
  const recovered = decodeWorkspace(JSON.stringify(data));
  assert.equal(recovered.tasks.length, 1);
  assert.deepEqual(recovered.favorites, ['20260917']);
});

test('本机数据达到容量上限时保留全部旧记录，不静默覆盖', () => {
  let data = emptyWorkspace();
  for (let index = 0; index < 500; index++) {
    data = addTask(data, { id: `t${index}`, dateKey: '20260917', title: `目标${index}`, category: '其他', done: false });
  }
  assert.equal(addTask(data, { id: 'overflow', dateKey: '20260917', title: '溢出', category: '其他', done: false }).tasks.length, 500);
  for (let offset = 0; offset < 65; offset++) data = toggleFavorite(data, shiftDay('20260101', offset));
  assert.equal(data.favorites.length, 60);
  for (let index = 0; index < 2001; index++) {
    data = appendFocus(data, { id: `f${index}`, dateKey: '20260917', minutes: 25, category: '阅读' });
  }
  assert.equal(data.sessions.length, 2000);
  assert.equal(data.sessions[0].id, 'f0');
  assert.deepEqual(decodeWorkspace(JSON.stringify(data)), data);
});

test('四个独立功能页与编辑、计时、回顾、日期入口已接入原生 UI', async () => {
  const indexText = await readFile(indexUrl, 'utf8');
  for (const id of ['task_input', 'task_add', 'focus_start_pause', 'focus_reset', 'review_save',
    'calendar_open', 'calendar_jump', 'favorite_toggle', 'bottom_navigation', 'clear_local_records']) {
    assert.match(indexText, new RegExp(`id\\('${id}'\\)`));
  }
  assert.match(indexText, /@StorageLink\('researchWorkspaceV1'\)/);
  assert.match(indexText, /this\.workspaceRaw = JSON\.stringify\(data\)/);
  assert.match(indexText, /remainingSeconds\(this\.focusDeadline, Date\.now\(\)\)/);
  assert.match(indexText, /clearInterval\(this\.focusInterval\)/);
  assert.match(indexText, /this\.PlanPage\(\)/);
  assert.match(indexText, /this\.FocusPage\(\)/);
  assert.match(indexText, /this\.ReviewPage\(\)/);
});
