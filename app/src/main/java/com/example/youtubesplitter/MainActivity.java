package com.example.youtubesplitter;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.Observer;
import androidx.work.Data;
import androidx.work.OneTimeWorkRequest;
import androidx.work.WorkInfo;
import androidx.work.WorkManager;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import com.example.youtubesplitter.databinding.ActivityMainBinding;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.tasks.Task;

public class MainActivity extends AppCompatActivity {

    private static final String TAG = "MainActivity";
    private ActivityMainBinding binding;
    private YouTubeUploader youTubeUploader;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        youTubeUploader = new YouTubeUploader(this);

        setupClickListeners();
        checkSignInStatus();
    }

    private void setupClickListeners() {
        binding.loginButton.setOnClickListener(v -> youTubeUploader.signIn());
        binding.processButton.setOnClickListener(v -> handleProcessUrl());
    }

    private void checkSignInStatus() {
        GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(this);
        updateUI(account);
    }

    private void updateUI(@Nullable GoogleSignInAccount account) {
        if (account != null) {
            binding.loginStatusTextView.setText("Autenticado como: " + account.getEmail());
            binding.loginButton.setText("Cerrar Sesión");
            binding.loginButton.setOnClickListener(v -> signOut());
            binding.processButton.setEnabled(true);
        } else {
            binding.loginStatusTextView.setText("Estado: No autenticado");
            binding.loginButton.setText("Iniciar Sesión con YouTube");
            binding.loginButton.setOnClickListener(v -> youTubeUploader.signIn());
            binding.processButton.setEnabled(false); // Deshabilitar si no está logueado
        }
    }

    private void signOut() {
        youTubeUploader.signOut();
        updateUI(null);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == YouTubeUploader.REQUEST_CODE_SIGN_IN) {
            Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
            handleSignInResult(task);
        }
    }

    private void handleSignInResult(Task<GoogleSignInAccount> completedTask) {
        try {
            GoogleSignInAccount account = completedTask.getResult(ApiException.class);
            Toast.makeText(this, "Inicio de sesión exitoso", Toast.LENGTH_SHORT).show();
            updateUI(account);
        } catch (ApiException e) {
            Log.w(TAG, "signInResult:failed code=" + e.getStatusCode());
            Toast.makeText(this, "Fallo en el inicio de sesión", Toast.LENGTH_SHORT).show();
            updateUI(null);
        }
    }

    private void handleProcessUrl() {
        // ... (el código existente para WorkManager se mantiene igual)
        String url = binding.urlEditText.getText().toString().trim();
        if (url.isEmpty()) {
            binding.statusTextView.setText("Por favor, introduce una URL de YouTube.");
            return;
        }

        binding.processButton.setEnabled(false);
        binding.statusTextView.setText("Enviando a la cola de procesamiento...");

        GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(this);
        if (account == null) {
            Toast.makeText(this, "Error: No hay una sesión iniciada. Por favor, inicia sesión primero.", Toast.LENGTH_LONG).show();
            binding.processButton.setEnabled(true);
            return;
        }

        Data inputData = new Data.Builder()
                .putString("VIDEO_URL", url)
                .putString("USER_ACCOUNT_EMAIL", account.getEmail())
                .build();
        OneTimeWorkRequest workRequest = new OneTimeWorkRequest.Builder(VideoProcessingWorker.class)
                .setInputData(inputData)
                .build();

        WorkManager.getInstance(this).enqueue(workRequest);

        WorkManager.getInstance(this).getWorkInfoByIdLiveData(workRequest.getId())
                .observe(this, workInfo -> {
                    if (workInfo != null) {
                        if (workInfo.getState().isFinished()) {
                            binding.statusTextView.append("\nProceso finalizado.");
                            binding.processButton.setEnabled(true);
                            if (workInfo.getState() == WorkInfo.State.SUCCEEDED) {
                                binding.statusTextView.append("\nResultado: ¡Éxito!");
                            } else {
                                binding.statusTextView.append("\nResultado: ¡Fallo!");
                                String error = workInfo.getOutputData().getString("error");
                                if (error != null) {
                                    binding.statusTextView.append("\nError: " + error);
                                }
                            }
                        } else {
                            binding.statusTextView.setText("Estado actual: " + workInfo.getState().name());
                        }
                    }
                });
    }
}
