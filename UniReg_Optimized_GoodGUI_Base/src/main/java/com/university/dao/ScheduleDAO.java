package com.university.dao;

import com.university.model.ScheduleEntry;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

public class ScheduleDAO extends BaseDAO {
    public List<ScheduleEntry> getStudentSchedule(String studentId) {
        return queryList("""
            SELECT e.student_id, e.enrollment_id, co.offering_id, co.course_id, c.course_name, c.credits,
                   co.term, co.academic_year, co.section_code,
                   rs.day_of_week, rs.slot_id, rs.meeting_type,
                   CONVERT(VARCHAR(5), ts.start_time, 108) AS start_time,
                   CONVERT(VARCHAR(5), ts.end_time, 108) AS end_time,
                   rs.room_id, r.room_type,
                   rs.instructor_id AS instructor_ids,
                   COALESCE(i.title + ' ' + i.first_name + ' ' + i.last_name, '') AS instructor_names,
                   e.status AS enrollment_status
            FROM enrollments e
            JOIN course_offerings co ON e.offering_id = co.offering_id
            JOIN courses c ON co.course_id = c.course_id
            JOIN room_schedule rs ON co.offering_id = rs.offering_id
            JOIN rooms r ON rs.room_id = r.room_id
            JOIN time_slots ts ON rs.slot_id = ts.slot_id
            LEFT JOIN instructors i ON rs.instructor_id = i.id
            WHERE e.student_id = ? AND e.status = 'ENROLLED'
            ORDER BY CASE rs.day_of_week WHEN 'Saturday' THEN 1 WHEN 'Sunday' THEN 2 WHEN 'Monday' THEN 3 WHEN 'Tuesday' THEN 4 WHEN 'Wednesday' THEN 5 WHEN 'Thursday' THEN 6 ELSE 7 END,
                     rs.slot_id, co.course_id
        """, this::mapScheduleEntry, studentId);
    }

    public List<ScheduleEntry> getInstructorSchedule(String instructorId) {
        return queryList("""
            SELECT NULL AS student_id, NULL AS enrollment_id, co.offering_id, co.course_id, c.course_name, c.credits,
                   co.term, co.academic_year, co.section_code,
                   rs.day_of_week, rs.slot_id, rs.meeting_type,
                   CONVERT(VARCHAR(5), ts.start_time, 108) AS start_time,
                   CONVERT(VARCHAR(5), ts.end_time, 108) AS end_time,
                   rs.room_id, r.room_type,
                   rs.instructor_id AS instructor_ids,
                   COALESCE(i.title + ' ' + i.first_name + ' ' + i.last_name, '') AS instructor_names,
                   co.status AS enrollment_status
            FROM room_schedule rs
            JOIN course_offerings co ON rs.offering_id = co.offering_id
            JOIN courses c ON co.course_id = c.course_id
            JOIN rooms r ON rs.room_id = r.room_id
            JOIN time_slots ts ON rs.slot_id = ts.slot_id
            LEFT JOIN instructors i ON rs.instructor_id = i.id
            WHERE rs.instructor_id = ?
            ORDER BY CASE rs.day_of_week WHEN 'Saturday' THEN 1 WHEN 'Sunday' THEN 2 WHEN 'Monday' THEN 3 WHEN 'Tuesday' THEN 4 WHEN 'Wednesday' THEN 5 WHEN 'Thursday' THEN 6 ELSE 7 END,
                     rs.slot_id, co.course_id
        """, this::mapScheduleEntry, instructorId);
    }

    public String getInstructorRoleForOffering(String instructorId, String offeringId) {
        String role = querySingle("""
            SELECT TOP 1 role FROM course_instructors WHERE instructor_id = ? AND offering_id = ?
            ORDER BY CASE role WHEN 'LECTURE' THEN 1 WHEN 'ASSISTANT' THEN 2 WHEN 'LAB' THEN 3 ELSE 4 END
        """, rs -> rs.getString("role"), instructorId, offeringId);
        if (role != null && !role.isBlank()) return role;
        role = querySingle("""
            SELECT TOP 1 CASE WHEN meeting_type = 'LAB' THEN 'LAB' WHEN meeting_type = 'SECTION' THEN 'ASSISTANT' ELSE 'LECTURE' END AS role
            FROM room_schedule WHERE instructor_id = ? AND offering_id = ?
            ORDER BY CASE meeting_type WHEN 'LECTURE' THEN 1 WHEN 'SECTION' THEN 2 WHEN 'LAB' THEN 3 ELSE 4 END
        """, rs -> rs.getString("role"), instructorId, offeringId);
        return role == null || role.isBlank() ? "LECTURE" : role;
    }

    private ScheduleEntry mapScheduleEntry(ResultSet rs) throws SQLException {
        ScheduleEntry e = new ScheduleEntry();
        e.setStudentId(rs.getString("student_id"));
        e.setEnrollmentId(rs.getString("enrollment_id"));
        e.setOfferingId(rs.getString("offering_id"));
        e.setCourseId(rs.getString("course_id"));
        e.setCourseName(rs.getString("course_name"));
        e.setCredits(rs.getInt("credits"));
        e.setTerm(rs.getString("term"));
        e.setAcademicYear(rs.getInt("academic_year"));
        e.setSectionCode(rs.getString("section_code"));
        e.setDayOfWeek(rs.getString("day_of_week"));
        e.setSlotId(rs.getInt("slot_id"));
        e.setMeetingType(rs.getString("meeting_type"));
        e.setStartTime(rs.getString("start_time"));
        e.setEndTime(rs.getString("end_time"));
        e.setRoomId(rs.getString("room_id"));
        e.setRoomType(rs.getString("room_type"));
        e.setInstructorIds(rs.getString("instructor_ids"));
        e.setInstructorNames(rs.getString("instructor_names"));
        e.setEnrollmentStatus(rs.getString("enrollment_status"));
        return e;
    }
}
