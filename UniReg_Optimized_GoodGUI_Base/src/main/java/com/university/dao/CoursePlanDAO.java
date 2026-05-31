package com.university.dao;

import com.university.model.Course;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

public class CoursePlanDAO extends BaseDAO {

    public List<Course> getCoursesForOfferingPicker(String majorIdOrName, int studentYear, String term, boolean showAllCourses) {
        if (showAllCourses) {
            return queryList("""
                SELECT
                    c.course_id,
                    c.course_name,
                    c.description,
                    c.credits,
                    d.department_name,
                    CAST(0 AS bit) AS is_required
                FROM courses c
                JOIN departments d ON c.department_id = d.department_id
                ORDER BY d.department_name, c.course_id
            """, this::mapCatalogCourse);
        }

        String majorId = findMajorId(majorIdOrName);
        int year = studentYear <= 0 ? 1 : studentYear;
        String cleanTerm = safeTerm(term);

        return queryList("""
            SELECT
                c.course_id,
                c.course_name,
                c.description,
                c.credits,
                d.department_name,
                cap.is_required
            FROM course_academic_plan cap
            JOIN courses c ON cap.course_id = c.course_id
            JOIN departments d ON c.department_id = d.department_id
            WHERE cap.major_id = ?
              AND cap.student_year = ?
              AND cap.recommended_term = ?
              AND cap.is_active = 1
            ORDER BY cap.is_required DESC, c.course_id
        """, this::mapCatalogCourse, majorId, year, cleanTerm);
    }

    public int getPlanCountForCourse(String courseId) {
        Integer count = querySingle("""
            SELECT COUNT(*)
            FROM course_academic_plan
            WHERE course_id = ?
              AND is_active = 1
        """, rs -> rs.getInt(1), courseId);
        return count == null ? 0 : count;
    }

    private Course mapCatalogCourse(ResultSet rs) throws SQLException {
        Course c = new Course();
        c.setCourseId(rs.getString("course_id"));
        c.setCourseName(rs.getString("course_name"));
        c.setDescription(rs.getString("description"));
        c.setCredits(rs.getInt("credits"));
        c.setDepartment(rs.getString("department_name"));
        return c;
    }
}
