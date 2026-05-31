package com.university.util;

import java.util.function.Consumer;
import java.util.function.Function;

public class Result<T> {
    private final T value;
    private final String error;
    private final boolean success;

    private Result(T value, String error, boolean success) {
        this.value = value;
        this.error = error;
        this.success = success;
    }

    public static <T> Result<T> success(T value) {
        return new Result<>(value, null, true);
    }

    public static <T> Result<T> error(String message) {
        return new Result<>(null, message, false);
    }

    public boolean isSuccess() { return success; }
    public boolean isError() { return !success; }
    public T getValue() { return value; }
    public String getError() { return error; }

    public void ifSuccess(Consumer<T> consumer) {
        if (success) consumer.accept(value);
    }

    public void ifError(Consumer<String> consumer) {
        if (!success) consumer.accept(error);
    }

    public <U> Result<U> map(Function<T, U> mapper) {
        if (success) return Result.success(mapper.apply(value));
        return Result.error(error);
    }
}
