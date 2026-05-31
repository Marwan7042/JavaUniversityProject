package com.university.service;

import com.university.dao.DatabaseManager;

public class GradingPermissionService {
    private final DatabaseManager db = DatabaseManager.getInstance();

    public String getTeachingRole(String instructorId, String offeringId) {
        return db.getInstructorRoleForOffering(instructorId, offeringId);
    }

    public boolean canEdit(String instructorId, String offeringId, String componentCode) {
        String role = getTeachingRole(instructorId, offeringId);
        if ("LECTURE".equalsIgnoreCase(role)) {
            return componentCode.equals("W7_LEC") || componentCode.equals("W12_LEC") || componentCode.equals("FINAL");
        }
        if ("ASSISTANT".equalsIgnoreCase(role) || "LAB".equalsIgnoreCase(role)) {
            return componentCode.equals("W7_SEC") || componentCode.equals("W12_SEC") || componentCode.equals("CW");
        }
        return false;
    }

    public String permissionText(String instructorId, String offeringId) {
        String role = getTeachingRole(instructorId, offeringId);
        if ("LECTURE".equalsIgnoreCase(role)) return "Lecture role: Week 7 Lecture, Week 12 Lecture, Final Exam";
        if ("LAB".equalsIgnoreCase(role)) return "Lab role: Week 7 Section, Week 12 Section, Coursework";
        return "Assistant/Section role: Week 7 Section, Week 12 Section, Coursework";
    }
}
