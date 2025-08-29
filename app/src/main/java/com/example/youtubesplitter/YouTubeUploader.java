package com.example.youtubesplitter;

import android.app.Activity;
import android.content.Intent;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.Scope;
import com.google.api.services.youtube.YouTubeScopes;

public class YouTubeUploader {

    public static final int REQUEST_CODE_SIGN_IN = 1;

    private GoogleSignInClient mGoogleSignInClient;
    private Activity mActivity;

    public YouTubeUploader(Activity activity) {
        this.mActivity = activity;

        // Configurar el inicio de sesión para solicitar el permiso de subida a YouTube
        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestEmail()
                .requestScopes(new Scope(YouTubeScopes.YOUTUBE_UPLOAD))
                .build();

        mGoogleSignInClient = GoogleSignIn.getClient(activity, gso);
    }

    public void signIn() {
        Intent signInIntent = mGoogleSignInClient.getSignInIntent();
        mActivity.startActivityForResult(signInIntent, REQUEST_CODE_SIGN_IN);
    }

    public void signOut() {
        mGoogleSignInClient.signOut();
    }

    // Aquí añadiremos la lógica de subida más adelante.
}
