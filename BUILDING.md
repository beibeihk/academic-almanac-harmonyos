# 构建

要求：Windows 10/11、Node.js 22+、DevEco Studio 6.0.2 或 Command Line Tools 6.0.2（含 HarmonyOS SDK 6.0.2），以及 `@deveco/deveco-cli`。

```powershell
npm install -g @deveco/deveco-cli@stable
npm test
devecocli build --build-mode debug
devecocli build --build-mode release
```

真机安装需使用开发者账号生成的调试签名；提交 AppGallery Connect 需使用官方发布签名。签名材料只应保存在本机，已由 `.gitignore` 排除。

