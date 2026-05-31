package com.university.dao;

import com.university.model.Instructor;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;

public class InstructorDAO extends BaseDAO {
    public void insertInstructor(Instructor i) {
        String departmentId = findDepartmentId(i.getDepartment());
        execute("""
            IF NOT EXISTS (SELECT 1 FROM instructors WHERE id = ?)
                INSERT INTO instructors (id, first_name, last_name, email, password, phone, department_id, title, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE')
            ELSE
                UPDATE instructors SET first_name = ?, last_name = ?, email = ?, password = ?, phone = ?, department_id = ?, title = ? WHERE id = ?
        """, i.getId(),
                i.getId(), i.getFirstName(), i.getLastName(), i.getEmail(), i.getPassword(), i.getPhone(), departmentId, i.getTitle(),
                i.getFirstName(), i.getLastName(), i.getEmail(), i.getPassword(), i.getPhone(), departmentId, i.getTitle(), i.getId());
    }

    public void deleteInstructor(String id) { execute("DELETE FROM instructors WHERE id = ?", id); }

    public Optional<Instructor> findInstructorByEmail(String email) {
        Instructor i = querySingle("SELECT * FROM vw_instructor_full WHERE LOWER(email) = LOWER(?)", this::mapInstructorFromView, email);
        return Optional.ofNullable(i);
    }

    public Instructor getInstructor(String id) {
        return querySingle("SELECT * FROM vw_instructor_full WHERE id = ?", this::mapInstructorFromView, id);
    }

    public Map<String, Instructor> getAllInstructors() {
        Map<String, Instructor> map = new LinkedHashMap<>();
        queryList("SELECT * FROM vw_instructor_full ORDER BY id", this::mapInstructorFromView).forEach(i -> map.put(i.getId(), i));
        return map;
    }

    private Instructor mapInstructorFromView(ResultSet rs) throws SQLException {
        String id = rs.getString("id");
        Instructor i = new Instructor(id, rs.getString("first_name"), rs.getString("last_name"), rs.getString("email"),
                getPasswordForUser("instructors", id), rs.getString("phone"), rs.getString("department_name"), rs.getString("title"));
        try { i.setCourseIds(csvToList(rs.getString("course_ids"))); } catch (Exception ignored) {}
        try { i.setOfferingIds(csvToList(rs.getString("offering_ids"))); } catch (Exception ignored) {}
        return i;
    }

    private List<String> csvToList(String value) {
        if (value == null || value.isBlank()) return new ArrayList<>();
        return Arrays.stream(value.split(",")).map(String::trim).filter(s -> !s.isBlank()).distinct().toList();
    }

    public String generateInstructorId() { return generateId("instructors", "id", "INS", 3); }
}
