package com.university.dao;

import com.university.model.RegistrationPeriod;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

public class RegistrationPeriodDAO extends BaseDAO {

    public List<RegistrationPeriod> getAllRegistrationPeriods() {
        return queryList("""
            SELECT period_id, term, academic_year, add_start_date, add_end_date, drop_end_date, status
            FROM registration_periods
            ORDER BY academic_year DESC,
                     CASE term WHEN 'TERM1' THEN 1 WHEN 'TERM2' THEN 2 WHEN 'SUMMER' THEN 3 ELSE 4 END
        """, this::mapPeriod);
    }

    public void saveRegistrationPeriod(RegistrationPeriod p) {
        if (p == null) return;

        String term = safeTerm(p.getTerm());
        int year = safeYear(p.getAcademicYear());
        String status = safePeriodStatus(p.getStatus());

        if (p.getPeriodId() > 0) {
            execute("""
                UPDATE registration_periods
                SET term = ?, academic_year = ?, add_start_date = ?, add_end_date = ?, drop_end_date = ?, status = ?
                WHERE period_id = ?
            """,
                    term,
                    year,
                    Date.valueOf(p.getAddStartDate()),
                    Date.valueOf(p.getAddEndDate()),
                    Date.valueOf(p.getDropEndDate()),
                    status,
                    p.getPeriodId()
            );
        } else {
            execute("""
                IF NOT EXISTS (SELECT 1 FROM registration_periods WHERE term = ? AND academic_year = ?)
                    INSERT INTO registration_periods (term, academic_year, add_start_date, add_end_date, drop_end_date, status)
                    VALUES (?, ?, ?, ?, ?, ?)
                ELSE
                    UPDATE registration_periods
                    SET add_start_date = ?, add_end_date = ?, drop_end_date = ?, status = ?
                    WHERE term = ? AND academic_year = ?
            """,
                    term, year,
                    term, year, Date.valueOf(p.getAddStartDate()), Date.valueOf(p.getAddEndDate()), Date.valueOf(p.getDropEndDate()), status,
                    Date.valueOf(p.getAddStartDate()), Date.valueOf(p.getAddEndDate()), Date.valueOf(p.getDropEndDate()), status, term, year
            );
        }
    }

    public void deleteRegistrationPeriod(int periodId) {
        execute("DELETE FROM registration_periods WHERE period_id = ?", periodId);
    }

    private RegistrationPeriod mapPeriod(ResultSet rs) throws SQLException {
        Date addStart = rs.getDate("add_start_date");
        Date addEnd = rs.getDate("add_end_date");
        Date dropEnd = rs.getDate("drop_end_date");

        return new RegistrationPeriod(
                rs.getInt("period_id"),
                rs.getString("term"),
                rs.getInt("academic_year"),
                addStart == null ? null : addStart.toLocalDate(),
                addEnd == null ? null : addEnd.toLocalDate(),
                dropEnd == null ? null : dropEnd.toLocalDate(),
                rs.getString("status")
        );
    }

    private String safePeriodStatus(String value) {
        if (value == null || value.isBlank()) return "OPEN";
        String v = value.trim().toUpperCase();
        return v.equals("OPEN") || v.equals("CLOSED") ? v : "OPEN";
    }
}
