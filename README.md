# 学术黄历 Academic Almanac

> 科研人的每日宜忌。

一款使用 ArkTS / ArkUI 开发的 HarmonyOS 原生轻量应用。它每天仅根据设备本地日期，从内置原创文案库中确定性生成两条“宜”、两条“忌”、吉时与学术签；同一天内容不变，第二天自动更新。

- 完全离线，无账号、广告、统计 SDK 或第三方 SDK
- 不申请网络、位置、相册、联系人等权限
- FNV-1a + xorshift32 确定性日更
- HarmonyOS 5.0.0(12)+，目标 SDK 6.0.2(22)

```powershell
npm test
& "$env:DEVECO_HOME\bin\hvigorw.bat" clean assembleApp --mode project -p product=default -p buildMode=debug --no-daemon
& "$env:DEVECO_HOME\bin\hvigorw.bat" clean assembleApp --mode project -p product=default -p buildMode=release --no-daemon
```

构建环境见 [BUILDING.md](BUILDING.md)，隐私说明见 [PRIVACY.md](PRIVACY.md)。

代码采用 MIT License；应用内原创文案与品牌素材不随代码许可开放，详见 [CONTENT_LICENSE.md](CONTENT_LICENSE.md)。
