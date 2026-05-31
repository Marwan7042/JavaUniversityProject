package com.university.ui;

import javafx.animation.FadeTransition;
import javafx.scene.layout.*;
import javafx.util.Duration;

import java.util.ArrayList;
import java.util.List;

public class ChromeTabPane extends VBox {

    private final HBox tabBar = new HBox(2);
    private final StackPane contentArea = new StackPane();
    private final List<ChromeTab> tabs = new ArrayList<>();
    private ChromeTab activeTab;

    public ChromeTabPane() {
        tabBar.getStyleClass().add("chrome-tab-bar");
        contentArea.getStyleClass().add("chrome-content");

        VBox.setVgrow(contentArea, Priority.ALWAYS);
        this.getChildren().addAll(tabBar, contentArea);
        this.getStyleClass().add("chrome-pane");

        VBox.setVgrow(this, Priority.ALWAYS);
    }

    public void addTab(ChromeTab tab) {
        tabs.add(tab);
        tab.setActive(false);
        tab.getTabLabel().setOnMouseClicked(e -> selectTab(tab));
        tabBar.getChildren().add(tab.getTabLabel());
        if (activeTab == null) selectTab(tab);
    }

    public void selectTab(ChromeTab tab) {
        for (ChromeTab t : tabs) t.setActive(false);
        activeTab = tab;
        activeTab.setActive(true);
        contentArea.getChildren().setAll(tab.getContent());
        FadeTransition ft = new FadeTransition(Duration.millis(250), contentArea);
        ft.setFromValue(0.55);
        ft.setToValue(1.0);
        ft.play();
    }
}