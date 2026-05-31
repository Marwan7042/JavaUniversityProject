package com.university.dao;

import com.university.model.*;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public class DatabaseManager {
    private static DatabaseManager instance;

    private final AdminDAO adminDAO = new AdminDAO();
    private final InstructorDAO instructorDAO = new InstructorDAO();
    private final StudentDAO studentDAO = new StudentDAO();
    private final CourseDAO courseDAO = new CourseDAO();
    private final EnrollmentDAO enrollmentDAO = new EnrollmentDAO();
    private final ScheduleDAO scheduleDAO = new ScheduleDAO();
    private final RegistrationPeriodDAO registrationPeriodDAO = new RegistrationPeriodDAO();

    private DatabaseManager() { verifySchema(); }

    public static synchronized DatabaseManager getInstance() {
        if (instance == null) instance = new DatabaseManager();
        return instance;
    }

    public Connection getConnection() throws SQLException { return BaseDAO.dataSource.getConnection(); }

    private void verifySchema() {
        String[] objects = {"students", "instructors", "admins", "courses", "course_offerings", "registration_periods", "enrollments", "assessment_components", "student_assessment_scores", "room_schedule", "rooms", "time_slots", "vw_course_full", "vw_student_full", "vw_instructor_full", "vw_enrollment_gradebook"};
        try (Connection conn = getConnection()) {
            for (String obj : objects) {
                boolean exists;
                try (var ps = conn.prepareStatement("SELECT 1 FROM sys.objects WHERE name = ? AND schema_id = SCHEMA_ID('dbo')")) {
                    ps.setString(1, obj);
                    try (var rs = ps.executeQuery()) { exists = rs.next(); }
                }
                if (!exists) throw new IllegalStateException("Required database object dbo." + obj + " was not found.");
            }
        } catch (Exception e) {
            throw new RuntimeException("Database schema verification failed: " + e.getMessage(), e);
        }
    }

    public void insertAdmin(Admin a) { adminDAO.insertAdmin(a); }
    public void deleteAdmin(String id) { adminDAO.deleteAdmin(id); }
    public String generateAdminId() { return adminDAO.generateAdminId(); }
    public Optional<Admin> findAdminByEmail(String email) { return adminDAO.findAdminByEmail(email); }
    public Map<String, Admin> getAllAdmins() { return adminDAO.getAllAdmins(); }

    public void insertInstructor(Instructor i) { instructorDAO.insertInstructor(i); }
    public void deleteInstructor(String id) { instructorDAO.deleteInstructor(id); }
    public Optional<Instructor> findInstructorByEmail(String email) { return instructorDAO.findInstructorByEmail(email); }
    public Map<String, Instructor> getAllInstructors() { return instructorDAO.getAllInstructors(); }
    public Instructor getInstructor(String id) { return instructorDAO.getInstructor(id); }
    public String generateInstructorId() { return instructorDAO.generateInstructorId(); }

    public void insertStudent(Student s) { studentDAO.insertStudent(s); }
    public void updateStudentGpa(String studentId, double gpa) { studentDAO.updateStudentGpa(studentId, gpa); }
    public void deleteStudent(String id) { studentDAO.deleteStudent(id); }
    public Optional<Student> findStudentByEmail(String email) { return studentDAO.findStudentByEmail(email); }
    public Student getStudent(String id) { return studentDAO.getStudent(id); }
    public Map<String, Student> getAllStudents() { return studentDAO.getAllStudents(); }
    public String generateStudentId() { return studentDAO.generateStudentId(); }
    public List<Student> getStudentsInCourse(String courseOrOfferingId) { return studentDAO.getStudentsInCourse(courseOrOfferingId); }

    public void insertCourse(Course c) { courseDAO.insertCourse(c); }
    public void deleteCourse(String courseOrOfferingId) { courseDAO.deleteCourse(courseOrOfferingId); }
    public Course getCourse(String courseOrOfferingId) { return courseDAO.getCourse(courseOrOfferingId); }
    public Map<String, Course> getAllCourses() { return courseDAO.getAllCourses(); }
    public String generateOfferingId() { return courseDAO.generateOfferingId(); }

    public void insertEnrollment(Enrollment e) { enrollmentDAO.insertEnrollment(e); }
    public void updateEnrollment(Enrollment e) { enrollmentDAO.updateEnrollment(e); }
    public List<Enrollment> getEnrollmentsForStudent(String studentId) { return enrollmentDAO.getEnrollmentsForStudent(studentId); }
    public Enrollment getEnrollment(String enrollmentId) { return enrollmentDAO.getEnrollment(enrollmentId); }
    public Enrollment getEnrollmentForStudentAndCourse(String studentId, String courseOrOfferingId) { return enrollmentDAO.getEnrollmentForStudentAndCourse(studentId, courseOrOfferingId); }
    public String generateEnrollmentId() { return enrollmentDAO.generateEnrollmentId(); }
    public boolean isAddPeriodOpen(String offeringId) { return enrollmentDAO.isAddPeriodOpen(offeringId); }
    public boolean isDropPeriodOpen(String offeringId) { return enrollmentDAO.isDropPeriodOpen(offeringId); }
    public boolean hasStudentTimeConflict(String studentId, String targetOfferingId) { return enrollmentDAO.hasStudentTimeConflict(studentId, targetOfferingId); }
    public int getActiveCredits(String studentId) { return enrollmentDAO.getActiveCredits(studentId); }
    public void setAssessmentScore(String enrollmentId, String componentCode, double score) { enrollmentDAO.setAssessmentScore(enrollmentId, componentCode, score); }
    public void assignTotalGradeProportionally(String enrollmentId, double totalGrade) { enrollmentDAO.assignTotalGradeProportionally(enrollmentId, totalGrade); }
    public Map<String, Double> getAssessmentMaxMarks() { return enrollmentDAO.getAssessmentMaxMarks(); }

    public List<RegistrationPeriod> getAllRegistrationPeriods() { return registrationPeriodDAO.getAllRegistrationPeriods(); }
    public void saveRegistrationPeriod(RegistrationPeriod period) { registrationPeriodDAO.saveRegistrationPeriod(period); }
    public void deleteRegistrationPeriod(int periodId) { registrationPeriodDAO.deleteRegistrationPeriod(periodId); }

    public List<ScheduleEntry> getStudentSchedule(String studentId) { return scheduleDAO.getStudentSchedule(studentId); }
    public List<ScheduleEntry> getInstructorSchedule(String instructorId) { return scheduleDAO.getInstructorSchedule(instructorId); }
    public String getInstructorRoleForOffering(String instructorId, String offeringId) { return scheduleDAO.getInstructorRoleForOffering(instructorId, offeringId); }
}
