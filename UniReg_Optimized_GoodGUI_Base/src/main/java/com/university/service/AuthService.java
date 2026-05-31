package com.university.service;

import com.university.dao.DatabaseManager;
import com.university.exception.UniversityException;
import com.university.model.Admin;
import com.university.model.Instructor;
import com.university.model.Person;
import com.university.model.Student;

import java.util.Optional;

/**
 * Authentication service.
 *
 * Keeps current user in memory and searches admins, instructors, then students.
 */
public class AuthService {
    private static AuthService instance;

    private final DatabaseManager db;
    private Person currentUser;

    private AuthService() {
        this.db = DatabaseManager.getInstance();
    }

    public static synchronized AuthService getInstance() {
        if (instance == null) {
            instance = new AuthService();
        }

        return instance;
    }

    public Person login(String email, String password) throws UniversityException {
        String cleanEmail = email == null ? "" : email.trim();
        String cleanPassword = password == null ? "" : password.trim();

        if (cleanEmail.isBlank() || cleanPassword.isBlank()) {
            throw new UniversityException("Email and password are required.");
        }

        try {
            Optional<Admin> admin = db.findAdminByEmail(cleanEmail);
            if (admin.isPresent()) {
                Admin a = admin.get();

                if (cleanPassword.equals(safe(a.getPassword()))) {
                    currentUser = a;
                    return currentUser;
                }
            }

            Optional<Instructor> instructor = db.findInstructorByEmail(cleanEmail);
            if (instructor.isPresent()) {
                Instructor i = instructor.get();

                if (cleanPassword.equals(safe(i.getPassword()))) {
                    currentUser = i;
                    return currentUser;
                }
            }

            Optional<Student> student = db.findStudentByEmail(cleanEmail);
            if (student.isPresent()) {
                Student s = student.get();

                if (cleanPassword.equals(safe(s.getPassword()))) {
                    currentUser = s;
                    return currentUser;
                }
            }
        } catch (RuntimeException ex) {
            throw new UniversityException("Database/authentication error: " + rootCauseMessage(ex), ex);
        }

        throw new UniversityException("Invalid email or password. Use one of the demo accounts shown below.");
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private String rootCauseMessage(Throwable throwable) {
        Throwable t = throwable;

        while (t.getCause() != null) {
            t = t.getCause();
        }

        String message = t.getMessage();
        return message == null || message.isBlank() ? t.getClass().getSimpleName() : message;
    }

    public void logout() {
        currentUser = null;
    }

    public void refreshCurrentUser(Person updated) {
        currentUser = updated;
    }

    public Person getCurrentUser() {
        return currentUser;
    }

    public boolean isLoggedIn() {
        return currentUser != null;
    }

    public boolean isStudent() {
        return currentUser instanceof Student;
    }

    public boolean isInstructor() {
        return currentUser instanceof Instructor;
    }

    public boolean isAdmin() {
        return currentUser instanceof Admin;
    }
}
