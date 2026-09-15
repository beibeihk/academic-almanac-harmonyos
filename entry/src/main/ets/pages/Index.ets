import {
  AlmanacItem,
  DailyAlmanac,
  formatChineseDate,
  formatWeekday,
  generateAlmanac
} from '../model/AlmanacEngine';
import { ALMANAC_DATABASE } from '../model/AlmanacData';

const PAPER: ResourceColor = '#F7F2E8';
const PAPER_CARD: ResourceColor = '#FFFCF5';
const INK: ResourceColor = '#26221D';
const MUTED: ResourceColor = '#766E64';
const CINNABAR: ResourceColor = '#A63228';
const LINE: ResourceColor = '#DDD2C1';
const PRIVACY_CONSENT_KEY: string = 'privacyConsentV1';

PersistentStorage.persistProp(PRIVACY_CONSENT_KEY, false);

@Entry
@Component
struct Index {
  @StorageLink('privacyConsentV1') private privacyAccepted: boolean = false;
  @State private almanac: DailyAlmanac | null = null;
  @State private dateText: string = '';
  @State private weekdayText: string = '';
  @State private visibleDateKey: string = '';
  @State private showAbout: boolean = false;
  @State private showPrivacyDetails: boolean = false;
  @State private privacyRejected: boolean = false;

  aboutToAppear(): void {
    this.refreshForToday();
  }

  onPageShow(): void {
    this.refreshForToday();
  }

  private refreshForToday(): void {
    const now: Date = new Date();
    const key: string = `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;
    if (key === this.visibleDateKey && this.almanac !== null) {
      return;
    }
    try {
      this.almanac = generateAlmanac(ALMANAC_DATABASE, now);
      this.dateText = formatChineseDate(now);
      this.weekdayText = formatWeekday(now);
      this.visibleDateKey = key;
    } catch (error) {
      console.error(`Failed to generate almanac: ${JSON.stringify(error)}`);
    }
  }

  private acceptPrivacy(): void {
    this.privacyAccepted = true;
    this.showPrivacyDetails = false;
    this.privacyRejected = false;
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
        Text('本应用无需注册登录，核心功能完全离线运行；不收集、存储、上传或共享任何个人信息；不申请位置、通讯录、照片等敏感权限；不含广告与第三方统计 SDK。')
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
      Text('生效及更新日期：2026年9月16日')
        .fontSize(11)
        .fontColor(MUTED)
        .width('100%')

      Scroll() {
        Column({ space: 12 }) {
          Text('1. 信息处理').fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
          Text('本应用不要求注册或登录，不收集、存储、上传、出售或共享任何个人信息。每日黄历内容仅依据设备本地日期和应用内置原创文案在本地生成。')
            .fontSize(13).lineHeight(21).fontColor(INK)
          Text('2. 设备权限与联网').fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
          Text('本应用不申请位置、通讯录、相机、麦克风、照片、存储或设备标识符等权限，核心功能无需联网，不含广告及第三方统计 SDK。')
            .fontSize(13).lineHeight(21).fontColor(INK)
          Text('3. 数据共享与保存').fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
          Text('由于本应用不收集个人信息，因此不存在向第三方提供个人信息或将个人信息传输至境外的情形。您的同意状态仅保存在本机，用于避免重复提示。')
            .fontSize(13).lineHeight(21).fontColor(INK)
          Text('4. 您的权利').fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK).width('100%')
          Text('您可以选择不同意本政策并停止使用应用，也可以通过卸载应用清除本机保存的同意状态。')
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

      Button('返回并继续选择')
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
  private AlmanacRow(item: AlmanacItem) {
    Column({ space: 2 }) {
      Text(item.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(INK)
        .maxLines(1)
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

        Divider().color(CINNABAR).strokeWidth(1)

        if (this.almanac !== null) {
          Row({ space: 14 }) {
            Column({ space: 3 }) {
              Text('今日学术签')
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
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.None)
    .backgroundColor(PAPER)
  }

  @Builder
  private AboutPage() {
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
      Text('科研人的每日宜忌。')
        .fontSize(16)
        .fontColor(CINNABAR)
        .width('100%')

      Text('学术黄历是一款面向科研人员和高校学生的轻量趣味应用。每日内容仅由设备本地日期与内置原创文案生成，同一天保持一致，次日自动更新。')
        .fontSize(14)
        .lineHeight(24)
        .fontColor(INK)
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
      Divider().color(LINE)
      Text('所有内容均为原创科研趣味文案，仅供娱乐，不构成任何学术、职业或其他决策建议。')
        .fontSize(13)
        .lineHeight(22)
        .fontColor(MUTED)
      Blank()
      Text('版本 1.0.2')
        .fontSize(12)
        .fontColor('#9A9187')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding({ left: 22, right: 22, top: 18, bottom: 20 })
    .backgroundColor(PAPER)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.showAbout) {
        this.AboutPage()
      } else {
        this.MainPage()
      }
      if (!this.privacyAccepted) {
        this.PrivacyOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
}
