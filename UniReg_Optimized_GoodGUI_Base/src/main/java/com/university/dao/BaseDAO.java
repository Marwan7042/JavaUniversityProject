package com.university.dao;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.*;

public abstract class BaseDAO {
    private static final Logger log = LoggerFactory.getLogger(BaseDAO.class);
    protected static final HikariDataSource dataSource;

    static {
        String server = System.getenv().getOrDefault("UNIVERSITY_DB_SERVER", "localhost");
        String database = System.getenv().getOrDefault("UNIVERSITY_DB_NAME", "UniversityDB");
        String user = System.getenv().getOrDefault("UNIVERSITY_DB_USER", "university_user");
        String password = System.getenv().getOrDefault("UNIVERSITY_DB_PASSWORD", "UniPass123!");

        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:sqlserver://" + server + ";databaseName=" + database + ";encrypt=true;trustServerCertificate=true;");
        config.setUsername(user);
        config.setPassword(password);
        config.setDriverClassName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(2);
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        dataSource = new HikariDataSource(config);
    }

    @FunctionalInterface
    protected interface ResultSetMapper<T> { T map(ResultSet rs) throws SQLException; }

    protected void execute(String sql, Object... params) {
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            bind(ps, params);
            ps.executeUpdate();
        } catch (SQLException e) {
            log.error("Execution error: {}", e.getMessage(), e);
            throw new RuntimeException(e);
        }
    }

    protected <T> List<T> queryList(String sql, ResultSetMapper<T> mapper, Object... params) {
        List<T> list = new ArrayList<>();
        try (Connection conn = dataSource.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            bind(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapper.map(rs));
            }
        } catch (SQLException e) {
            log.error("Query error: {}", e.getMessage(), e);
            throw new RuntimeException(e);
        }
        return list;
    }

    protected <T> T querySingle(String sql, ResultSetMapper<T> mapper, Object... params) {
        List<T> results = queryList(sql, mapper, params);
        return results.isEmpty() ? null : results.get(0);
    }

    protected void bind(PreparedStatement ps, Object... params) throws SQLException {
        for (int i = 0; i < params.length; i++) {
            Object p = params[i];
            if (p == null) ps.setNull(i + 1, Types.NULL);
            else if (p instanceof String s) ps.setString(i + 1, s);
            else if (p instanceof Integer v) ps.setInt(i + 1, v);
            else if (p instanceof Double v) ps.setDouble(i + 1, v);
            else if (p instanceof Boolean b) ps.setBoolean(i + 1, b);
            else if (p instanceof java.sql.Date d) ps.setDate(i + 1, d);
            else ps.setObject(i + 1, p);
        }
    }

    protected String buildPlaceholders(int count) {
        return count <= 0 ? "" : String.join(",", Collections.nCopies(count, "?"));
    }

    protected String getPasswordForUser(String tableName, String id) {
        String sql = "SELECT password FROM " + tableName + " WHERE id = ?";
        String pass = querySingle(sql, rs -> rs.getString("password"), id);
        return pass != null ? pass : "";
    }

    protected Map<String, String> getPasswordsForUsers(String tableName, Collection<String> ids) {
        Map<String, String> map = new HashMap<>();
        if (ids == null || ids.isEmpty()) return map;
        List<String> idList = new ArrayList<>(new LinkedHashSet<>(ids));
        String sql = "SELECT id, password FROM " + tableName + " WHERE id IN (" + buildPlaceholders(idList.size()) + ")";
        queryList(sql, rs -> { map.put(rs.getString("id"), rs.getString("password")); return null; }, idList.toArray());
        return map;
    }

    protected String findDepartmentId(String departmentNameOrId) {
        if (departmentNameOrId == null || departmentNameOrId.isBlank()) return "DCS";
        String id = querySingle("""
            SELECT TOP 1 department_id
            FROM departments
            WHERE department_id = ? OR LOWER(department_name) = LOWER(?)
        """, rs -> rs.getString("department_id"), departmentNameOrId, departmentNameOrId);
        return id != null ? id : "DCS";
    }

    protected String findMajorId(String majorNameOrId) {
        if (majorNameOrId == null || majorNameOrId.isBlank()) return "MCS";
        String id = querySingle("""
            SELECT TOP 1 major_id
            FROM majors
            WHERE major_id = ? OR LOWER(major_name) = LOWER(?)
        """, rs -> rs.getString("major_id"), majorNameOrId, majorNameOrId);
        return id != null ? id : "MCS";
    }

    protected String generateId(String tableName, String columnName, String prefix, int digits) {
        String lastId = querySingle(
                "SELECT TOP 1 " + columnName + " FROM " + tableName + " WHERE " + columnName + " LIKE ? ORDER BY " + columnName + " DESC",
                rs -> rs.getString(columnName), prefix + "%");
        if (lastId != null) {
            try {
                int num = Integer.parseInt(lastId.substring(prefix.length()));
                return prefix + String.format("%0" + digits + "d", num + 1);
            } catch (Exception ignored) {}
        }
        return prefix + String.format("%0" + digits + "d", 1);
    }

    protected String safeTerm(String term) {
        if (term == null || term.isBlank()) return "TERM1";
        String t = term.trim().toUpperCase();
        if (!t.equals("TERM1") && !t.equals("TERM2") && !t.equals("SUMMER")) return "TERM1";
        return t;
    }

    protected int safeYear(int year) { return year <= 0 ? 2026 : year; }
    protected String safeSection(String section) { return section == null || section.isBlank() ? "L01" : section.trim().toUpperCase(); }
    protected String safeStatus(String status) { return status == null || status.isBlank() ? "OPEN" : status.trim().toUpperCase(); }
}
