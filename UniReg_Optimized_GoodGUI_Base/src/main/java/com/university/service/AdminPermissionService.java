package com.university.service;

import com.university.model.Admin;

import java.util.EnumSet;
import java.util.Set;

public class AdminPermissionService {

    public enum Permission {
        VIEW_STUDENTS,
        MANAGE_STUDENTS,
        VIEW_INSTRUCTORS,
        MANAGE_INSTRUCTORS,
        VIEW_COURSES,
        MANAGE_COURSE_OFFERINGS,
        VIEW_ACADEMIC_SETTINGS,
        MANAGE_REGISTRATION_PERIODS,
        MANAGE_ADMINS,
        DELETE_RECORDS
    }

    private static final Set<Permission> SUPER = EnumSet.allOf(Permission.class);

    private static final Set<Permission> MODERATOR = EnumSet.of(
            Permission.VIEW_STUDENTS,
            Permission.MANAGE_STUDENTS,
            Permission.VIEW_INSTRUCTORS,
            Permission.MANAGE_INSTRUCTORS,
            Permission.VIEW_COURSES,
            Permission.MANAGE_COURSE_OFFERINGS,
            Permission.VIEW_ACADEMIC_SETTINGS,
            Permission.MANAGE_REGISTRATION_PERIODS
    );

    private static final Set<Permission> STANDARD = EnumSet.of(
            Permission.VIEW_STUDENTS,
            Permission.VIEW_INSTRUCTORS,
            Permission.VIEW_COURSES,
            Permission.VIEW_ACADEMIC_SETTINGS
    );

    private AdminPermissionService() {}

    public static boolean hasPermission(Admin admin, Permission permission) {
        if (admin == null || permission == null) return false;

        String level = admin.getAdminLevel() == null ? "STANDARD" : admin.getAdminLevel().trim().toUpperCase();

        return switch (level) {
            case "SUPER" -> SUPER.contains(permission);
            case "MODERATOR" -> MODERATOR.contains(permission);
            default -> STANDARD.contains(permission);
        };
    }

    public static String describeLevel(Admin admin) {
        if (admin == null || admin.getAdminLevel() == null) return "Read-only/support access.";

        return switch (admin.getAdminLevel().trim().toUpperCase()) {
            case "SUPER" -> "Full system access, including admin management and delete operations.";
            case "MODERATOR" -> "Can manage academic data, students, instructors, courses, and registration periods.";
            default -> "Read-only/support access to operational data.";
        };
    }
}
