package com.university.model;

import java.time.LocalDate;

public class RegistrationPeriod {
    private int periodId;
    private String term = "TERM1";
    private int academicYear = 2026;
    private LocalDate addStartDate = LocalDate.now();
    private LocalDate addEndDate = LocalDate.now().plusDays(14);
    private LocalDate dropEndDate = LocalDate.now().plusDays(21);
    private String status = "OPEN";

    public RegistrationPeriod() {}

    public RegistrationPeriod(int periodId, String term, int academicYear,
                              LocalDate addStartDate, LocalDate addEndDate,
                              LocalDate dropEndDate, String status) {
        this.periodId = periodId;
        this.term = term;
        this.academicYear = academicYear;
        this.addStartDate = addStartDate;
        this.addEndDate = addEndDate;
        this.dropEndDate = dropEndDate;
        this.status = status;
    }

    public boolean isOpen() {
        return "OPEN".equalsIgnoreCase(status);
    }

    public int getPeriodId() { return periodId; }
    public void setPeriodId(int periodId) { this.periodId = periodId; }
    public String getTerm() { return term; }
    public void setTerm(String term) { this.term = term; }
    public int getAcademicYear() { return academicYear; }
    public void setAcademicYear(int academicYear) { this.academicYear = academicYear; }
    public LocalDate getAddStartDate() { return addStartDate; }
    public void setAddStartDate(LocalDate addStartDate) { this.addStartDate = addStartDate; }
    public LocalDate getAddEndDate() { return addEndDate; }
    public void setAddEndDate(LocalDate addEndDate) { this.addEndDate = addEndDate; }
    public LocalDate getDropEndDate() { return dropEndDate; }
    public void setDropEndDate(LocalDate dropEndDate) { this.dropEndDate = dropEndDate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
