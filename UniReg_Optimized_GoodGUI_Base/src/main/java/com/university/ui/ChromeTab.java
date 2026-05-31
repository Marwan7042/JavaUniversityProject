package com.university.ui;

import javafx.scene.Node;
import javafx.scene.control.Label;

import java.util.function.Supplier;

public class ChromeTab {

    private final String title;
    private final Supplier<Node> contentSupplier;
    private Node content;
    private final Label tabLabel = new Label();
    private boolean active = false;

    public ChromeTab(String title, Node content) {
        this(title, () -> content);
        this.content = content;
    }

    public ChromeTab(String title, Supplier<Node> contentSupplier) {
        this.title = title;
        this.contentSupplier = contentSupplier;

        tabLabel.setText(title);
        tabLabel.getStyleClass().add("chrome-tab");

        setActive(false);
    }

    public Label getTabLabel() { return tabLabel; }

    public Node getContent() {
        if (content == null && contentSupplier != null) content = contentSupplier.get();
        return content;
    }

    public boolean isActive()  { return active; }
    public String  getTitle()  { return title; }

    public void setActive(boolean active) {
        this.active = active;
        if (active) {
            if (!tabLabel.getStyleClass().contains("active")) {
                tabLabel.getStyleClass().add("active");
            }
        } else {
            tabLabel.getStyleClass().remove("active");
        }
    }
}
