# 构建

要求：Windows 10/11、JDK 17、Node.js 22+，以及 DevEco Studio 6.0.2 或 Command Line Tools 6.0.2（含 HarmonyOS SDK 6.0.2）。将 `DEVECO_HOME` 指向 Command Line Tools 根目录；使用 DevEco Studio 时也可直接执行同名 Hvigor 任务。

```powershell
npm test
& "$env:DEVECO_HOME\bin\hvigorw.bat" clean assembleApp --mode project -p product=default -p buildMode=debug --no-daemon
& "$env:DEVECO_HOME\bin\hvigorw.bat" clean assembleApp --mode project -p product=default -p buildMode=release --no-daemon
```

构建产物位于 `entry/build/default/outputs/default/`（HAP）和 `build/outputs/default/`（APP）。未配置签名时文件名带 `unsigned`，不能直接安装或上传。真机安装需使用开发者账号生成的调试签名；提交 AppGallery Connect 需使用官方发布签名。签名材料只应保存在本机，已由 `.gitignore` 排除。
