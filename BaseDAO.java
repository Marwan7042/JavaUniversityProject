classDiagram
    direction LR

    class BaseDAO {
        <<abstract>>
        #dataSource HikariDataSource
        #execute(String, Object...)
        #queryList(String, ResultSetMapper, Object...)
        #querySingle(String, ResultSetMapper, Object...)
        #bind(PreparedStatement, Object...)
        #buildPlaceholders(int) String
        #getPasswordForUser(String, String) String
        #getPasswordsForUsers(String, Collection~String~) Map~String,String~
        #findDepartmentId(String) String
        #findMajorId(String) String
        #generateId(String, String, String, int) String
        #safeTerm(String) String
        #safeYear(int) int
        #safeSection(String) String
        #safeStatus(String) String
    }

    class DatabaseManager {
        -instance DatabaseManager
        -adminDAO AdminDAO
        -instructorDAO InstructorDAO
        -studentDAO StudentDAO
        -courseDAO CourseDAO
        -enrollmentDAO EnrollmentDAO
        -scheduleDAO ScheduleDAO
        -registrationPeriodDAO RegistrationPeriodDAO
        -DatabaseManager()
        +getInstance() DatabaseManager
        +getConnection() Connection
        -verifySchema()
        +insertAdmin(Admin)
        +deleteAdmin(String)
        +generateAdminId() String
        +findAdminByEmail(String) Optional~Admin~
        +getAllAdmins() Map~String,Admin~
        +insertInstructor(Instructor)
        +deleteInstructor(String)
        +findInstructorByEmail(String) Optional~Instructor~
        +getAllInstructors() Map~String,Instructor~
        +getInstructor(String) Instructor
        +generateInstructorId() String
        +insertStudent(Student)
        +updateStudentGpa(String, double)
        +deleteStudent(String)
        +findStudentByEmail(String) Optional~Student~
        +getStudent(String) Student
        +getAllStudents() Map~String,Student~
        +generateStudentId() String
        +getStudentsInCourse(String) List~Student~
        +insertCourse(Course)
        +deleteCourse(String)
        +getCourse(String) Course
        +getAllCourses() Map~String,Course~
        +generateOfferingId() String
        +insertEnrollment(Enrollment)
        +updateEnrollment(Enrollment)
        +getEnrollmentsForStudent(String) List~Enrollment~
        +getEnrollment(String) Enrollment
        +getEnrollmentForStudentAndCourse(String, String) Enrollment
        +generateEnrollmentId() String
        +isAddPeriodOpen(String) boolean
        +isDropPeriodOpen(String) boolean
        +hasStudentTimeConflict(String, String) boolean
        +getActiveCredits(String) int
        +setAssessmentScore(String, String, double)
        +assignTotalGradeProportionally(String, double)
        +getAssessmentMaxMarks() Map~String,Double~
        +getAllRegistrationPeriods() List~RegistrationPeriod~
        +saveRegistrationPeriod(RegistrationPeriod)
        +deleteRegistrationPeriod(int)
        +getStudentSchedule(String) List~ScheduleEntry~
        +getInstructorSchedule(String) List~ScheduleEntry~
        +getInstructorRoleForOffering(String, String) String
    }

    DatabaseManager --> BaseDAO