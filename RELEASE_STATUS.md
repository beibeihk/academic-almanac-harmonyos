# Release Status

更新：2026-09-21（北京时间）。以 AppGallery Connect 实时状态为准。

- 原生应用：`com.beibeihk.academicalmanac`。1.1.0（1001001）于 2026-09-18 19:38:30 上架；应用市场详情页：<https://appgallery.huawei.com/app/detail?id=com.beibeihk.academicalmanac>。
- 原生 1.2.0（1002000）：签名 APP `release-assets/packages/AcademicAlmanac-1.2.0-HarmonyOS5-signed.app` 已上传华为，已选作升级发布包；上架自检已启动，升级版本信息处于“准备提交”。适用 HarmonyOS 5 及以上，不覆盖 HarmonyOS 4。
- Android 兼容应用：独立 APP ID `119074903`，包名 `com.beibeihk.academicalmanac.android`。签名 APK `release-assets/packages/AcademicAlmanac-1.2.0-HarmonyOS4-compatible-signed.apk` 已上传华为，已选作发布包；应用信息和版本信息已保存，当前为“准备提交”。该应用拟供仍支持 Android 应用的 HarmonyOS 4.x 设备下载，不能仅凭 Android 模拟器推定所有鸿蒙 4 真机兼容或保证应用市场审核通过。
- 1.2.0 内容：首次同意隐私政策后必须从现行 14 个学科门类中选一类；560 条学科专属、194 条通用语料离线生成每日宜忌、吉时与学术签，可在“关于”切换学科；黄历、计划、专注、回顾四页保留。
- 验证：18/18 自动测试通过；原生 Release APP/HAP 已构建并通过官方签名校验；官方 ArkUI 预览验证首启、学科选择、经济学黄历和计划。Android APK 通过 v2 签名验证，并在 Android 11 模拟设备实际安装，走通隐私提示、学科选择、经济学日签、计划、专注和回顾；五张 1080×1920 应用内截图保存在 `release-assets/screenshots/academic-almanac-120-android-*.png`。尚未取得 HarmonyOS 4 真机验证，华为付费云设备未启用。
- 两版是不同安装包及包名，本机记录不能自动迁移；均无账号、网络权限、广告或第三方 SDK。开发者邮箱和完整隐私政策见 `PRIVACY.md`。
- 历史：1.0.0 曾因启动停留在加载页被拒；1.0.1 将语料编译进 ArkTS 静态模块；1.0.2 加入首启隐私提示；1.1.0 因此前功能过于简单而扩展成四页并最终上架。
