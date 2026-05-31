package com.university.dao;

import com.university.model.Course;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;

public class CourseDAO extends BaseDAO {
    public void insertCourse(Course c) {
        String departmentId = findDepartmentId(c.getDepartment());
        String offeringId = c.getOfferingId();
        if (offeringId == null || offeringId.isBlank()) {
            offeringId = getOfferingIdByCourseOrNull(c.getCourseId(), c.getTerm(), c.getAcademicYear(), c.getSectionCode());
            if (offeringId == null) offeringId = generateOfferingId();
            c.setOfferingId(offeringId);
        }
        ensureRegistrationPeriod(c.getTerm(), c.getAcademicYear());

        execute("""
            IF NOT EXISTS (SELECT 1 FROM courses WHERE course_id = ?)
                INSERT INTO courses (course_id, course_name, description, department_id, credits)
                VALUES (?, ?, ?, ?, ?)
            ELSE
                UPDATE courses SET course_name = ?, description = ?, department_id = ?, credits = ? WHERE course_id = ?
        """, c.getCourseId(),
                c.getCourseId(), c.getCourseName(), c.getDescription(), departmentId, c.getCredits(),
                c.getCourseName(), c.getDescription(), departmentId, c.getCredits(), c.getCourseId());

        execute("""
            IF NOT EXISTS (SELECT 1 FROM course_offerings WHERE offering_id = ?)
                INSERT INTO course_offerings (offering_id, course_id, term, academic_year, section_code, capacity, status)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ELSE
                UPDATE course_offerings SET course_id = ?, term = ?, academic_year = ?, section_code = ?, capacity = ?, status = ? WHERE offering_id = ?
        """, offeringId,
                offeringId, c.getCourseId(), safeTerm(c.getTerm()), safeYear(c.getAcademicYear()), safeSection(c.getSectionCode()), c.getCapacity(), safeStatus(c.getStatus().name()),
                c.getCourseId(), safeTerm(c.getTerm()), safeYear(c.getAcademicYear()), safeSection(c.getSectionCode()), c.getCapacity(), safeStatus(c.getStatus().name()), offeringId);

        if (c.getInstructorId() != null && !c.getInstructorId().isBlank()) {
            String role = safeInstructorRole(c.getInstructorRole(), c.getMeetingType());
            execute("""
                IF NOT EXISTS (SELECT 1 FROM course_instructors WHERE offering_id = ? AND instructor_id = ?)
                    INSERT INTO course_instructors (offering_id, instructor_id, role) VALUES (?, ?, ?)
                ELSE
                    UPDATE course_instructors SET role = ? WHERE offering_id = ? AND instructor_id = ?
            """, offeringId, c.getInstructorId(), offeringId, c.getInstructorId(), role, role, offeringId, c.getInstructorId());
        }

        if (c.getRoom() != null && !c.getRoom().isBlank() && c.getDayOfWeek() != null && c.getSlotId() != null) {
            execute("DELETE FROM room_schedule WHERE offering_id = ? AND meeting_type = ?", offeringId, safeMeetingType(c.getMeetingType()));
            execute("""
                INSERT INTO room_schedule (offering_id, room_id, instructor_id, day_of_week, slot_id, meeting_type)
                VALUES (?, ?, ?, ?, ?, ?)
            """, offeringId, c.getRoom(), c.getInstructorId(), c.getDayOfWeek(), c.getSlotId(), safeMeetingType(c.getMeetingType()));
        }
    }

    public void deleteCourse(String courseOrOfferingId) {
        Course course = getCourse(courseOrOfferingId);
        if (course == null) return;

        if (courseOrOfferingId.toUpperCase().startsWith("OFF")) {
            execute("""
                DELETE sas
                FROM student_assessment_scores sas
                JOIN enrollments e ON sas.enrollment_id = e.enrollment_id
                WHERE e.offering_id = ?
            """, course.getOfferingId());
            execute("DELETE FROM enrollments WHERE offering_id = ?", course.getOfferingId());
            execute("DELETE FROM room_schedule WHERE offering_id = ?", course.getOfferingId());
            execute("DELETE FROM course_instructors WHERE offering_id = ?", course.getOfferingId());
            execute("DELETE FROM course_offerings WHERE offering_id = ?", course.getOfferingId());
        } else {
            execute("""
                DELETE sas
                FROM student_assessment_scores sas
                JOIN enrollments e ON sas.enrollment_id = e.enrollment_id
                JOIN course_offerings co ON e.offering_id = co.offering_id
                WHERE co.course_id = ?
            """, course.getCourseId());
            execute("""
                DELETE e
                FROM enrollments e
                JOIN course_offerings co ON e.offering_id = co.offering_id
                WHERE co.course_id = ?
            """, course.getCourseId());
            execute("""
                DELETE rs
                FROM room_schedule rs
                JOIN course_offerings co ON rs.offering_id = co.offering_id
                WHERE co.course_id = ?
            """, course.getCourseId());
            execute("""
                DELETE ci
                FROM course_instructors ci
                JOIN course_offerings co ON ci.offering_id = co.offering_id
                WHERE co.course_id = ?
            """, course.getCourseId());
            execute("DELETE FROM course_offerings WHERE course_id = ?", course.getCourseId());
            execute("DELETE FROM course_prerequisites WHERE course_id = ? OR prerequisite_id = ?", course.getCourseId(), course.getCourseId());
            execute("DELETE FROM courses WHERE course_id = ?", course.getCourseId());
        }
    }


    public Map<String, Course> getCourseCatalog() {
        Map<String, Course> map = new LinkedHashMap<>();

        queryList("""
            SELECT
                c.course_id,
                c.course_name,
                c.description,
                c.credits,
                d.department_name
            FROM courses c
            JOIN departments d ON c.department_id = d.department_id
            ORDER BY d.department_name, c.course_id
        """, rs -> {
            Course c = new Course();
            c.setCourseId(rs.getString("course_id"));
            c.setCourseName(rs.getString("course_name"));
            c.setDescription(rs.getString("description"));
            c.setCredits(rs.getInt("credits"));
            c.setDepartment(rs.getString("department_name"));
            map.put(c.getCourseId(), c);
            return null;
        });

        return map;
    }

    public void insertCatalogCourse(Course c) {
        String departmentId = findDepartmentId(c.getDepartment());

        execute("""
            IF NOT EXISTS (SELECT 1 FROM courses WHERE course_id = ?)
                INSERT INTO courses (course_id, course_name, description, department_id, credits)
                VALUES (?, ?, ?, ?, ?)
            ELSE
                UPDATE courses
                SET course_name = ?, description = ?, department_id = ?, credits = ?
                WHERE course_id = ?
        """,
                c.getCourseId(),
                c.getCourseId(), c.getCourseName(), c.getDescription(), departmentId, c.getCredits(),
                c.getCourseName(), c.getDescription(), departmentId, c.getCredits(), c.getCourseId()
        );
    }

    public void deleteCatalogCourse(String courseId) {
        deleteCourse(courseId);
    }

    public Course getCourse(String courseOrOfferingId) {
        return querySingle("""
            SELECT TOP 1 * FROM vw_course_full
            WHERE offering_id = ? OR course_id = ?
            ORDER BY CASE WHEN offering_id = ? THEN 0 ELSE 1 END,
                     academic_year DESC,
                     CASE term WHEN 'TERM1' THEN 3 WHEN 'TERM2' THEN 2 WHEN 'SUMMER' THEN 1 ELSE 0 END DESC
        """, this::mapCourseFromView, courseOrOfferingId, courseOrOfferingId, courseOrOfferingId);
    }

    public Map<String, Course> getAllCourses() {
        Map<String, Course> map = new LinkedHashMap<>();
        List<Course> list = queryList("""
            SELECT * FROM vw_course_full
            ORDER BY academic_year DESC,
                     CASE term WHEN 'TERM1' THEN 1 WHEN 'TERM2' THEN 2 WHEN 'SUMMER' THEN 3 ELSE 4 END,
                     course_id, section_code
        """, rs -> mapCourseFromView(rs, null, null));
        if (!list.isEmpty()) {
            List<String> courseIds = list.stream().map(Course::getCourseId).distinct().toList();
            List<String> offeringIds = list.stream().map(Course::getOfferingId).distinct().toList();
            Map<String, List<String>> prereq = getPrerequisitesForCourses(courseIds);
            Map<String, List<String>> enrolled = getEnrolledStudentIdsForOfferings(offeringIds);
            for (Course c : list) {
                c.setPrerequisiteIds(prereq.getOrDefault(c.getCourseId(), new ArrayList<>()));
                c.setEnrolledStudentIds(enrolled.getOrDefault(c.getOfferingId(), new ArrayList<>()));
                map.put(c.getOfferingId(), c);
            }
        }
        return map;
    }

    private Course mapCourseFromView(ResultSet rs) throws SQLException {
        return mapCourseFromView(rs, getPrerequisitesForCourse(rs.getString("course_id")), getEnrolledStudentIdsForOffering(rs.getString("offering_id")));
    }

    private Course mapCourseFromView(ResultSet rs, List<String> prereq, List<String> enrolledIds) throws SQLException {
        Course.Status status = "OPEN".equalsIgnoreCase(rs.getString("status")) ? Course.Status.OPEN : Course.Status.CLOSED;
        Course c = new Course(rs.getString("offering_id"), rs.getString("course_id"), rs.getString("course_name"),
                rs.getString("department_name"), rs.getInt("credits"), rs.getString("term"), rs.getInt("academic_year"),
                rs.getString("section_code"), rs.getInt("capacity"), rs.getInt("enrolled"), rs.getString("instructor_ids"),
                rs.getString("instructor_names"), rs.getString("schedule"), rs.getString("room_id"), rs.getString("description"), status);
        c.setPrerequisiteIds(prereq == null ? new ArrayList<>() : new ArrayList<>(prereq));
        c.setEnrolledStudentIds(enrolledIds == null ? new ArrayList<>() : new ArrayList<>(enrolledIds));

        ScheduleBits bits = firstScheduleBits(c.getOfferingId());
        if (bits != null) {
            c.setDayOfWeek(bits.dayOfWeek);
            c.setSlotId(bits.slotId);
            c.setMeetingType(bits.meetingType);
            c.setRoom(bits.roomId);
            c.setRoomType(bits.roomType);
            if (c.getInstructorId() == null || c.getInstructorId().isBlank()) {
                c.setInstructorId(bits.instructorId);
            }
        }

        return c;
    }

    private ScheduleBits firstScheduleBits(String offeringId) {
        return querySingle("""
            SELECT TOP 1
                rs.day_of_week,
                rs.slot_id,
                rs.meeting_type,
                rs.room_id,
                r.room_type,
                rs.instructor_id
            FROM room_schedule rs
            LEFT JOIN rooms r ON rs.room_id = r.room_id
            WHERE rs.offering_id = ?
            ORDER BY
                CASE rs.meeting_type WHEN 'LECTURE' THEN 1 WHEN 'SECTION' THEN 2 WHEN 'LAB' THEN 3 ELSE 4 END,
                rs.schedule_id
        """, rs -> new ScheduleBits(
                rs.getString("day_of_week"),
                rs.getInt("slot_id"),
                rs.getString("meeting_type"),
                rs.getString("room_id"),
                rs.getString("room_type"),
                rs.getString("instructor_id")
        ), offeringId);
    }

    private record ScheduleBits(String dayOfWeek, int slotId, String meetingType, String roomId, String roomType, String instructorId) {}


    public void applyOfferingStatusForTerm(String term, int academicYear) {
        String cleanTerm = safeTerm(term);
        int cleanYear = safeYear(academicYear);

        execute("""
            UPDATE course_offerings
            SET status =
                CASE
                    WHEN term = ? AND academic_year = ? THEN 'OPEN'
                    ELSE 'CLOSED'
                END
            WHERE academic_year = ?
        """, cleanTerm, cleanYear, cleanYear);
    }

    public String generateOfferingId() { return generateId("course_offerings", "offering_id", "OFF", 3); }

    private String getOfferingIdByCourseOrNull(String courseId, String term, int academicYear, String sectionCode) {
        return querySingle("""
            SELECT TOP 1 offering_id FROM course_offerings
            WHERE course_id = ? AND term = ? AND academic_year = ? AND section_code = ?
        """, rs -> rs.getString("offering_id"), courseId, safeTerm(term), safeYear(academicYear), safeSection(sectionCode));
    }

    private void ensureRegistrationPeriod(String term, int academicYear) {
        execute("""
            IF NOT EXISTS (SELECT 1 FROM registration_periods WHERE term = ? AND academic_year = ?)
                INSERT INTO registration_periods (term, academic_year, add_start_date, add_end_date, drop_end_date, status)
                VALUES (?, ?, '2026-01-01', '2099-12-31', '2099-12-31', 'OPEN')
        """, safeTerm(term), safeYear(academicYear), safeTerm(term), safeYear(academicYear));
    }

    private String safeMeetingType(String value) {
        if (value == null || value.isBlank()) return "LECTURE";
        String v = value.toUpperCase();
        if (!v.equals("LECTURE") && !v.equals("SECTION") && !v.equals("LAB")) return "LECTURE";
        return v;
    }

    private String safeInstructorRole(String role, String meetingType) {
        if (role != null && !role.isBlank()) {
            String r = role.toUpperCase();
            if (r.equals("LECTURE") || r.equals("ASSISTANT") || r.equals("LAB")) return r;
        }
        return "LAB".equalsIgnoreCase(meetingType) ? "LAB" : "SECTION".equalsIgnoreCase(meetingType) ? "ASSISTANT" : "LECTURE";
    }

    private List<String> getPrerequisitesForCourse(String courseId) {
        return queryList("SELECT prerequisite_id FROM course_prerequisites WHERE course_id = ? ORDER BY prerequisite_id", rs -> rs.getString("prerequisite_id"), courseId);
    }

    private Map<String, List<String>> getPrerequisitesForCourses(Collection<String> courseIds) {
        Map<String, List<String>> map = new LinkedHashMap<>();
        if (courseIds == null || courseIds.isEmpty()) return map;
        List<String> ids = new ArrayList<>(new LinkedHashSet<>(courseIds));
        String sql = "SELECT course_id, prerequisite_id FROM course_prerequisites WHERE course_id IN (" + buildPlaceholders(ids.size()) + ") ORDER BY course_id, prerequisite_id";
        queryList(sql, rs -> { map.computeIfAbsent(rs.getString("course_id"), k -> new ArrayList<>()).add(rs.getString("prerequisite_id")); return null; }, ids.toArray());
        return map;
    }

    private List<String> getEnrolledStudentIdsForOffering(String offeringId) {
        return queryList("SELECT student_id FROM enrollments WHERE offering_id = ? AND status = 'ENROLLED' ORDER BY student_id", rs -> rs.getString("student_id"), offeringId);
    }

    private Map<String, List<String>> getEnrolledStudentIdsForOfferings(Collection<String> offeringIds) {
        Map<String, List<String>> map = new LinkedHashMap<>();
        if (offeringIds == null || offeringIds.isEmpty()) return map;
        List<String> ids = new ArrayList<>(new LinkedHashSet<>(offeringIds));
        String sql = "SELECT offering_id, student_id FROM enrollments WHERE offering_id IN (" + buildPlaceholders(ids.size()) + ") AND status = 'ENROLLED' ORDER BY offering_id, student_id";
        queryList(sql, rs -> { map.computeIfAbsent(rs.getString("offering_id"), k -> new ArrayList<>()).add(rs.getString("student_id")); return null; }, ids.toArray());
        return map;
    }
}
