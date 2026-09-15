# Release Status

- 应用名称：学术黄历 Academic Almanac
- 当前正式版本：1.0.1（1000001）
- 测试状态：AppGallery Connect 邀请测试审核通过并已开放；测试期为 2026-09-14 至 2026-12-12
- 测试下载/邀请入口：https://appgallery.huawei.com/link/invite-test-wap?taskId=2545e317edef88f8eda66c8d3fb43794
- 邀请码：`9eQy8SAGrDY`
- 1.0.0 审核结果：未通过。审核附件中的真机视频显示首屏持续停留在“正在翻阅今日学术运势…”，主要功能无法使用
- 1.0.1 修复：将黄历 JSON 在构建阶段编译为 ArkTS 数据模块，移除真机运行时对 `rawfile`、`Context` 和文本解码器的依赖；同时加入数据库哈希一致性及禁止恢复运行时资源读取的回归测试
- 验证结果：自动测试 6/6 通过；Release APP/HAP 构建成功；华为签名工具摘要校验通过；官方 ArkUI 运行时中首屏可立即显示完整内容
- 新包状态：`AcademicAlmanac-1.0.1-release-signed.app` 已上传并启动华为上架自检
- 正式上架状态：已于 2026-09-16 使用 1.0.1 重新提交，当前为“预审中”
- 发布区域：中国大陆
- 上架方式：审核通过后立即上架
- 应用截图：已重新提交 3 张真实运行截图，其中首屏和“关于”页已更新为 1.0.1 官方 ArkUI 运行时画面，保存在 `release-assets/screenshots/`
- 手机端安装：在 HarmonyOS NEXT 手机的系统浏览器打开上方邀请链接，点击“开始测试”并在华为应用市场安装
