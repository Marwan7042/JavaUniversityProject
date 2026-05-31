package com.university.util;

import javafx.beans.property.SimpleObjectProperty;
import javafx.beans.value.ObservableValue;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.util.Callback;

import java.util.function.Function;

public class GlassTable<S> {
    private final TableView<S> table;

    private GlassTable() {
        this.table = new TableView<>();
        UIHelper.styleGlassTable(table);
    }

    public static <S> GlassTable<S> create() {
        return new GlassTable<>();
    }

    public GlassTable<S> prop(String header, String propertyName) {
        UIHelper.addGlassCol(table, header, propertyName, null);
        return this;
    }

    public <T> GlassTable<S> col(String header, Function<S, T> mapper) {
        Callback<TableColumn.CellDataFeatures<S, T>, ObservableValue<T>> factory = 
            data -> new SimpleObjectProperty<>(mapper.apply(data.getValue()));
        UIHelper.addGlassCol(table, header, null, factory);
        return this;
    }

    public GlassTable<S> statusCol(String header, Function<S, String> mapper) {
        TableColumn<S, String> col = new TableColumn<>(header);
        col.setCellValueFactory(data -> new SimpleObjectProperty<>(mapper.apply(data.getValue())));
        UIHelper.makeStatusColumn(col);
        table.getColumns().add(col);
        return this;
    }

    public GlassTable<S> prefHeight(double height) {
        table.setPrefHeight(height);
        return this;
    }

    public TableView<S> build() {
        return table;
    }
}
