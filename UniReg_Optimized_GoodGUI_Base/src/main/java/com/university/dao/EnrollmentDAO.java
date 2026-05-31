package com.university.dao;

import com.university.model.Enrollment;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;

public class EnrollmentDAO extends BaseDAO {
    public void insertEnrollment(Enrollment e) {
        if (e.getEnrollmentId() == null || e.getEnrollmentId().isBlank()) e.setEnrollmentId(generateEnrollmentId());
        execute("""
            INSERT INTO enrollments (enrollment_id, student_id, offering_id, enrollment_date, status)
            VALUES (?, ?, ?, ?, ?)
        """, e.getEnrollmentId(), e.getStudentId(), e.getOfferingId(), java.sql.Date.valueOf(e.getEnrollmentDate()), e.getDbStatus());
    }

    public void updateEnrollment(Enrollment e) {
        execute("UPDATE enrollments SET status = ? WHERE enrollment_id = ?", e.getDbStatus(), e.getEnrollmentId());
    }

    public List<Enrollment> getEnrollmentsForStudent(String studentId) {
        return queryList("""
            SELECT g.*, e.enrollment_date
            FROM vw_enrollment_gradebook g
            JOIN enrollments e ON g.enrollment_id = e.enrollment_id
            WHERE g.student_id = ?
            ORDER BY g.academic_year DESC, g.term, g.course_id
        """, this::mapEnrollmentFromGradebook, studentId);
    }

    public Enrollment getEnrollment(String enrollmentId) {
        return querySingle("""
            SELECT g.*, e.enrollment_date
            FROM vw_enrollment_gradebook g
            JOIN enrollments e ON g.enrollment_id = e.enrollment_id
            WHERE g.enrollment_id = ?
        """, this::mapEnrollmentFromGradebook, enrollmentId);
    }

    public Enrollment getEnrollmentForStudentAndCourse(String studentId, String courseOrOfferingId) {
        return querySingle("""
            SELECT TOP 1 g.*, e.enrollment_date
            FROM vw_enrollment_gradebook g
            JOIN enrollments e ON g.enrollment_id = e.enrollment_id
            WHERE g.student_id = ?
              AND (g.offering_id = ? OR g.course_id = ?)
            ORDER BY CASE WHEN g.offering_id = ? THEN 0 ELSE 1 END, e.enrollment_date DESC
        """, this::mapEnrollmentFromGradebook, studentId, courseOrOfferingId, courseOrOfferingId, courseOrOfferingId);
    }

    public String generateEnrollmentId() { return generateId("enrollments", "enrollment_id", "ENR", 5); }

    public boolean isAddPeriodOpen(String offeringId) {
        Integer ok = querySingle("""
            SELECT CASE WHEN rp.status = 'OPEN' AND CAST(GETDATE() AS DATE) BETWEEN rp.add_start_date AND rp.add_end_date THEN 1 ELSE 0 END AS is_open
            FROM course_offerings co
            JOIN registration_periods rp ON co.term = rp.term AND co.academic_year = rp.academic_year
            WHERE co.offering_id = ?
        """, rs -> rs.getInt("is_open"), offeringId);
        return ok != null && ok == 1;
    }

    public boolean isDropPeriodOpen(String offeringId) {
        Integer ok = querySingle("""
            SELECT CASE WHEN rp.status = 'OPEN' AND CAST(GETDATE() AS DATE) <= rp.drop_end_date THEN 1 ELSE 0 END AS is_open
            FROM course_offerings co
            JOIN registration_periods rp ON co.term = rp.term AND co.academic_year = rp.academic_year
            WHERE co.offering_id = ?
        """, rs -> rs.getInt("is_open"), offeringId);
        return ok != null && ok == 1;
    }

    public boolean hasStudentTimeConflict(String studentId, String targetOfferingId) {
        Integer count = querySingle("""
            SELECT COUNT(*) AS cnt
            FROM enrollments e
            JOIN room_schedule current_rs ON e.offering_id = current_rs.offering_id
            JOIN room_schedule target_rs ON target_rs.day_of_week = current_rs.day_of_week AND target_rs.slot_id = current_rs.slot_id
            WHERE e.student_id = ?
              AND e.status = 'ENROLLED'
              AND target_rs.offering_id = ?
              AND e.offering_id <> ?
        """, rs -> rs.getInt("cnt"), studentId, targetOfferingId, targetOfferingId);
        return count != null && count > 0;
    }

    public int getActiveCredits(String studentId) {
        Integer credits = querySingle("""
            SELECT COALESCE(SUM(c.credits), 0) AS credits
            FROM enrollments e
            JOIN course_offerings co ON e.offering_id = co.offering_id
            JOIN courses c ON co.course_id = c.course_id
            WHERE e.student_id = ? AND e.status = 'ENROLLED'
        """, rs -> rs.getInt("credits"), studentId);
        return credits == null ? 0 : credits;
    }

    public void setAssessmentScore(String enrollmentId, String componentCode, double score) {
        String scoreId = generateId("student_assessment_scores", "score_id", "SCR", 6);
        execute("""
            DECLARE @component_id INT = (SELECT component_id FROM assessment_components WHERE component_code = ?);
            IF @component_id IS NULL THROW 51020, 'Unknown assessment component code.', 1;

            IF EXISTS (SELECT 1 FROM student_assessment_scores WHERE enrollment_id = ? AND component_id = @component_id)
                UPDATE student_assessment_scores SET score = ? WHERE enrollment_id = ? AND component_id = @component_id;
            ELSE
                INSERT INTO student_assessment_scores (score_id, enrollment_id, component_id, score)
                VALUES (?, ?, @component_id, ?);
        """, componentCode, enrollmentId, score, enrollmentId, scoreId, enrollmentId, score);
    }

    public void assignTotalGradeProportionally(String enrollmentId, double totalGrade) {
        Map<String, Double> max = getAssessmentMaxMarks();
        double ratio = Math.max(0, Math.min(1, totalGrade / 100.0));
        for (Map.Entry<String, Double> entry : max.entrySet()) setAssessmentScore(enrollmentId, entry.getKey(), Math.round(entry.getValue() * ratio * 10.0) / 10.0);
    }

    public Map<String, Double> getAssessmentMaxMarks() {
        Map<String, Double> map = new LinkedHashMap<>();
        queryList("SELECT component_code, max_marks FROM assessment_components ORDER BY display_order", rs -> {
            map.put(rs.getString("component_code"), rs.getDouble("max_marks")); return null;
        });
        return map;
    }

    private Enrollment mapEnrollmentFromGradebook(ResultSet rs) throws SQLException {
        Enrollment e = new Enrollment(rs.getString("enrollment_id"), rs.getString("student_id"), rs.getString("offering_id"),
                rs.getString("course_id"), rs.getString("course_name"), rs.getInt("credits"), rs.getString("term"), rs.getInt("academic_year"));
        e.setStatus(Enrollment.statusFromDb(rs.getString("status")));
        e.setGradeFromLetter(rs.getString("letter_grade"));
        e.setGradePoints(rs.getDouble("gpa_points"));
        java.sql.Date enrollmentDate = rs.getDate("enrollment_date");
        if (enrollmentDate != null) e.setEnrollmentDate(enrollmentDate.toLocalDate());
        e.setWeek7Lecture(rs.getDouble("week7_lecture"));
        e.setWeek7Section(rs.getDouble("week7_section"));
        e.setWeek12Lecture(rs.getDouble("week12_lecture"));
        e.setWeek12Section(rs.getDouble("week12_section"));
        e.setCoursework(rs.getDouble("coursework"));
        e.setFinalExam(rs.getDouble("final_exam"));
        e.setTotalGrade(rs.getDouble("total_grade"));
        e.setMaxGrade(rs.getDouble("max_grade"));
        e.setPercentage(rs.getDouble("percentage"));
        e.setGradedComponents(rs.getInt("graded_components"));
        e.setTotalComponents(rs.getInt("total_components"));
        return e;
    }
}
