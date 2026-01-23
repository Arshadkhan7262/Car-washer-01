package com.example.wash_away

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.auth.api.signin.GoogleSignIn

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Configure Google Sign-In with serverClientId for server-side token verification
        // This is required for google_sign_in package version 7.x on Android
        val serverClientId = "10266283459-7g052icp6h684cru34f2ab3h6qdamnp9.apps.googleusercontent.com"
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(serverClientId)
            .requestEmail()
            .build()
        
        // This ensures the google_sign_in plugin uses this configuration
        GoogleSignIn.getClient(this, gso)
    }
}
