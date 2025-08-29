package com.example.youtubesplitter;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.work.Data;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import com.arthenica.ffmpegkit.FFmpegKit;
import com.arthenica.ffmpegkit.ReturnCode;
import com.arthenica.ffmpegkit.Session;
import com.chaquo.python.PyObject;
import com.chaquo.python.Python;
import com.chaquo.python.android.AndroidPlatform;
import com.google.api.client.extensions.android.http.AndroidHttp;
import com.google.api.client.googleapis.extensions.android.gms.auth.GoogleAccountCredential;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.client.util.ExponentialBackOff;
import com.google.api.services.youtube.YouTube;
import com.google.api.services.youtube.YouTubeScopes;
import com.google.api.services.youtube.model.Video;
import com.google.api.services.youtube.model.VideoSnippet;
import com.google.api.services.youtube.model.VideoStatus;
import com.google.api.client.http.InputStreamContent;


import java.io.File;
import java.io.FileInputStream;
import java.util.Collections;

public class VideoProcessingWorker extends Worker {

    private static final String TAG = "VideoProcessingWorker";

    public VideoProcessingWorker(@NonNull Context context, @NonNull WorkerParameters workerParams) {
        super(context, workerParams);
    }

    @NonNull
    @Override
    public Result doWork() {
        String url = getInputData().getString("VIDEO_URL");
        String userEmail = getInputData().getString("USER_ACCOUNT_EMAIL");

        if (url == null || url.isEmpty() || userEmail == null || userEmail.isEmpty()) {
            return Result.failure(new Data.Builder().putString("error", "URL o email de usuario vacío.").build());
        }

        try {
            // --- Paso 1: Descargar ---
            if (!Python.isStarted()) {
                Python.start(new AndroidPlatform(getApplicationContext()));
            }
            Python py = Python.getInstance();
            File downloadsDir = new File(getApplicationContext().getFilesDir(), "downloads");
            if (!downloadsDir.exists()) downloadsDir.mkdirs();
            String videoPathFormat = new File(downloadsDir, "%(title)s.%(ext)s").getAbsolutePath();

            PyObject ytdlpModule = py.getModule("yt_dlp");
            int ytdlpResult = ytdlpModule.callAttr("main", url, "-o", videoPathFormat, "-f", "best[ext=mp4]", "--no-playlist").toInt();

            if (ytdlpResult != 0) return Result.failure(createErrorData("Fallo en la descarga."));

            File[] downloadedFiles = downloadsDir.listFiles();
            if (downloadedFiles == null || downloadedFiles.length == 0) return Result.failure(createErrorData("Archivo descargado no encontrado."));
            File downloadedVideo = downloadedFiles[0];
            String originalTitle = downloadedVideo.getName().replaceFirst("[.][^.]+$", "");


            // --- Paso 2: Dividir ---
            File clipsDir = new File(getApplicationContext().getFilesDir(), "clips");
            if (!clipsDir.exists()) clipsDir.mkdirs();
            for (File file : clipsDir.listFiles()) file.delete(); // Limpiar clips antiguos

            String clipPathPattern = new File(clipsDir, "clip_%03d.mp4").getAbsolutePath();
            String ffmpegCommand = String.format("-i \"%s\" -c copy -map 0 -segment_time 30 -f segment -reset_timestamps 1 \"%s\"",
                    downloadedVideo.getAbsolutePath(), clipPathPattern);

            Session session = FFmpegKit.execute(ffmpegCommand);
            if (!ReturnCode.isSuccess(session.getReturnCode())) return Result.failure(createErrorData("Fallo en la división del vídeo."));
            downloadedVideo.delete(); // Limpiar vídeo original


            // --- Paso 3: Subir ---
            GoogleAccountCredential credential = GoogleAccountCredential.usingOAuth2(
                    getApplicationContext(), Collections.singleton(YouTubeScopes.YOUTUBE_UPLOAD))
                    .setSelectedAccountName(userEmail)
                    .setBackOff(new ExponentialBackOff());

            YouTube youtubeService = new YouTube.Builder(
                    AndroidHttp.newCompatibleTransport(),
                    new GsonFactory(),
                    credential)
                    .setApplicationName(getApplicationContext().getString(R.string.app_name))
                    .build();

            File[] clips = clipsDir.listFiles();
            if (clips == null || clips.length == 0) return Result.failure(createErrorData("No se encontraron clips para subir."));

            for (int i = 0; i < clips.length; i++) {
                File clip = clips[i];
                Video videoObject = new Video();

                VideoStatus status = new VideoStatus();
                status.setPrivacyStatus("private"); // 'private', 'public', o 'unlisted'
                videoObject.setStatus(status);

                VideoSnippet snippet = new VideoSnippet();
                snippet.setTitle(String.format("Clip %d de '%s'", i + 1, originalTitle));
                snippet.setDescription(String.format("Clip autogenerado del vídeo '%s'.", originalTitle));
                videoObject.setSnippet(snippet);

                InputStreamContent mediaContent = new InputStreamContent("video/*", new FileInputStream(clip));
                YouTube.Videos.Insert videoInsert = youtubeService.videos().insert("snippet,status", videoObject, mediaContent);
                videoInsert.getMediaHttpUploader().setProgressListener(uploader -> {
                    // Aquí se podría actualizar el progreso
                });

                Video returnedVideo = videoInsert.execute();
                Log.d(TAG, "Vídeo subido: " + returnedVideo.getId());
                clip.delete(); // Limpiar clip subido
            }

            return Result.success();

        } catch (Exception e) {
            Log.e(TAG, "Error en VideoProcessingWorker", e);
            return Result.failure(createErrorData(e.getMessage()));
        }
    }

    private Data createErrorData(String error) {
        return new Data.Builder().putString("error", error).build();
    }
}
