package com.beibeihk.academicalmanac;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private WebView webView;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(false);
        settings.setDatabaseEnabled(false);
        settings.setGeolocationEnabled(false);
        settings.setMediaPlaybackRequiresUserGesture(true);
        webView.setWebViewClient(new WebViewClient());
        webView.loadUrl("file:///android_asset/index.html");
        setContentView(webView);
    }

    @Override
    public void onBackPressed() {
        webView.evaluateJavascript("window.handleAndroidBack ? window.handleAndroidBack() : 'exit'", value -> {
            if ("\"exit\"".equals(value)) MainActivity.super.onBackPressed();
        });
    }

    @Override
    protected void onDestroy() {
        webView.destroy();
        super.onDestroy();
    }
}
