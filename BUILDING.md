# 构建

要求：Windows 10/11、JDK 17、Node.js 22+，以及 DevEco Studio 6.0.2 或 Command Line Tools 6.0.2（含 HarmonyOS SDK 6.0.2）。将 `DEVECO_HOME` 指向 Command Line Tools 根目录；使用 DevEco Studio 时也可直接执行同名 Hvigor 任务。

```powershell
npm run generate:data
npm test
& "$env:DEVECO_HOME\bin\hvigorw.bat" clean assembleApp --mode project -p product=default -p buildMode=debug --no-daemon
& "$env:DEVECO_HOME\bin\hvigorw.bat" clean assembleApp --mode project -p product=default -p buildMode=release --no-daemon
```

`generate:data` 会生成 14 学科门类的专属语料，并把通用及专属语料编译进 ArkTS 静态数据模块和 Android 离线资源，避免首屏在真机上依赖运行时资源读取。生成文件纳入版本控制，构建前仍应重新执行命令并通过测试中的哈希一致性检查；测试还会逐日对照两版的日签结果。

构建产物位于 `entry/build/default/outputs/default/`（HAP）和 `build/outputs/default/`（APP）。未配置签名时文件名带 `unsigned`，不能直接安装或上传。真机安装需使用开发者账号生成的调试签名；提交 AppGallery Connect 需使用官方发布签名。签名材料只应保存在本机，已由 `.gitignore` 排除。

Android 兼容版另需 JDK 17、Android SDK 35、Android Gradle Plugin 8.7.3 和 Gradle 8.9。进入 `android/` 后运行 `gradle :app:assembleRelease`。发布签名通过环境变量 `ACADEMIC_KEYSTORE_PATH`、`ACADEMIC_KEYSTORE_PASSWORD`、`ACADEMIC_KEY_ALIAS`、`ACADEMIC_KEY_PASSWORD` 注入；未签名的 Release APK 不可提交。Android 版独立包名为 `com.beibeihk.academicalmanac.android`，不会与原生 `.app` 的包名冲突，两版数据不互通。
