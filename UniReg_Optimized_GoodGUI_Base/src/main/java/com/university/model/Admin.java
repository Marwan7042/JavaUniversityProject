package com.university.model;

public class Admin extends Person {
    private static final long serialVersionUID = 1L;

    private String adminLevel;

    public Admin() {}

    public Admin(String id, String firstName, String lastName, String email, String password, String phone, String adminLevel) {
        super(id, firstName, lastName, email, password, phone);
        this.adminLevel = adminLevel;
    }

    @Override public String getRole() { return "Admin"; }

    @Override public String getSummary() {
        return "Admin " + getFullName() + " | Level: " + adminLevel;
    }

    public boolean isSuperAdmin() { return "SUPER".equalsIgnoreCase(adminLevel); }
    public boolean isModeratorAdmin() { return "MODERATOR".equalsIgnoreCase(adminLevel); }
    public boolean isStandardAdmin() { return "STANDARD".equalsIgnoreCase(adminLevel); }

    public String getAdminLevel() { return adminLevel; }
    public void setAdminLevel(String adminLevel) { this.adminLevel = adminLevel; }
}
