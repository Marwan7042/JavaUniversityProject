package com.university.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.concurrent.*;
import java.util.function.Consumer;

public class NotificationService {
    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);
    private static NotificationService instance;
    private final ScheduledExecutorService executor = Executors.newScheduledThreadPool(3);
    private Consumer<String> uiCallback;

    private NotificationService() {}

    public static synchronized NotificationService getInstance() {
        if (instance == null) instance = new NotificationService();
        return instance;
    }

    public void setUiCallback(Consumer<String> callback) { this.uiCallback = callback; }

    public void sendAsync(String message) {
        executor.schedule(() -> {
            if (uiCallback != null) javafx.application.Platform.runLater(() -> uiCallback.accept(message));
            log.info("[NOTIFICATION] {}", message);
        }, 100, TimeUnit.MILLISECONDS);
    }

    public void sendEnrollmentConfirmation(String studentName, String courseName) {
        sendAsync("Enrollment confirmed: " + studentName + " → " + courseName);
    }

    public void sendDropConfirmation(String studentName, String courseName) {
        sendAsync("Drop confirmed: " + studentName + " dropped " + courseName);
    }

    public void shutdown() { executor.shutdown(); }
}
