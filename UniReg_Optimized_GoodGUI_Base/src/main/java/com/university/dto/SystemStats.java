package com.university.dto;

public record SystemStats(
        long totalStudents,
        long totalInstructors,
        long totalCourses,
        long activeEnrollments,
        double averageGpa,
        long openCourses
) {}
