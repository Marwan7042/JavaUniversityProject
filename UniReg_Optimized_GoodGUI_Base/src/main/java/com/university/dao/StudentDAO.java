package com.university.dao;

import com.university.model.Enrollment;
import com.university.model.Student;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;

public class StudentDAO extends BaseDAO {
    public void insertStudent(Student s) {
        String majorId = findMajorId(s.getMajor());
        execute("""
            IF NOT EXISTS (SELECT 1 FROM students WHERE id = ?)
                INSERT INTO students (id, first_name, last_name, email, personal_email, password, phone, major_id, year, status)
                VALUES (?, ?, ?, ?, NULL, ?, ?, ?, ?, 'ACTIVE')
            ELSE
                UPDATE students SET first_name = ?, last_name = ?, email = ?, password = ?, phone = ?, major_id = ?, year = ? WHERE id = ?
        """, s.getId(),
                s.getId(), s.getFirstName(), s.getLastName(), s.getEmail(), s.getPassword(), s.getPhone(), majorId, s.getYear(),
                s.getFirstName(), s.getLastName(), s.getEmail(), s.getPassword(), s.getPhone(), majorId, s.getYear(), s.getId());
    }

    public void updateStudentGpa(String studentId, double gpa) { /* GPA is view-calculated. */ }
    public void deleteStudent(String id) { execute("DELETE FROM students WHERE id = ?", id); }

    public Optional<Student> findStudentByEmail(String email) {
        Student s = querySingle("SELECT * FROM vw_student_full WHERE LOWER(email) = LOWER(?)", this::mapStudentFromView, email);
        return Optional.ofNullable(s);
    }

    public Student getStudent(String id) { return querySingle("SELECT * FROM vw_student_full WHERE id = ?", this::mapStudentFromView, id); }

    public Map<String, Student> getAllStudents() {
        Map<String, Student> map = new LinkedHashMap<>();
        List<Student> list = queryList("SELECT * FROM vw_student_full ORDER BY id", rs -> mapStudentFromView(rs, "", null));
        List<String> ids = list.stream().map(Student::getId).toList();
        list.forEach(s -> map.put(s.getId(), s));
        if (!ids.isEmpty()) {
            Map<String, String> passwords = getPasswordsForUsers("students", ids);
            Map<String, List<Enrollment>> enrollments = getEnrollmentsForStudents(ids);
            for (String id : ids) {
                Student s = map.get(id);
                if (s == null) continue;
                s.setPassword(passwords.getOrDefault(id, ""));
                s.setEnrollments(enrollments.getOrDefault(id, new ArrayList<>()));
            }
        }
        return map;
    }

    private Student mapStudentFromView(ResultSet rs) throws SQLException {
        String id = rs.getString("id");
        return mapStudentFromView(rs, getPasswordForUser("students", id), getEnrollmentsForStudent(id));
    }

    private Student mapStudentFromView(ResultSet rs, String password, List<Enrollment> enrollments) throws SQLException {
        Student s = new Student(rs.getString("id"), rs.getString("first_name"), rs.getString("last_name"), rs.getString("email"),
                password == null ? "" : password, rs.getString("phone"), rs.getString("major_name"), rs.getInt("year"));
        s.setGpa(rs.getDouble("gpa"));
        s.setEnrollments(enrollments == null ? new ArrayList<>() : new ArrayList<>(enrollments));
        return s;
    }

    public String generateStudentId() { return generateId("students", "id", "STU", 3); }

    public List<Student> getStudentsInCourse(String courseOrOfferingId) {
        List<String> ids = queryList("""
            SELECT DISTINCT s.id
            FROM students s
            JOIN enrollments e ON s.id = e.student_id
            JOIN course_offerings co ON e.offering_id = co.offering_id
            WHERE e.status = 'ENROLLED'
              AND (co.offering_id = ? OR co.course_id = ?)
            ORDER BY s.id
        """, rs -> rs.getString("id"), courseOrOfferingId, courseOrOfferingId);
        return getStudentsByIds(ids);
    }

    public List<Student> getStudentsByIds(List<String> studentIds) {
        if (studentIds == null || studentIds.isEmpty()) return new ArrayList<>();
        List<String> ids = new ArrayList<>(new LinkedHashSet<>(studentIds));
        Map<String, Student> map = new LinkedHashMap<>();
        String sql = "SELECT * FROM vw_student_full WHERE id IN (" + buildPlaceholders(ids.size()) + ") ORDER BY id";
        queryList(sql, rs -> { Student s = mapStudentFromView(rs, "", null); map.put(s.getId(), s); return s; }, ids.toArray());
        Map<String, String> passwords = getPasswordsForUsers("students", ids);
        Map<String, List<Enrollment>> enrollments = getEnrollmentsForStudents(ids);
        for (Student s : map.values()) {
            s.setPassword(passwords.getOrDefault(s.getId(), ""));
            s.setEnrollments(enrollments.getOrDefault(s.getId(), new ArrayList<>()));
        }
        return new ArrayList<>(map.values());
    }

    public Map<String, List<Enrollment>> getEnrollmentsForStudents(Collection<String> studentIds) {
        Map<String, List<Enrollment>> map = new LinkedHashMap<>();
        if (studentIds == null || studentIds.isEmpty()) return map;
        List<String> ids = new ArrayList<>(new LinkedHashSet<>(studentIds));
        String sql = "SELECT g.*, e.enrollment_date FROM vw_enrollment_gradebook g JOIN enrollments e ON g.enrollment_id = e.enrollment_id " +
                "WHERE g.student_id IN (" + buildPlaceholders(ids.size()) + ") ORDER BY g.student_id, g.academic_year, g.term, g.course_id";
        queryList(sql, rs -> {
            map.computeIfAbsent(rs.getString("student_id"), k -> new ArrayList<>()).add(mapEnrollmentFromGradebook(rs));
            return null;
        }, ids.toArray());
        return map;
    }

    public List<Enrollment> getEnrollmentsForStudent(String studentId) {
        return queryList("""
            SELECT g.*, e.enrollment_date
            FROM vw_enrollment_gradebook g
            JOIN enrollments e ON g.enrollment_id = e.enrollment_id
            WHERE g.student_id = ?
            ORDER BY g.academic_year, g.term, g.course_id
        """, this::mapEnrollmentFromGradebook, studentId);
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
