import {
  AlmanacItem,
  DailyAlmanac,
  formatChineseDate,
  formatWeekday,
  generateAlmanac,
  disciplineNames,
  isKnownDiscipline,
  localDateKey
} from '../model/AlmanacEngine';
import { ALMANAC_DATABASE } from '../model/AlmanacData';
import {
  CalendarDay, DailyReview, DaySummary, ResearchTask, WorkspaceData,
  addTask, appendFocus, calendarDays, dateFromKey, decodeWorkspace, emptyWorkspace,
  parseDateInput, readableDate, remainingSeconds, removeTask, saveReview,
  shiftDay, summarizeDay, summarizeWeek, toggleFavorite, toggleTask
} from '../model/ResearchWorkspace';

const PAPER: ResourceColor = '#F7F2E8';
const PAPER_CARD: ResourceColor = '#FFFCF5';
const INK: ResourceColor = '#26221D';
const MUTED: ResourceColor = '#766E64';
const CINNABAR: ResourceColor = '#A63228';
const LINE: ResourceColor = '#DDD2C1';
const PRIVACY_CONSENT_KEY: string = 'privacyConsentV2';
const WORKSPACE_KEY: string = 'researchWorkspaceV1';
const DISCIPLINE_KEY: string = 'academicDisciplineV1';

PersistentStorage.persistProp(PRIVACY_CONSENT_KEY, false);
PersistentStorage.persistProp(WORKSPACE_KEY, '');
PersistentStorage.persistProp(DISCIPLINE_KEY, '');

@Entry
@Component
struct Index {
  @StorageLink('privacyConsentV2') private privacyAccepted: boolean = false;
  @StorageLink('researchWorkspaceV1') private workspaceRaw: string = '';
  @StorageLink('academicDisciplineV1') private selectedDiscipline: string = '';
  @StorageLink('almanacForegroundTick') @Watch('handleForeground') private foregroundTick: number = 0;
  @State private almanac: DailyAlmanac | null = null;
  @State private dateText: string = '';
  @State private weekdayText: string = '';
  @State private visibleDateKey: string = '';
  @State private showAbout: boolean = false;
  @State private showPrivacyDetails: boolean = false;
  @State private privacyRejected: boolean = false;
  @State private activeSection: number = 0;
  @State private showDisciplinePicker: boolean = false;
  @State private disciplineDraft: string = '';
  @State private selectedDateKey: string = localDateKey(new Date());
  @State private workspace: WorkspaceData = emptyWorkspace();
  @State private showCalendar: boolean = false;
  @State private calendarMonth: string = localDateKey(new Date());
  @State private dateInput: string = '';
  @State private calendarError: string = '';
  @State private taskInput: string = '';
  @State private taskCategory: string = '写作';
  @State private allTasks: boolean = false;
  @State private pendingDelete: string = '';
  @State private feedback: string = '';
  @State private reviewText: string = '';
  @State private focusDuration: number = 25;
  @State private focusRemaining: number = 1500;
  @State private focusRunning: boolean = false;
  @State private focusCategory: string = '写作';
  @State private focusTarget: string = '';
  private categories: string[] = ['阅读', '写作', '代码', '实验', '其他'];
  private focusDurations: number[] = [15, 25, 45, 60];
  private tabLabels: string[] = ['黄历', '计划', '专注', '回顾'];
  private weekLabels: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  private disciplineOptions: string[] = disciplineNames(ALMANAC_DATABASE);
  private focusDeadline: number = 0;
  private focusInterval: number = -1;
  private focusId: string = '';
  private idSequence: number = 0;
  private todayKey: string = '';

  aboutToAppear(): void {
    if (this.selectedDiscipline && !isKnownDiscipline(ALMANAC_DATABASE, this.selectedDiscipline)) {
      this.selectedDiscipline = '';
    }
    this.disciplineDraft = this.selectedDiscipline;
    this.refreshForToday();
    if (this.privacyAccepted) this.loadWorkspace();
  }

  onPageShow(): void {
    this.refreshForToday();
    this.tickFocus();
  }

  private handleForeground(): void {
    this.refreshForToday();
    this.tickFocus();
  }

  aboutToDisappear(): void {
    this.stopInterval();
  }

  onBackPress(): boolean {
    if (!this.privacyAccepted) {
      if (this.showPrivacyDetails) {
        this.showPrivacyDetails = false;
        return true;
      }
      return false;
    }
    if (this.showDisciplinePicker) {
      if (this.selectedDiscipline) this.showDisciplinePicker = false;
      return true;
    }
    if (this.showCalendar) this.showCalendar = false;
    else if (this.showPrivacyDetails) this.showPrivacyDetails = false;
    else if (this.showAbout) this.showAbout = false;
    else if (this.activeSection !== 0) this.activeSection = 0;
    else return false;
    return true;
  }

  private refreshForToday(): void {
    const now: Date = new Date();
    const key: string = localDateKey(now);
    if (this.todayKey && this.todayKey !== key && this.selectedDateKey === this.todayKey) {
      this.selectedDateKey = key;
    }
    this.todayKey = key;
    if (this.selectedDateKey === key && this.visibleDateKey !== key) {
      this.almanac = generateAlmanac(ALMANAC_DATABASE, now, this.selectedDiscipline);
      this.updateDateLabels(now);
      this.loadReview();
    } else if (this.almanac === null) {
      this.changeDate(this.selectedDateKey);
    }
  }

  private updateDateLabels(date: Date): void {
    this.dateText = formatChineseDate(date);
    this.weekdayText = formatWeekday(date);
    this.visibleDateKey = localDateKey(date);
  }

  private changeDate(key: string): void {
    if (!parseDateInput(key)) return;
    const date: Date = dateFromKey(key);
    try {
      this.almanac = generateAlmanac(ALMANAC_DATABASE, date, this.selectedDiscipline);
      this.selectedDateKey = key;
      this.updateDateLabels(date);
      this.loadReview();
      this.pendingDelete = '';
      this.feedback = '';
    } catch (error) {
      console.error(`Failed to generate almanac: ${JSON.stringify(error)}`);
    }
  }

  private acceptPrivacy(): void {
    this.privacyAccepted = true;
    this.showPrivacyDetails = false;
    this.privacyRejected = false;
    this.loadWorkspace();
  }

  private loadWorkspace(): void {
    this.workspace = decodeWorkspace(this.workspaceRaw);
    this.loadReview();
  }

  private loadReview(): void {
    const review: DailyReview | undefined = this.workspace.reviews.find(
      (item: DailyReview) => item.dateKey === this.selectedDateKey);
    this.reviewText = review ? review.note : '';
  }

  private persistWorkspace(data: WorkspaceData): void {
    if (!this.privacyAccepted) return;
    this.workspace = data;
    this.workspaceRaw = JSON.stringify(data);
  }

  private saveDiscipline(): void {
    if (!isKnownDiscipline(ALMANAC_DATABASE, this.disciplineDraft)) return;
    this.selectedDiscipline = this.disciplineDraft;
    this.showDisciplinePicker = false;
    this.changeDate(this.selectedDateKey);
    this.feedback = `已切换为${this.selectedDiscipline}，日签将混合通用与本学科内容。`;
  }

  private openDisciplinePicker(): void {
    this.disciplineDraft = this.selectedDiscipline;
    this.showDisciplinePicker = true;
  }

  private nextId(prefix: string): string {
    this.idSequence++;
    return `${prefix}-${Date.now()}-${this.idSequence}`;
  }

  private createTask(title: string): void {
    const value: string = title.trim();
    if (!value) {
      this.feedback = '先写下一个具体的小目标。';
      return;
    }
    if (this.workspace.tasks.length >= 500) {
      this.feedback = '已达 500 条计划上限，请先移除不再需要的计划。';
      return;
    }
    const data: WorkspaceData = addTask(this.workspace, { id: this.nextId('task'),
      dateKey: this.selectedDateKey, title: value, category: this.taskCategory, done: false });
    const added: boolean = data.tasks.length > this.workspace.tasks.length;
    this.persistWorkspace(data);
    this.feedback = added ? '已加入计划，可在「计划」中完成或开始专注。' : '这个日期已经有同名计划。';
    if (added) this.taskInput = '';
  }

  private visibleTasks(): ResearchTask[] {
    return this.workspace.tasks.filter((task: ResearchTask) =>
      this.allTasks || task.dateKey === this.selectedDateKey);
  }

  private favoriteDate(): void {
    if (!this.workspace.favorites.includes(this.selectedDateKey) && this.workspace.favorites.length >= 60) {
      this.feedback = '最多收藏 60 天，请先取消一个不再需要的收藏。';
      return;
    }
    this.persistWorkspace(toggleFavorite(this.workspace, this.selectedDateKey));
    this.feedback = this.workspace.favorites.includes(this.selectedDateKey) ?
      '已收藏，可在「回顾」中重读。' : '已取消收藏。';
  }

  private openCalendar(): void {
    this.calendarMonth = this.selectedDateKey.substring(0, 6) + '01';
    this.dateInput = `${this.selectedDateKey.substring(0, 4)}-${this.selectedDateKey.substring(4, 6)}-${this.selectedDateKey.substring(6, 8)}`;
    this.calendarError = '';
    this.showCalendar = true;
  }

  private changeMonth(delta: number): void {
    const date: Date = dateFromKey(this.calendarMonth);
    date.setMonth(date.getMonth() + delta, 1);
    const key: string = localDateKey(date);
    if (parseDateInput(key)) this.calendarMonth = key;
  }

  private saveCurrentReview(): void {
    if (this.workspace.reviews.length >= 1000 && !this.workspace.reviews.some(
      (item: DailyReview) => item.dateKey === this.selectedDateKey)) {
      this.feedback = '已达 1000 天回顾上限，旧记录仍保存在本机。';
      return;
    }
    this.persistWorkspace(saveReview(this.workspace, this.selectedDateKey, this.reviewText));
    this.feedback = '回顾已保存在本机。切换日期可查看以前的记录。';
  }

  private stopInterval(): void {
    if (this.focusInterval >= 0) clearInterval(this.focusInterval);
    this.focusInterval = -1;
  }

  private tickFocus(): void {
    if (!this.focusRunning) return;
    this.focusRemaining = remainingSeconds(this.focusDeadline, Date.now());
    if (this.focusRemaining === 0) {
      this.focusRunning = false;
      this.stopInterval();
      this.persistWorkspace(appendFocus(this.workspace, { id: this.focusId,
        dateKey: localDateKey(new Date(this.focusDeadline)), minutes: this.focusDuration, category: this.focusCategory }));
      this.feedback = `这一段完成了，已记录 ${this.focusDuration} 分钟专注。起身休息一下。`;
    }
  }

  private switchFocus(): void {
    if (this.focusRunning) {
      this.tickFocus();
      this.focusRunning = false;
      this.stopInterval();
      return;
    }
    if (this.workspace.sessions.length >= 2000) {
      this.feedback = '已达 2000 段专注记录上限，旧记录仍保存在本机。';
      return;
    }
    if (this.focusRemaining <= 0) this.focusRemaining = this.focusDuration * 60;
    if (this.focusRemaining === this.focusDuration * 60) this.focusId = this.nextId('focus');
    this.focusDeadline = Date.now() + this.focusRemaining * 1000;
    this.focusRunning = true;
    this.feedback = '';
    this.stopInterval();
    this.focusInterval = setInterval(() => { this.tickFocus(); this.refreshForToday(); }, 1000);
  }

  private resetFocus(minutes: number): void {
    if (this.focusRunning) return;
    this.stopInterval();
    this.focusDuration = minutes;
    this.focusRemaining = minutes * 60;
    this.focusId = '';
    this.feedback = '已重置；未完成的时段不计入专注记录。';
  }

  private focusTime(): string {
    const minutes: number = Math.floor(this.focusRemaining / 60);
    const seconds: number = this.focusRemaining % 60;
    return `${minutes < 10 ? '0' : ''}${minutes}:${seconds < 10 ? '0' : ''}${seconds}`;
  }

  private beginTaskFocus(task: ResearchTask): void {
    if (this.focusRunning || this.focusRemaining !== this.focusDuration * 60) {
      this.feedback = '请先在「专注」中暂停并重置当前时段，再切换目标。';
      return;
    }
    this.focusTarget = task.title;
    this.focusCategory = task.category;
    this.activeSection = 2;
    this.feedback = '计划已带入，点击「开始专注」启动计时。';
  }

  private favoriteQuote(key: string): string {
    return generateAlmanac(ALMANAC_DATABASE, dateFromKey(key), this.selectedDiscipline).quote.text;
  }

  @Builder
  private PrivacyConsentCard() {
    Column({ space: 13 }) {
      Text(this.privacyRejected ? '需要您的同意' : '隐私保护提示')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(INK)
        .width('100%')

      if (this.privacyRejected) {
        Text('您尚未同意隐私政策，因此暂时不能进入应用主功能。学术黄历不会在您同意前处理任何个人信息。')
          .fontSize(14)
          .lineHeight(23)
          .fontColor(INK)
          .width('100%')
      } else {
        Text('欢迎使用学术黄历。请您在使用前认真阅读并理解《隐私政策》。')
          .fontSize(15)
          .lineHeight(24)
          .fontColor(INK)
          .width('100%')
        Text('本应用无需注册登录，全部功能离线运行；您选择的学科门类及填写的计划、回顾、收藏和专注记录仅保存在本机，不上传或共享；不申请敏感权限，不含广告与第三方统计 SDK。')
          .fontSize(13)
          .lineHeight(22)
          .fontColor(MUTED)
          .width('100%')
      }

      Text('查看完整《隐私政策》')
        .id('privacy_view_policy')
        .fontSize(14)
        .fontColor(CINNABAR)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .onClick(() => this.showPrivacyDetails = true)

      if (this.privacyRejected) {
        Button('重新阅读并选择')
          .id('privacy_reconsider')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(CINNABAR)
          .borderRadius(18)
          .width('100%')
          .height(40)
          .onClick(() => this.privacyRejected = false)
      } else {
        Row({ space: 10 }) {
          Button('暂不同意')
            .id('privacy_reject')
            .fontSize(14)
            .fontColor(MUTED)
            .backgroundColor('#EFE7DA')
            .borderRadius(18)
            .layoutWeight(1)
            .height(40)
            .onClick(() => this.privacyRejected = true)
          Button('同意并继续')
            .id('privacy_accept')
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor(CINNABAR)
            .borderRadius(18)
            .layoutWeight(1)
            .height(40)
            .onClick(() => this.acceptPrivacy())
        }
        .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('88%')
    .padding({ left: 20, right: 20, top: 22, bottom: 20 })
    .backgroundColor(PAPER_CARD)
    .borderRadius(18)
    .border({ width: 1, color: LINE })
  }

  @Builder
  private PrivacyPolicyCard() {
    Column({ space: 12 }) {
      Text('学术黄历隐私政策')
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor(INK)
        .width('100%')
      Text('生效及更新日期：2026年9月21日')
        .fontSize(11)
        .fontColor(MUTED)
        .width('100%')

      Scroll() {
        Column({ space: 12 }) {
          Text('1. 信息处理').fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
          Text('本应用不要求注册或登录。每日黄历依据设备本地日期、您主动选择的学科门类与内置原创文案生成。学科选择、计划与回顾，以及收藏日期、已完成专注的日期、时长和分类，只保存在应用私有的本机存储内，不上传、出售或共享。请勿填写不必要的敏感信息。')
            .fontSize(13).lineHeight(21).fontColor(INK)
          Text('2. 设备权限与联网').fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
          Text('本应用不申请位置、通讯录、相机、麦克风、照片、存储或设备标识符等权限，核心功能无需联网，不含广告及第三方统计 SDK。')
            .fontSize(13).lineHeight(21).fontColor(INK)
          Text('3. 数据共享与保存').fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
          Text('本应用没有服务器，没有向第三方提供数据或传输至境外的功能。本机保存隐私同意状态、一个学科门类选择、最多500条计划、60天收藏、2000段专注记录及1000天回顾（每条最多400字）。达到上限会提示，不会静默覆盖旧记录。未完成计时只在本次运行内保存，结束应用后重置。')
            .fontSize(13).lineHeight(21).fontColor(INK)
          Text('4. 您的权利').fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
          Text('您可选择不同意并停止使用，可随时修改学科门类，也可修改或移除自己的计划、取消收藏、编辑回顾。在关于页确认「清除本机记录」可删除学科选择、全部计划、收藏、专注及回顾；卸载应用也会清除本机数据和同意状态。')
            .fontSize(13).lineHeight(21).fontColor(INK)
          Text('5. 联系我们').fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
          Text('如对本政策有疑问，请联系：huangkun123huang@163.com')
            .fontSize(13).lineHeight(21).fontColor(INK)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      Button(this.privacyAccepted ? '返回应用' : '返回并继续选择')
        .id('privacy_details_back')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor(CINNABAR)
        .borderRadius(18)
        .width('100%')
        .height(40)
        .onClick(() => this.showPrivacyDetails = false)
    }
    .alignItems(HorizontalAlign.Start)
    .width('88%')
    .height('82%')
    .padding({ left: 20, right: 20, top: 22, bottom: 18 })
    .backgroundColor(PAPER_CARD)
    .borderRadius(18)
    .border({ width: 1, color: LINE })
  }

  @Builder
  private PrivacyOverlay() {
    Column() {
      if (this.showPrivacyDetails) {
        this.PrivacyPolicyCard()
      } else {
        this.PrivacyConsentCard()
      }
    }
    .id('privacy_overlay')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
  }

  @Builder
  private DisciplineOverlay() {
    Column() {
      Column({ space: 12 }) {
        Text('选择你的学科门类')
          .fontSize(23)
          .fontWeight(FontWeight.Bold)
          .fontColor(INK)
          .width('100%')
        Text('日签会混合通用科研建议与所选学科的专属内容。选择仅保存在本机，可随时在“关于”中修改。')
          .fontSize(13)
          .lineHeight(21)
          .fontColor(MUTED)
          .width('100%')
        Grid() {
          ForEach(this.disciplineOptions, (discipline: string) => {
            GridItem() {
              Button(discipline, { type: ButtonType.Normal })
                .id(`discipline_option_${discipline}`)
                .fontSize(14)
                .fontColor(this.disciplineDraft === discipline ? Color.White : INK)
                .backgroundColor(this.disciplineDraft === discipline ? CINNABAR : '#EFE7DA')
                .borderRadius(10)
                .height(43)
                .width('100%')
                .onClick(() => this.disciplineDraft = discipline)
            }
          }, (discipline: string) => discipline)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .height(350)
        .width('100%')
        Button(this.disciplineDraft ? `确认选择 · ${this.disciplineDraft}` : '请选择一个学科门类')
          .id('discipline_confirm')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.disciplineDraft ? CINNABAR : '#B8AEA3')
          .borderRadius(18)
          .height(42)
          .width('100%')
          .enabled(!!this.disciplineDraft)
          .onClick(() => this.saveDiscipline())
        if (this.selectedDiscipline) {
          Button('取消修改', { type: ButtonType.Normal })
            .fontSize(13)
            .fontColor(MUTED)
            .backgroundColor(Color.Transparent)
            .height(32)
            .onClick(() => this.showDisciplinePicker = false)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('90%')
      .padding({ left: 18, right: 18, top: 20, bottom: 16 })
      .backgroundColor(PAPER_CARD)
      .borderRadius(18)
      .border({ width: 1, color: LINE })
    }
    .id('discipline_overlay')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
  }

  @Builder
  private AlmanacRow(item: AlmanacItem) {
    Column({ space: 2 }) {
      Row() {
        Text(item.title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(INK)
          .maxLines(1).layoutWeight(1)
        if (item.type === 'yi') {
          Button('+ 计划', { type: ButtonType.Normal }).fontSize(11).fontColor(CINNABAR)
            .backgroundColor(Color.Transparent).height(25).padding({ left: 4, right: 0 })
            .onClick(() => this.createTask(item.title))
        }
      }.width('100%')
      Text(item.subtitle)
        .fontSize(12)
        .fontColor(MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  private SectionCard(mark: string, items: AlmanacItem[]) {
    Row({ space: 12 }) {
      Text(mark)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(CINNABAR)
        .width(30)
        .textAlign(TextAlign.Center)
      Column({ space: 9 }) {
        if (items.length > 0) {
          this.AlmanacRow(items[0])
        }
        if (items.length > 1) {
          Divider().color(LINE).strokeWidth(0.5)
          this.AlmanacRow(items[1])
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 11, bottom: 11 })
    .backgroundColor(PAPER_CARD)
    .border({ width: 1, color: LINE })
    .borderRadius(12)
  }

  @Builder
  private MainPage() {
    Scroll() {
      Column({ space: 10 }) {
        Row() {
          Column({ space: 1 }) {
            Text('学术黄历')
              .fontSize(27)
              .fontWeight(FontWeight.Bold)
              .fontColor(INK)
              .letterSpacing(2)
            Text('ACADEMIC ALMANAC')
              .fontSize(10)
              .fontColor(MUTED)
              .letterSpacing(2.3)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('关于', { type: ButtonType.Normal })
            .id('about_button')
            .fontSize(11)
            .fontColor(MUTED)
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: LINE })
            .borderRadius(14)
            .height(28)
            .padding({ left: 10, right: 10 })
            .onClick(() => this.showAbout = true)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          Text(this.dateText).fontSize(14).fontColor(INK)
          Blank()
          Text(this.weekdayText).fontSize(13).fontColor(MUTED)
        }
        .width('100%')

        Row({ space: 6 }) {
          Text('学科').fontSize(11).fontColor(MUTED)
          Text(this.selectedDiscipline).fontSize(12).fontColor(CINNABAR)
            .fontWeight(FontWeight.Medium)
          Text('通用＋专属语料').fontSize(10).fontColor('#9A9187')
        }
        .id('discipline_badge')
        .width('100%')

        Divider().color(CINNABAR).strokeWidth(1)

        if (this.almanac !== null) {
          Row({ space: 14 }) {
            Column({ space: 3 }) {
              Text(this.selectedDateKey === localDateKey(new Date()) ? '今日学术签' : '当日学术签')
                .fontSize(12)
                .fontColor(MUTED)
              Text(this.almanac.fortune.phrase)
                .fontSize(13)
                .fontColor(INK)
                .maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column() {
              Text(this.almanac.fortune.level)
                .fontSize(this.almanac.fortune.level.length > 2 ? 18 : 22)
                .fontWeight(FontWeight.Bold)
                .fontColor(CINNABAR)
            }
            .justifyContent(FlexAlign.Center)
            .width(64)
            .height(64)
            .border({ width: 2, color: CINNABAR })
            .borderRadius(8)
          }
          .width('100%')
          .padding({ left: 16, right: 12, top: 10, bottom: 10 })
          .backgroundColor('#F2E7D8')
          .borderRadius(12)

          this.SectionCard('宜', this.almanac.yi)
          this.SectionCard('忌', this.almanac.ji)

          Column({ space: 4 }) {
            Row() {
              Text('吉时').fontSize(12).fontColor(CINNABAR).fontWeight(FontWeight.Bold)
              Blank()
              Text(this.almanac.time.time).fontSize(15).fontColor(INK).fontWeight(FontWeight.Medium)
            }
            .width('100%')
            Text(this.almanac.time.task).fontSize(15).fontColor(INK).fontWeight(FontWeight.Medium)
            Text(this.almanac.time.subtitle).fontSize(12).fontColor(MUTED).maxLines(1)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ left: 15, right: 15, top: 10, bottom: 10 })
          .backgroundColor(PAPER_CARD)
          .border({ width: 1, color: LINE })
          .borderRadius(12)

          Column({ space: 5 }) {
            Text('今日签文').fontSize(11).fontColor(CINNABAR).fontWeight(FontWeight.Bold)
            Text(`“${this.almanac.quote.text}”`)
              .fontSize(16)
              .fontColor(INK)
              .fontStyle(FontStyle.Italic)
              .maxLines(2)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 9, bottom: 9 })
          .alignItems(HorizontalAlign.Center)

          Text('科研趣味内容 · 仅供娱乐')
            .fontSize(10)
            .fontColor('#9A9187')
            .width('100%')
            .textAlign(TextAlign.Center)
          Row({ space: 8 }) {
            Button('选择日期', { type: ButtonType.Normal }).id('calendar_open')
              .fontSize(12).fontColor(CINNABAR).backgroundColor('#EFE7DA').borderRadius(8)
              .layoutWeight(1).onClick(() => this.openCalendar())
            Button(this.workspace.favorites.includes(this.selectedDateKey) ? '已收藏' : '收藏日签',
              { type: ButtonType.Normal }).id('favorite_toggle').fontSize(12).fontColor(CINNABAR)
              .backgroundColor('#EFE7DA').borderRadius(8).layoutWeight(1).onClick(() => this.favoriteDate())
            Button('今日', { type: ButtonType.Normal }).id('today_button').fontSize(12).fontColor(CINNABAR)
              .backgroundColor('#EFE7DA').borderRadius(8).width(54).padding(0)
              .onClick(() => this.changeDate(localDateKey(new Date())))
          }.width('100%')
          this.FeedbackText()
        } else {
          Text('正在翻阅今日学术运势…')
            .fontSize(14)
            .fontColor(MUTED)
            .margin({ top: 80 })
        }
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 14, bottom: 12 })
    }
    .id('almanac_scroll')
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None)
    .backgroundColor(PAPER)
  }

  @Builder
  private FeedbackText() {
    if (this.feedback) {
      Text(this.feedback).id('action_feedback').fontSize(12).fontColor(CINNABAR)
        .lineHeight(19).width('100%')
    }
  }

  @Builder
  private PageHeading(title: string, subtitle: string) {
    Row() {
      Column({ space: 5 }) {
        Text(title).fontSize(26).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
        Text(subtitle).fontSize(12).fontColor(MUTED).width('100%')
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Button('关于', { type: ButtonType.Normal }).fontSize(12).fontColor(MUTED)
        .backgroundColor(Color.Transparent).onClick(() => this.showAbout = true)
    }.width('100%')
  }

  @Builder
  private DateNavigation() {
    Row({ space: 8 }) {
      Button('‹', { type: ButtonType.Normal }).id('previous_day').fontSize(22)
        .fontColor(CINNABAR).backgroundColor(Color.Transparent).width(32).padding(0)
        .onClick(() => this.changeDate(shiftDay(this.selectedDateKey, -1)))
      Button(`${readableDate(this.selectedDateKey)} · ${this.weekdayText}`,
        { type: ButtonType.Normal }).id('date_select').fontSize(13).fontColor(INK)
        .backgroundColor(PAPER_CARD).borderRadius(10).layoutWeight(1)
        .onClick(() => this.openCalendar())
      Button('›', { type: ButtonType.Normal }).id('next_day').fontSize(22)
        .fontColor(CINNABAR).backgroundColor(Color.Transparent).width(32).padding(0)
        .onClick(() => this.changeDate(shiftDay(this.selectedDateKey, 1)))
    }.width('100%')
  }

  @Builder
  private CategoryPicker(forFocus: boolean) {
    Row({ space: 5 }) {
      ForEach(this.categories, (category: string) => {
        Button(category, { type: ButtonType.Normal }).fontSize(12).layoutWeight(1).padding(0)
          .fontColor((forFocus ? this.focusCategory : this.taskCategory) === category ? Color.White : MUTED)
          .backgroundColor((forFocus ? this.focusCategory : this.taskCategory) === category ? CINNABAR : '#EFE7DA')
          .borderRadius(8).height(33)
          .enabled(!forFocus || (!this.focusRunning && this.focusRemaining === this.focusDuration * 60))
          .onClick(() => {
            if (forFocus) this.focusCategory = category;
            else this.taskCategory = category;
          })
      }, (category: string) => category)
    }.width('100%')
  }

  @Builder
  private TaskCard(task: ResearchTask) {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        Button(task.done ? '✓' : '○', { type: ButtonType.Normal })
          .id(`task_done_${task.id}`).fontSize(21).width(35).height(35).borderRadius(8).padding(0)
          .fontColor(task.done ? Color.White : CINNABAR)
          .backgroundColor(task.done ? CINNABAR : '#EFE7DA')
          .accessibilityText(task.done ? '标记为未完成' : '标记为已完成')
          .onClick(() => { this.persistWorkspace(toggleTask(this.workspace, task.id)); this.pendingDelete = ''; })
        Column({ space: 4 }) {
          Text(task.title).fontSize(15).fontColor(task.done ? MUTED : INK).maxLines(3).width('100%')
            .decoration({ type: task.done ? TextDecorationType.LineThrough : TextDecorationType.None })
          Text(`${task.category} · ${readableDate(task.dateKey)} · ${task.done ? '已完成' : '待推进'}`)
            .fontSize(11).fontColor(MUTED)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      }.width('100%')
      Row() {
        if (!task.done) {
          Button('带入专注', { type: ButtonType.Normal }).fontSize(12).fontColor(CINNABAR)
            .backgroundColor(Color.Transparent).padding(0).height(26)
            .onClick(() => this.beginTaskFocus(task))
        }
        Blank()
        Button(this.pendingDelete === task.id ? '确认移除' : '移除', { type: ButtonType.Normal })
          .fontSize(11).fontColor(MUTED).backgroundColor(Color.Transparent).height(26).padding(0)
          .onClick(() => {
            if (this.pendingDelete === task.id) {
              this.persistWorkspace(removeTask(this.workspace, task.id));
              this.pendingDelete = '';
              this.feedback = '计划已移除。';
            } else {
              this.pendingDelete = task.id;
              this.feedback = '再次点击「确认移除」会删除这条计划；点击其他页面可取消。';
            }
          })
      }.width('100%')
    }.width('100%').padding(14).backgroundColor(PAPER_CARD)
      .borderRadius(12).border({ width: 1, color: LINE })
  }

  @Builder
  private PlanPage() {
    Scroll() {
      Column({ space: 14 }) {
        this.PageHeading('科研计划', '把一个大目标，拆成今天能做的一小步。')
        this.DateNavigation()
        Column({ space: 10 }) {
          Text('新增一个小目标').fontSize(15).fontWeight(FontWeight.Medium).fontColor(INK)
          TextInput({ text: this.taskInput, placeholder: '例如：读完一篇文献并写三句笔记' })
            .id('task_input').maxLength(60).fontSize(14).backgroundColor('#F2ECE2')
            .onChange((value: string) => this.taskInput = value)
          this.CategoryPicker(false)
          Button('加入当日计划').id('task_add').width('100%').height(40)
            .fontSize(14).fontColor(Color.White).backgroundColor(CINNABAR)
            .onClick(() => this.createTask(this.taskInput))
          Text('最多 500 条 · 仅保存在本机').fontSize(10).fontColor(MUTED)
        }.width('100%').alignItems(HorizontalAlign.Start).padding(16).backgroundColor(PAPER_CARD)
          .borderRadius(12).border({ width: 1, color: LINE })
        this.FeedbackText()
        Row() {
          Text(`${this.allTasks ? '全部' : '当日'}计划 · ${this.visibleTasks().length} 条`)
            .fontSize(16).fontWeight(FontWeight.Medium).fontColor(INK).layoutWeight(1)
          Button(this.allTasks ? '只看当日' : '查看全部', { type: ButtonType.Normal })
            .id('task_filter').fontSize(12).fontColor(CINNABAR).backgroundColor(Color.Transparent)
            .onClick(() => { this.allTasks = !this.allTasks; this.pendingDelete = ''; })
        }.width('100%')
        if (this.visibleTasks().length === 0) {
          Column({ space: 8 }) {
            Text('先完成一件小事').fontSize(18).fontColor(INK)
            Text('写下自己的计划，也可以把黄历中的「宜」一键加入。')
              .fontSize(13).lineHeight(21).fontColor(MUTED).textAlign(TextAlign.Center)
          }.width('100%').padding(24).backgroundColor(PAPER_CARD).borderRadius(12)
        } else {
          ForEach(this.visibleTasks(), (task: ResearchTask) => { this.TaskCard(task) },
            (task: ResearchTask) => task.id)
        }
      }.width('100%').padding(18).alignItems(HorizontalAlign.Start)
    }.id('plan_scroll').width('100%').layoutWeight(1).scrollBar(BarState.Auto).backgroundColor(PAPER)
  }

  @Builder
  private FocusPage() {
    Scroll() {
      Column({ space: 18 }) {
        this.PageHeading('专注一段', '暂时不判断论文命运，先把这一段做完。')
        Column({ space: 18 }) {
          Text(this.focusRunning ? '专注进行中' : (this.focusRemaining === 0 ? '已完成这一段' :
            (this.focusRemaining < this.focusDuration * 60 ? '已暂停' : '准备开始')))
            .id('focus_status').fontSize(14).fontColor(MUTED)
          Text(this.focusTime()).id('focus_clock').fontSize(64).fontWeight(FontWeight.Medium)
            .fontColor(CINNABAR).fontFamily('monospace')
          Text(this.focusTarget || '只做一件事').fontSize(15).fontColor(INK).maxLines(2).width('100%')
            .textAlign(TextAlign.Center)
          Row({ space: 8 }) {
            ForEach(this.focusDurations, (minutes: number) => {
              Button(`${minutes}分`, { type: ButtonType.Normal }).fontSize(12).layoutWeight(1).padding(0)
                .backgroundColor(this.focusDuration === minutes ? CINNABAR : '#EFE7DA')
                .fontColor(this.focusDuration === minutes ? Color.White : MUTED).borderRadius(8)
                .enabled(!this.focusRunning).onClick(() => this.resetFocus(minutes))
            }, (minutes: number) => `${minutes}`)
          }.width('100%')
          Row({ space: 10 }) {
            Button(this.focusRunning ? '暂停' : (this.focusRemaining === 0 ? '再来一段' :
              (this.focusRemaining < this.focusDuration * 60 ? '继续专注' : '开始专注')))
              .id('focus_start_pause').fontSize(15).layoutWeight(1).backgroundColor(CINNABAR)
              .fontColor(Color.White).height(44).onClick(() => this.switchFocus())
            Button('重置', { type: ButtonType.Normal }).id('focus_reset').fontSize(14)
              .fontColor(MUTED).backgroundColor('#EFE7DA').height(44).width(75).borderRadius(12).padding(0)
              .enabled(!this.focusRunning).onClick(() => this.resetFocus(this.focusDuration))
          }.width('100%')
        }.width('100%').padding(22).backgroundColor(PAPER_CARD).borderRadius(16)
          .border({ width: 1, color: LINE })
        this.FeedbackText()
        TextInput({ text: this.focusTarget, placeholder: '这一段准备做什么？（可选）' })
          .id('focus_target').maxLength(60).fontSize(14).backgroundColor(PAPER_CARD)
          .enabled(!this.focusRunning && this.focusRemaining === this.focusDuration * 60)
          .onChange((value: string) => this.focusTarget = value)
        this.CategoryPicker(true)
        Text('完整完成一个时段后自动记录日期、时长和分类；暂停、重置不会增加记录。切换时长会重置未完成时段。退出应用后未完成计时重置，无后台通知。')
          .fontSize(12).lineHeight(21).fontColor(MUTED).width('100%')
        Divider().color(LINE)
        Row() {
          Text('今日已完成专注').fontSize(14).fontColor(INK)
          Blank()
          Text(`${summarizeDay(this.workspace, localDateKey(new Date())).minutes} 分钟`)
            .id('focus_today_minutes').fontSize(20).fontColor(CINNABAR).fontWeight(FontWeight.Bold)
        }.width('100%')
        Text('记录按实际完成日期归档，不随黄历浏览日期改变。').fontSize(11).fontColor(MUTED).width('100%')
      }.width('100%').padding(18).alignItems(HorizontalAlign.Start)
    }.id('focus_scroll').width('100%').layoutWeight(1).scrollBar(BarState.Auto).backgroundColor(PAPER)
  }

  @Builder
  private SummaryMetric(value: string, label: string) {
    Column({ space: 5 }) {
      Text(value).fontSize(24).fontWeight(FontWeight.Bold).fontColor(CINNABAR)
      Text(label).fontSize(11).fontColor(MUTED)
    }.layoutWeight(1).padding(15).backgroundColor(PAPER_CARD).borderRadius(12)
  }

  @Builder
  private ReviewPage() {
    Scroll() {
      Column({ space: 14 }) {
        this.PageHeading('科研回顾', '记录做过什么，而不是只记得还有什么没做。')
        this.DateNavigation()
        Row({ space: 8 }) {
          this.SummaryMetric(`${summarizeDay(this.workspace, this.selectedDateKey).completed}/${summarizeDay(this.workspace, this.selectedDateKey).planned}`, '计划已完成')
          this.SummaryMetric(`${summarizeDay(this.workspace, this.selectedDateKey).minutes}`, '专注分钟')
        }.width('100%')
        Column({ space: 10 }) {
          Text('七日足迹').fontSize(16).fontWeight(FontWeight.Medium).fontColor(INK)
          Text('截至所选日期 · 计划完成 / 专注分钟').fontSize(11).fontColor(MUTED)
          ForEach(summarizeWeek(this.workspace, this.selectedDateKey), (day: DaySummary) => {
            Row() {
              Text(`${day.dateKey.substring(4, 6)}/${day.dateKey.substring(6, 8)}`)
                .fontSize(12).fontColor(MUTED).width(48)
              Text(`${day.completed}/${day.planned} 件`).fontSize(13).fontColor(INK).layoutWeight(1)
              Text(`${day.minutes} 分钟`).fontSize(13).fontColor(CINNABAR)
            }.width('100%')
          }, (day: DaySummary) => day.dateKey)
        }.alignItems(HorizontalAlign.Start).width('100%').padding(16)
          .backgroundColor(PAPER_CARD).borderRadius(12).border({ width: 1, color: LINE })
        Column({ space: 10 }) {
          Text('当日一记').fontSize(16).fontWeight(FontWeight.Medium).fontColor(INK)
          Text('切换日期前请保存；清空文字再保存可清除当天笔记。').fontSize(11).fontColor(MUTED).width('100%')
          TextArea({ text: this.reviewText, placeholder: '今天推进了什么？明天从哪里继续？' })
            .id('review_input').height(115).maxLength(400).fontSize(14).backgroundColor('#F2ECE2')
            .onChange((value: string) => this.reviewText = value)
          Row() {
            Text(`${this.reviewText.length}/400 · 仅本机保存`).fontSize(11).fontColor(MUTED)
            Blank()
            Button('保存回顾').id('review_save').fontSize(13).height(34)
              .backgroundColor(CINNABAR).fontColor(Color.White).onClick(() => this.saveCurrentReview())
          }.width('100%')
        }.alignItems(HorizontalAlign.Start).width('100%').padding(16).backgroundColor(PAPER_CARD)
          .borderRadius(12).border({ width: 1, color: LINE })
        this.FeedbackText()
        Text(`收藏日签 · ${this.workspace.favorites.length}/60`)
          .fontSize(16).fontWeight(FontWeight.Medium).fontColor(INK)
        if (this.workspace.favorites.length === 0) {
          Text('在「黄历」中收藏喜欢的日签，这里可以随时重读。')
            .fontSize(13).fontColor(MUTED).lineHeight(21).width('100%')
        } else {
          ForEach(this.workspace.favorites.slice().reverse(), (key: string) => {
            Column({ space: 7 }) {
              Row() {
                Text(readableDate(key)).fontSize(12).fontColor(CINNABAR).layoutWeight(1)
                Button('重读', { type: ButtonType.Normal }).fontSize(12).fontColor(CINNABAR)
                  .backgroundColor(Color.Transparent).height(26).padding(0)
                  .onClick(() => { this.changeDate(key); this.activeSection = 0; })
                Button('取消收藏', { type: ButtonType.Normal }).fontSize(11).fontColor(MUTED)
                  .backgroundColor(Color.Transparent).height(26)
                  .onClick(() => this.persistWorkspace(toggleFavorite(this.workspace, key)))
              }.width('100%')
              Text(this.favoriteQuote(key)).fontSize(14).fontColor(INK).lineHeight(22).width('100%')
            }.alignItems(HorizontalAlign.Start).width('100%').padding(14)
              .backgroundColor(PAPER_CARD).borderRadius(12).border({ width: 1, color: LINE })
          }, (key: string) => key)
        }
      }.width('100%').padding(18).alignItems(HorizontalAlign.Start)
    }.id('review_scroll').width('100%').layoutWeight(1).scrollBar(BarState.Auto).backgroundColor(PAPER)
  }

  @Builder
  private BottomNavigation() {
    Row() {
      ForEach(this.tabLabels, (label: string, index: number) => {
        Column({ space: 5 }) {
          Text(['日', '单', '时', '记'][index]).fontSize(17).fontWeight(FontWeight.Bold)
            .fontColor(this.activeSection === index ? CINNABAR : MUTED)
          Text(label).fontSize(11).fontColor(this.activeSection === index ? CINNABAR : MUTED)
        }.id(`tab_${index}`).layoutWeight(1).height(57).justifyContent(FlexAlign.Center)
          .backgroundColor(this.activeSection === index ? '#F2E7D8' : PAPER_CARD)
          .accessibilityText(label).onClick(() => {
            this.activeSection = index;
            this.pendingDelete = '';
            this.feedback = '';
            this.refreshForToday();
            this.tickFocus();
          })
      }, (label: string) => label)
    }.id('bottom_navigation').width('100%').backgroundColor(PAPER_CARD)
      .border({ width: { top: 1 }, color: LINE })
  }

  @Builder
  private CalendarOverlay() {
    Column() {
      Column({ space: 12 }) {
        Row() {
          Text('翻阅日期').fontSize(22).fontWeight(FontWeight.Bold).fontColor(INK).layoutWeight(1)
          Button('关闭', { type: ButtonType.Normal }).id('calendar_close').fontSize(13)
            .fontColor(MUTED).backgroundColor(Color.Transparent).onClick(() => this.showCalendar = false)
        }.width('100%')
        Row() {
          Button('‹', { type: ButtonType.Normal }).fontSize(24).fontColor(CINNABAR)
            .backgroundColor(Color.Transparent).onClick(() => this.changeMonth(-1))
          Text(`${this.calendarMonth.substring(0, 4)} 年 ${Number(this.calendarMonth.substring(4, 6))} 月`)
            .fontSize(17).fontColor(INK).layoutWeight(1).textAlign(TextAlign.Center)
          Button('›', { type: ButtonType.Normal }).fontSize(24).fontColor(CINNABAR)
            .backgroundColor(Color.Transparent).onClick(() => this.changeMonth(1))
        }.width('100%')
        Row() {
          ForEach(this.weekLabels, (label: string) => {
            Text(label).fontSize(12).fontColor(MUTED).layoutWeight(1).textAlign(TextAlign.Center)
          }, (label: string) => label)
        }.width('100%')
        Grid() {
          ForEach(calendarDays(this.calendarMonth), (day: CalendarDay) => {
            GridItem() {
              Text(day.day === 0 ? '' : `${day.day}`).fontSize(15)
                .fontColor(day.dateKey === this.selectedDateKey ? Color.White : INK)
                .width('100%').height(34).textAlign(TextAlign.Center)
                .backgroundColor(day.dateKey === this.selectedDateKey ? CINNABAR : Color.Transparent)
                .borderRadius(8).onClick(() => {
                  if (day.day > 0) { this.changeDate(day.dateKey); this.showCalendar = false; }
                })
            }
          }, (day: CalendarDay) => day.id)
        }.columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr').rowsGap(5).height(234).width('100%')
        TextInput({ text: this.dateInput, placeholder: 'YYYY-MM-DD' }).id('calendar_date_input')
          .fontSize(14).maxLength(10).backgroundColor('#EFE7DA')
          .onChange((value: string) => this.dateInput = value)
        if (this.calendarError) { Text(this.calendarError).fontSize(12).fontColor(CINNABAR) }
        Row({ space: 8 }) {
          Button('回到今天').fontSize(13).layoutWeight(1).backgroundColor('#EFE7DA').fontColor(CINNABAR)
            .onClick(() => { this.changeDate(localDateKey(new Date())); this.showCalendar = false; })
          Button('跳转日期').id('calendar_jump').fontSize(13).layoutWeight(1)
            .backgroundColor(CINNABAR).fontColor(Color.White).onClick(() => {
              const key: string = parseDateInput(this.dateInput);
              if (key) { this.changeDate(key); this.showCalendar = false; }
              else this.calendarError = '请输入真实日期，例如 2026-09-17。';
            })
        }.width('100%')
        Text('黄历仅供娱乐，不预测未来或提供真实择日建议。').fontSize(10).fontColor(MUTED)
      }.width('92%').padding(18).backgroundColor(PAPER_CARD).borderRadius(18)
    }.id('calendar_overlay').width('100%').height('100%').justifyContent(FlexAlign.Center)
      .backgroundColor('#99000000')
  }

  @Builder
  private AboutPage() {
    Scroll() {
    Column({ space: 18 }) {
      Row() {
        Button('返回', { type: ButtonType.Normal })
          .id('back_button')
          .fontSize(13)
          .fontColor(CINNABAR)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .onClick(() => this.showAbout = false)
        Blank()
      }
      .width('100%')

      Text('关于学术黄历')
        .fontSize(25)
        .fontWeight(FontWeight.Bold)
        .fontColor(INK)
        .width('100%')
      Text('科研人的每日宜忌与轻量工作台。')
        .fontSize(16)
        .fontColor(CINNABAR)
        .width('100%')

      Text('每日黄历、日期翻阅与日签收藏，让科研生活多一点会心一笑。按日期安排科研计划，用专注计时推进一件小事，再通过七日足迹和当日一记回顾进展。所有功能都在本机离线完成。')
        .fontSize(14)
        .lineHeight(24)
        .fontColor(INK)
      Column({ space: 8 }) {
        Text('当前学科门类').fontSize(13).fontColor(MUTED).width('100%')
        Row() {
          Text(this.selectedDiscipline).fontSize(18).fontWeight(FontWeight.Bold).fontColor(INK)
            .layoutWeight(1)
          Button('修改', { type: ButtonType.Normal }).id('discipline_change')
            .fontSize(13).fontColor(CINNABAR).backgroundColor('#EFE7DA').borderRadius(10)
            .onClick(() => this.openDisciplinePicker())
        }.width('100%')
        Text('每日内容由通用科研语料与本学科专属语料共同生成。')
          .fontSize(12).fontColor(MUTED).width('100%')
      }
      .width('100%')
      .padding(14)
      .backgroundColor(PAPER_CARD)
      .border({ width: 1, color: LINE })
      .borderRadius(12)
      Divider().color(LINE)
      Text('隐私说明')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(INK)
        .width('100%')
      Text('核心功能完全离线运行；不要求注册账号；不主动收集、上传或出售个人信息；不获取位置、通讯录、照片或科研文件；不集成广告和第三方统计 SDK。')
        .fontSize(14)
        .lineHeight(24)
        .fontColor(INK)
      Text('学科选择、计划、回顾、收藏和已完成专注记录仅保存在应用私有存储中，请勿填写不必要的敏感信息。卸载应用会清除本机数据。')
        .fontSize(13).lineHeight(22).fontColor(MUTED)
      Button('查看完整隐私政策', { type: ButtonType.Normal }).id('about_privacy')
        .fontSize(14).fontColor(CINNABAR).backgroundColor('#EFE7DA').width('100%')
        .onClick(() => this.showPrivacyDetails = true)
      Button('清除本机记录', { type: ButtonType.Normal }).id('clear_local_records')
        .fontSize(13).fontColor(MUTED).backgroundColor('#EFE7DA').width('100%')
        .onClick(() => {
          AlertDialog.show({ title: '清除全部本机记录？',
            message: '学科选择、计划、收藏、已完成专注与回顾将永久删除，无法恢复。隐私同意状态保留。',
            primaryButton: { value: '取消', action: () => {} },
            secondaryButton: { value: '确认清除', action: () => {
              this.focusRunning = false;
              this.stopInterval();
              this.resetFocus(this.focusDuration);
              this.focusTarget = '';
              this.taskInput = '';
              this.persistWorkspace(emptyWorkspace());
              this.selectedDiscipline = '';
              this.disciplineDraft = '';
              this.reviewText = '';
              this.feedback = '本机记录已清除，请重新选择学科门类。';
              this.showAbout = false;
            } }
          });
        })
      Divider().color(LINE)
      Text('所有内容均为原创科研趣味文案，仅供娱乐，不构成任何学术、职业或其他决策建议。')
        .fontSize(13)
        .lineHeight(22)
        .fontColor(MUTED)
      Text('版本 1.2.0')
        .fontSize(12)
        .fontColor('#9A9187')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 22, right: 22, top: 18, bottom: 20 })
    .backgroundColor(PAPER)
    }.width('100%').height('100%').scrollBar(BarState.Auto).backgroundColor(PAPER)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.privacyAccepted && this.selectedDiscipline) {
        if (this.showAbout) {
          this.AboutPage()
        } else {
          Column() {
            if (this.activeSection === 0) { this.MainPage() }
            else if (this.activeSection === 1) { this.PlanPage() }
            else if (this.activeSection === 2) { this.FocusPage() }
            else { this.ReviewPage() }
            this.BottomNavigation()
          }.width('100%').height('100%').backgroundColor(PAPER)
        }
        if (this.showCalendar) { this.CalendarOverlay() }
        if (this.showPrivacyDetails) { this.PrivacyPolicyCard() }
      }
      if (this.privacyAccepted && (!this.selectedDiscipline || this.showDisciplinePicker)) {
        this.DisciplineOverlay()
      }
      if (!this.privacyAccepted) {
        this.PrivacyOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAPER)
  }
}
