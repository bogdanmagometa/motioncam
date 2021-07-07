package com.motioncam.model;

import android.content.Context;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class CameraProfile {
    private static final String CAPTURE_OUTPUT_PATH_NAME = "motionCam";
    private static final SimpleDateFormat OUTPUT_DATE_FORMAT = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.forLanguageTag("en-US"));

    static private String generateFilename() {
        return String.format(
                Locale.getDefault(),
                "IMG_%s.zip",
                OUTPUT_DATE_FORMAT.format(new Date()));
    }

    static public File getRootOutputPath(Context context) {
        File root = new File(
                context.getFilesDir().getPath() +
                        java.io.File.separator +
                        CameraProfile.CAPTURE_OUTPUT_PATH_NAME);

        if(!root.exists() && !root.mkdirs()) {
            throw new IllegalStateException("Can't create output directory");
        }

        return root;
    }

    static public File generateCaptureFile(Context context) {
        return  new File(getRootOutputPath(context), CameraProfile.generateFilename());
    }

    public static final int DEFAULT_JPEG_QUALITY = 95;

    // Light
    public static final int DEFAULT_CONTRAST = 50;
    public static final int DEFAULT_WHITE_POINT = 50;

    // Saturation
    public static final int DEFAULT_SATURATION = 60;
    public static final int DEFAULT_GREENS = 50;
    public static final int DEFAULT_BLUES = 50;

    // Detail
    public static final int DEFAULT_SHARPNESS = 40;
    public static final int DEFAULT_DETAIL = 25;
}
