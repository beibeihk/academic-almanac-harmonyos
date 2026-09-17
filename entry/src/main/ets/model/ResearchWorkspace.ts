function localDateKey(date: Date): string {
  const month: number = date.getMonth() + 1;
  const day: number = date.getDate();
  return `${date.getFullYear()}${month < 10 ? '0' : ''}${month}${day < 10 ? '0' : ''}${day}`;
}

export interface ResearchTask {
  id: string;
  dateKey: string;
  title: string;
  category: string;
  done: boolean;
}

export interface FocusSession {
  id: string;
  dateKey: string;
  minutes: number;
  category: string;
}

export interface DailyReview {
  dateKey: string;
  note: string;
}

export interface WorkspaceData {
  version: number;
  tasks: ResearchTask[];
  favorites: string[];
  sessions: FocusSession[];
  reviews: DailyReview[];
}

export interface CalendarDay {
  id: string;
  dateKey: string;
  day: number;
}

export interface DaySummary {
  dateKey: string;
  planned: number;
  completed: number;
  minutes: number;
}

export function emptyWorkspace(): WorkspaceData {
  return { version: 1, tasks: [], favorites: [], sessions: [], reviews: [] };
}

export function dateFromKey(key: string): Date {
  return new Date(Number(key.substring(0, 4)), Number(key.substring(4, 6)) - 1,
    Number(key.substring(6, 8)), 12, 0, 0);
}

export function validDateKey(key: string): boolean {
  if (typeof key !== 'string' || !/^[12]\d{7}$/.test(key)) return false;
  const date: Date = dateFromKey(key);
  return localDateKey(date) === key;
}

export function parseDateInput(value: string): string {
  const input: string = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$|^\d{8}$/.test(input)) return '';
  const key: string = input.replace(/-/g, '');
  return validDateKey(key) ? key : '';
}

export function readableDate(key: string): string {
  return `${key.substring(0, 4)}.${key.substring(4, 6)}.${key.substring(6, 8)}`;
}

export function shiftDay(key: string, delta: number): string {
  const date: Date = dateFromKey(key);
  date.setDate(date.getDate() + delta);
  return localDateKey(date);
}

export function calendarDays(monthKey: string): CalendarDay[] {
  const first: Date = dateFromKey(monthKey);
  first.setDate(1);
  const days: CalendarDay[] = [];
  const padding: number = (first.getDay() + 6) % 7;
  for (let index: number = 0; index < padding; index++) {
    days.push({ id: `blank-${index}`, dateKey: '', day: 0 });
  }
  const lastDay: number = new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate();
  for (let day: number = 1; day <= lastDay; day++) {
    const key: string = localDateKey(new Date(first.getFullYear(), first.getMonth(), day, 12));
    days.push({ id: key, dateKey: key, day: day });
  }
  return days;
}

export function decodeWorkspace(raw: string): WorkspaceData {
  if (!raw || raw.length > 1000000) return emptyWorkspace();
  try {
    const stored: WorkspaceData = JSON.parse(raw) as WorkspaceData;
    if (!stored || stored.version !== 1 || !Array.isArray(stored.tasks) ||
      !Array.isArray(stored.favorites) || !Array.isArray(stored.sessions) ||
      !Array.isArray(stored.reviews)) return emptyWorkspace();
    const result: WorkspaceData = emptyWorkspace();
    for (const task of stored.tasks.slice(0, 500)) {
      if (task && typeof task.id === 'string' && task.id.length > 0 &&
        validDateKey(task.dateKey) && typeof task.title === 'string' && task.title.trim() &&
        typeof task.category === 'string' && typeof task.done === 'boolean' &&
        !result.tasks.some((item: ResearchTask) => item.id === task.id)) {
        result.tasks.push({ id: task.id.substring(0, 80), dateKey: task.dateKey,
          title: task.title.trim().substring(0, 60), category: task.category.substring(0, 12),
          done: task.done });
      }
    }
    for (const key of stored.favorites.slice(0, 60)) {
      if (validDateKey(key) && !result.favorites.includes(key)) result.favorites.push(key);
    }
    for (const session of stored.sessions.slice(0, 2000)) {
      if (session && typeof session.id === 'string' && session.id.length > 0 &&
        validDateKey(session.dateKey) && Number.isInteger(session.minutes) &&
        session.minutes >= 1 && session.minutes <= 120 && typeof session.category === 'string' &&
        !result.sessions.some((item: FocusSession) => item.id === session.id)) {
        result.sessions.push({ id: session.id.substring(0, 80), dateKey: session.dateKey,
          minutes: session.minutes, category: session.category.substring(0, 12) });
      }
    }
    for (const review of stored.reviews.slice(0, 1000)) {
      if (review && validDateKey(review.dateKey) && typeof review.note === 'string' &&
        !result.reviews.some((item: DailyReview) => item.dateKey === review.dateKey)) {
        result.reviews.push({ dateKey: review.dateKey, note: review.note.substring(0, 400) });
      }
    }
    return result;
  } catch (error) {
    return emptyWorkspace();
  }
}

function copyWorkspace(data: WorkspaceData): WorkspaceData {
  return { version: 1, tasks: data.tasks.slice(), favorites: data.favorites.slice(),
    sessions: data.sessions.slice(), reviews: data.reviews.slice() };
}

export function addTask(data: WorkspaceData, task: ResearchTask): WorkspaceData {
  const result: WorkspaceData = copyWorkspace(data);
  if (!task.title.trim() || !validDateKey(task.dateKey) || result.tasks.length >= 500 ||
    result.tasks.some((item: ResearchTask) => item.id === task.id ||
      (item.dateKey === task.dateKey && item.title === task.title.trim()))) return result;
  result.tasks.push({ id: task.id, dateKey: task.dateKey,
    title: task.title.trim().substring(0, 60), category: task.category, done: false });
  return result;
}

export function toggleTask(data: WorkspaceData, id: string): WorkspaceData {
  const result: WorkspaceData = copyWorkspace(data);
  result.tasks = result.tasks.map((task: ResearchTask): ResearchTask => {
    return { id: task.id, dateKey: task.dateKey, title: task.title, category: task.category,
      done: task.id === id ? !task.done : task.done };
  });
  return result;
}

export function removeTask(data: WorkspaceData, id: string): WorkspaceData {
  const result: WorkspaceData = copyWorkspace(data);
  result.tasks = result.tasks.filter((task: ResearchTask) => task.id !== id);
  return result;
}

export function toggleFavorite(data: WorkspaceData, key: string): WorkspaceData {
  const result: WorkspaceData = copyWorkspace(data);
  if (result.favorites.includes(key)) {
    result.favorites = result.favorites.filter((item: string) => item !== key);
  } else if (validDateKey(key) && result.favorites.length < 60) {
    result.favorites.push(key);
  }
  return result;
}

export function appendFocus(data: WorkspaceData, session: FocusSession): WorkspaceData {
  const result: WorkspaceData = copyWorkspace(data);
  if (result.sessions.length >= 2000 ||
    result.sessions.some((item: FocusSession) => item.id === session.id) ||
    !validDateKey(session.dateKey) || !Number.isInteger(session.minutes) ||
    session.minutes < 1 || session.minutes > 120) return result;
  result.sessions.push(session);
  return result;
}

export function saveReview(data: WorkspaceData, key: string, note: string): WorkspaceData {
  const result: WorkspaceData = copyWorkspace(data);
  if (!validDateKey(key)) return result;
  const review: DailyReview = { dateKey: key, note: note.substring(0, 400) };
  const index: number = result.reviews.findIndex((item: DailyReview) => item.dateKey === key);
  if (index >= 0) result.reviews[index] = review;
  else if (result.reviews.length < 1000) result.reviews.push(review);
  return result;
}

export function summarizeDay(data: WorkspaceData, key: string): DaySummary {
  const tasks: ResearchTask[] = data.tasks.filter((task: ResearchTask) => task.dateKey === key);
  let minutes: number = 0;
  for (const session of data.sessions) {
    if (session.dateKey === key) minutes += session.minutes;
  }
  return { dateKey: key, planned: tasks.length,
    completed: tasks.filter((task: ResearchTask) => task.done).length, minutes: minutes };
}

export function summarizeWeek(data: WorkspaceData, endKey: string): DaySummary[] {
  const result: DaySummary[] = [];
  for (let offset: number = -6; offset <= 0; offset++) {
    result.push(summarizeDay(data, shiftDay(endKey, offset)));
  }
  return result;
}

export function remainingSeconds(deadline: number, now: number): number {
  return Math.max(0, Math.ceil((deadline - now) / 1000));
}
