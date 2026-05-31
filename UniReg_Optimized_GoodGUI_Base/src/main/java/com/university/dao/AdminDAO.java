package com.university.dao;

import com.university.model.Admin;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

public class AdminDAO extends BaseDAO {

    public void insertAdmin(Admin a) {
        execute("""
            IF NOT EXISTS (SELECT 1 FROM admins WHERE id = ?)
                INSERT INTO admins (id, first_name, last_name, email, password, admin_level)
                VALUES (?, ?, ?, ?, ?, ?)
            ELSE
                UPDATE admins
                SET first_name = ?, last_name = ?, email = ?, password = ?, admin_level = ?
                WHERE id = ?
        """, a.getId(),
                a.getId(), a.getFirstName(), a.getLastName(), a.getEmail(), a.getPassword(), safeAdminLevel(a.getAdminLevel()),
                a.getFirstName(), a.getLastName(), a.getEmail(), a.getPassword(), safeAdminLevel(a.getAdminLevel()), a.getId());
    }

    public Optional<Admin> findAdminByEmail(String email) {
        Admin a = querySingle("SELECT * FROM admins WHERE LOWER(email) = LOWER(?)", this::mapAdmin, email);
        return Optional.ofNullable(a);
    }

    public Map<String, Admin> getAllAdmins() {
        Map<String, Admin> map = new LinkedHashMap<>();
        queryList("SELECT * FROM admins ORDER BY id", this::mapAdmin).forEach(a -> map.put(a.getId(), a));
        return map;
    }

    public void deleteAdmin(String id) {
        execute("DELETE FROM admins WHERE id = ?", id);
    }

    public String generateAdminId() {
        return generateId("admins", "id", "ADM", 3);
    }

    private Admin mapAdmin(ResultSet rs) throws SQLException {
        return new Admin(
                rs.getString("id"),
                rs.getString("first_name"),
                rs.getString("last_name"),
                rs.getString("email"),
                rs.getString("password"),
                "",
                rs.getString("admin_level")
        );
    }

    private String safeAdminLevel(String value) {
        if (value == null || value.isBlank()) return "STANDARD";

        String v = value.trim().toUpperCase();
        return switch (v) {
            case "SUPER", "MODERATOR", "STANDARD" -> v;
            default -> "STANDARD";
        };
    }
}
