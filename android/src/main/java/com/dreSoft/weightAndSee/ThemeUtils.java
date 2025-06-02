package com.dreSoft.weightAndSee;

import android.app.Activity;
import android.os.Build;
import android.view.Window;
import android.view.View;
import android.view.WindowInsetsController; // Importación añadida
import java.lang.reflect.Method;
import java.lang.reflect.Field;

public class ThemeUtils {
    public static void setDarkSystemBars(Activity activity) {
        if (activity == null) return;

        Window window = activity.getWindow();

        // Configuración básica para todas las versiones
        window.setStatusBarColor(0x00000000); // Transparente
        window.setNavigationBarColor(0x00000000); // Transparente

        // Configuración para Android 11+ (API 30+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowInsetsController insetsController = window.getInsetsController();
            if (insetsController != null) {
                insetsController.setSystemBarsAppearance(
                    0, // Iconos claros
                    WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS |
                    WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
                );
            }
        }
        // Configuración para versiones anteriores (API 23+)
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            View decorView = window.getDecorView();
            int flags = decorView.getSystemUiVisibility();
            flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
            flags &= ~View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
            decorView.setSystemUiVisibility(flags);
        }

        // Aplicar fixes para marcas específicas
        fixCustomBrands(activity);
    }

    private static void fixCustomBrands(Activity activity) {
        if (activity == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return;

        String manufacturer = Build.MANUFACTURER.toLowerCase();
        Window window = activity.getWindow();

        if (manufacturer.contains("xiaomi")) {
            applyMiuiFix(window);
        } else if (manufacturer.contains("huawei") || manufacturer.contains("honor")) {
            applyEmuiFix(window);
        }
    }

    private static void applyMiuiFix(Window window) {
        try {
            Class<?> clazz = window.getClass();
            Class<?> layoutParams = Class.forName("android.view.MiuiWindowManager$LayoutParams");
            Field field = layoutParams.getField("EXTRA_FLAG_STATUS_BAR_DARK_MODE");
            int darkModeFlag = field.getInt(layoutParams);
            Method extraFlagField = clazz.getMethod("setExtraFlags", int.class, int.class);
            extraFlagField.invoke(window, 0, darkModeFlag);
        } catch (Exception e) {
            // Silenciar fallos
        }
    }

    private static void applyEmuiFix(Window window) {
        try {
            View decorView = window.getDecorView();
            int flags = decorView.getSystemUiVisibility();
            flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
            decorView.setSystemUiVisibility(flags);
        } catch (Exception e) {
            // Silenciar fallos
        }
    }
}
