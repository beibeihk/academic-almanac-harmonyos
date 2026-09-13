export interface AlmanacItem {
  id: string;
  type: string;
  title: string;
  subtitle: string;
  tags: string[];
}

export interface QuoteItem {
  id: string;
  text: string;
}

export interface TimeItem {
  id: string;
  time: string;
  task: string;
  subtitle: string;
  tags: string[];
}

export interface FortuneItem {
  id: string;
  level: string;
  phrase: string;
}

export interface AlmanacDatabase {
  version: string;
  yi: AlmanacItem[];
  ji: AlmanacItem[];
  quotes: QuoteItem[];
  times: TimeItem[];
  fortunes: FortuneItem[];
}

export interface DailyAlmanac {
  dateKey: string;
  yi: AlmanacItem[];
  ji: AlmanacItem[];
  quote: QuoteItem;
  time: TimeItem;
  fortune: FortuneItem;
}

const CONFLICT_TAGS: string[] = [
  'review', 'submission', 'writing', 'coding', 'data', 'presentation',
  'reference', 'advisor', 'experiment', 'regression'
];

class XorShift32 {
  private state: number;

  constructor(seed: number) {
    this.state = seed === 0 ? 0x6D2B79F5 : seed >>> 0;
  }

  nextUInt(): number {
    let value: number = this.state;
    value ^= value << 13;
    value ^= value >>> 17;
    value ^= value << 5;
    this.state = value >>> 0;
    return this.state;
  }
}

export function fnv1a32(text: string): number {
  let hash: number = 0x811C9DC5;
  for (let i: number = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}

function pad2(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

export function localDateKey(date: Date): string {
  return `${date.getFullYear()}${pad2(date.getMonth() + 1)}${pad2(date.getDate())}`;
}

function preferredTags(weekday: number): string[] {
  if (weekday === 1) {
    return ['plan', 'reading', 'writing'];
  }
  if (weekday === 5) {
    return ['backup', 'finish', 'submission'];
  }
  if (weekday === 0 || weekday === 6) {
    return ['reading', 'reference', 'rest', 'ideas'];
  }
  return [];
}

function includes(values: string[], target: string): boolean {
  for (let i: number = 0; i < values.length; i++) {
    if (values[i] === target) {
      return true;
    }
  }
  return false;
}

function isConflictTag(tag: string): boolean {
  return includes(CONFLICT_TAGS, tag);
}

function hasForbiddenTag(item: AlmanacItem, forbidden: string[]): boolean {
  for (let i: number = 0; i < item.tags.length; i++) {
    if (isConflictTag(item.tags[i]) && includes(forbidden, item.tags[i])) {
      return true;
    }
  }
  return false;
}

function itemWeight(item: AlmanacItem, preferred: string[]): number {
  let weight: number = 100;
  for (let i: number = 0; i < item.tags.length; i++) {
    if (includes(preferred, item.tags[i])) {
      weight += 60;
    }
  }
  return weight;
}

function selectItems(source: AlmanacItem[], count: number, rng: XorShift32,
  weekday: number, forbiddenTags: string[]): AlmanacItem[] {
  const selected: AlmanacItem[] = [];
  const preferred: string[] = preferredTags(weekday);

  while (selected.length < count) {
    const candidates: AlmanacItem[] = [];
    for (let i: number = 0; i < source.length; i++) {
      let duplicate: boolean = false;
      for (let j: number = 0; j < selected.length; j++) {
        if (selected[j].id === source[i].id || selected[j].title === source[i].title) {
          duplicate = true;
          break;
        }
      }
      if (!duplicate && !hasForbiddenTag(source[i], forbiddenTags)) {
        candidates.push(source[i]);
      }
    }
    if (candidates.length === 0) {
      break;
    }
    let total: number = 0;
    for (let i: number = 0; i < candidates.length; i++) {
      total += itemWeight(candidates[i], preferred);
    }
    let target: number = rng.nextUInt() % total;
    let chosen: AlmanacItem = candidates[0];
    for (let i: number = 0; i < candidates.length; i++) {
      target -= itemWeight(candidates[i], preferred);
      if (target < 0) {
        chosen = candidates[i];
        break;
      }
    }
    selected.push(chosen);
  }
  return selected;
}

function selectedConflictTags(items: AlmanacItem[]): string[] {
  const result: string[] = [];
  for (let i: number = 0; i < items.length; i++) {
    for (let j: number = 0; j < items[i].tags.length; j++) {
      const tag: string = items[i].tags[j];
      if (isConflictTag(tag) && !includes(result, tag)) {
        result.push(tag);
      }
    }
  }
  return result;
}

function pickIndex(length: number, seed: number): number {
  return new XorShift32(seed).nextUInt() % length;
}

export function generateAlmanac(database: AlmanacDatabase, date: Date): DailyAlmanac {
  const key: string = localDateKey(date);
  const base: string = `AcademicAlmanac-v1-${key}`;
  const yi: AlmanacItem[] = selectItems(database.yi, 2,
    new XorShift32(fnv1a32(`${base}-yi`)), date.getDay(), []);
  const forbidden: string[] = selectedConflictTags(yi);
  const ji: AlmanacItem[] = selectItems(database.ji, 2,
    new XorShift32(fnv1a32(`${base}-ji`)), date.getDay(), forbidden);

  return {
    dateKey: key,
    yi: yi,
    ji: ji,
    quote: database.quotes[pickIndex(database.quotes.length, fnv1a32(`${base}-quote`))],
    time: database.times[pickIndex(database.times.length, fnv1a32(`${base}-time`))],
    fortune: database.fortunes[pickIndex(database.fortunes.length, fnv1a32(`${base}-fortune`))]
  };
}

const CHINESE_DIGITS: string[] = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
const WEEKDAYS: string[] = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];

function chineseNumber(value: number): string {
  if (value < 10) {
    return CHINESE_DIGITS[value];
  }
  if (value < 20) {
    return `十${value === 10 ? '' : CHINESE_DIGITS[value - 10]}`;
  }
  const tens: number = Math.floor(value / 10);
  const ones: number = value % 10;
  return `${CHINESE_DIGITS[tens]}十${ones === 0 ? '' : CHINESE_DIGITS[ones]}`;
}

export function formatChineseDate(date: Date): string {
  const yearText: string = `${date.getFullYear()}`;
  let year: string = '';
  for (let i: number = 0; i < yearText.length; i++) {
    year += CHINESE_DIGITS[Number.parseInt(yearText[i])];
  }
  return `${year}年 ${chineseNumber(date.getMonth() + 1)}月${chineseNumber(date.getDate())}日`;
}

export function formatWeekday(date: Date): string {
  return WEEKDAYS[date.getDay()];
}

export function hasSevereConflict(yi: AlmanacItem[], ji: AlmanacItem[]): boolean {
  const yiTags: string[] = selectedConflictTags(yi);
  for (let i: number = 0; i < ji.length; i++) {
    if (hasForbiddenTag(ji[i], yiTags)) {
      return true;
    }
  }
  return false;
}

