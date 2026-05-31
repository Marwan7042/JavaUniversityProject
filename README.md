# Project UML

This diagram set shows the main layers of the university registration system and how they connect.

## 1) High-level architecture

```mermaid
flowchart LR
    App[App]
    Nav[NavigationManager]
    LoginScreen[LoginScreen]
    LoginController[LoginController]
    Auth[AuthService]
    Reg[RegistrationService]
    Notify[NotificationService]
    AdminPerm[AdminPermissionService]
    GradePerm[GradingPermissionService]
    DBM[DatabaseManager]
    BaseDAO[BaseDAO]
    UI[UI Layer]
    Service[Service Layer]
    DAO[DAO Layer]
    Model[Model Layer]
    DB[(SQL Server / UniversityDB)]

    App --> Nav
    App --> LoginScreen
    App --> DBM
    App --> Notify

    LoginScreen --> Auth
    LoginController --> Auth
    LoginScreen --> Nav
    LoginController --> Nav

    Auth --> DBM
    Reg --> DBM
    AdminPerm --> Auth
    GradePerm --> Auth

    DBM --> AdminDAO[AdminDAO]
    DBM --> InstructorDAO[InstructorDAO]
    DBM --> StudentDAO[StudentDAO]
    DBM --> CourseDAO[CourseDAO]
    DBM --> EnrollmentDAO[EnrollmentDAO]
    DBM --> ScheduleDAO[ScheduleDAO]
    DBM --> RegistrationPeriodDAO[RegistrationPeriodDAO]

    AdminDAO --> BaseDAO
    InstructorDAO --> BaseDAO
    StudentDAO --> BaseDAO
    CourseDAO --> BaseDAO
    EnrollmentDAO --> BaseDAO
    ScheduleDAO --> BaseDAO
    RegistrationPeriodDAO --> BaseDAO

    BaseDAO --> DB

    UI --> LoginScreen
    UI --> LoginController
    UI --> AdminDashboardScreen[AdminDashboardScreen]
    UI --> StudentDashboardScreen[StudentDashboardScreen]
    UI --> InstructorScreen[InstructorScreen]
    UI --> BaseDashboardScreen[BaseDashboardScreen]
    UI --> CourseDetailsScreen[CourseDetailsScreen]
    UI --> ChromeTab[ChromeTab]
    UI --> ChromeTabPane[ChromeTabPane]

    Service --> Auth
    Service --> Reg
    Service --> Notify
    Service --> AdminPerm
    Service --> GradePerm

    Model --> Person[Person]
    Model --> Admin[Admin]
    Model --> Instructor[Instructor]
    Model --> Student[Student]
    Model --> Course[Course]
    Model --> Enrollment[Enrollment]
    Model --> RegistrationPeriod[RegistrationPeriod]
    Model --> ScheduleEntry[ScheduleEntry]
```

## 2) Core class diagram

```mermaid
classDiagram
    direction LR

    class App {
        +start(Stage)
        +stop()
        +main(String[])
    }

    class NavigationManager {
        -Stage primaryStage
        +getInstance()
        +setPrimaryStage(Stage)
        +navigateTo(Scene, String)
    }

    class DatabaseManager {
        -instance
        -AdminDAO adminDAO
        -InstructorDAO instructorDAO
        -StudentDAO studentDAO
        -CourseDAO courseDAO
        -EnrollmentDAO enrollmentDAO
        -ScheduleDAO scheduleDAO
        -RegistrationPeriodDAO registrationPeriodDAO
        +getInstance()
        +getConnection()
        +verifySchema()
    }

    class BaseDAO {
        <<abstract>>
        #dataSource
        #execute(String, Object...)
        #queryList(String, ResultSetMapper, Object...)
        #querySingle(String, ResultSetMapper, Object...)
        #findDepartmentId(String)
        #findMajorId(String)
        #generateId(String, String, String, int)
    }

    class AuthService {
        +getInstance()
        +login(String, String)
        +logout()
        +getCurrentUser()
    }

    class RegistrationService {
        +getInstance()
        +getAvailableCourses()
        +enrollStudent(String, String)
        +dropCourse(String, String)
        +assignGrade(String, String, Grade)
    }

    class NotificationService {
        +getInstance()
        +setUiCallback(Consumer<String>)
        +sendAsync(String)
        +sendEnrollmentConfirmation(String, String)
        +sendDropConfirmation(String, String)
        +shutdown()
    }

    class AdminPermissionService {
        +hasPermission(Admin, Permission) boolean
        +describeLevel(Admin) String
    }
    class GradingPermissionService {
        +getTeachingRole(String, String) String
        +canEdit(String, String, String) boolean
        +permissionText(String, String) String
    }

    class LoginScreen {
        +build() Scene
    }
    class LoginController {
        +initialize()
    }
    class BaseDashboardScreen {
        <<abstract>>
        #buildTopBar()
        #buildSidebar()
        #buildContent()
        +build() Scene
    }
    class AdminDashboardScreen
    class StudentDashboardScreen
    class InstructorScreen
    class CourseDetailsScreen
    class ChromeTab
    class ChromeTabPane

    class Person {
        <<abstract>>
        #id
        #firstName
        #lastName
        #email
        #password
        #phone
        +getRole() String
        +getSummary() String
    }
    class Admin {
        -adminLevel
        +isSuperAdmin()
    }
    class Instructor {
        -department
        -title
        -courseIds
        -offeringIds
    }
    class Student {
        -major
        -year
        -gpa
        -enrollments
    }
    class Course {
        -courseId
        -courseName
        -department
        -credits
        -offeringId
        -term
        -academicYear
        -sectionCode
        -capacity
        -enrolled
        -status
        -instructorId
        -prerequisiteIds
        -enrolledStudentIds
    }
    class Enrollment {
        -enrollmentId
        -studentId
        -offeringId
        -courseId
        -courseName
        -credits
        -term
        -academicYear
        -status
        -grade
        -totalGrade
    }
    class RegistrationPeriod {
        -periodId
        -term
        -academicYear
        -addStartDate
        -addEndDate
        -dropEndDate
        -status
    }
    class ScheduleEntry {
        -studentId
        -enrollmentId
        -offeringId
        -courseId
        -courseName
        -credits
        -term
        -academicYear
        -dayOfWeek
        -slotId
        -meetingType
        -startTime
        -endTime
        -roomId
    }

    class AdminDAO
    class InstructorDAO
    class StudentDAO
    class CourseDAO
    class EnrollmentDAO
    class ScheduleDAO
    class RegistrationPeriodDAO

    App --> NavigationManager
    App --> DatabaseManager
    App --> LoginScreen
    App --> NotificationService

    LoginScreen --> AuthService
    LoginController --> AuthService
    LoginScreen --> NavigationManager
    LoginController --> NavigationManager

    AuthService --> DatabaseManager
    RegistrationService --> DatabaseManager
    NotificationService --> DatabaseManager
    AdminPermissionService --> AuthService
    GradingPermissionService --> AuthService

    DatabaseManager --> AdminDAO
    DatabaseManager --> InstructorDAO
    DatabaseManager --> StudentDAO
    DatabaseManager --> CourseDAO
    DatabaseManager --> EnrollmentDAO
    DatabaseManager --> ScheduleDAO
    DatabaseManager --> RegistrationPeriodDAO

    AdminDAO --|> BaseDAO
    InstructorDAO --|> BaseDAO
    StudentDAO --|> BaseDAO
    CourseDAO --|> BaseDAO
    EnrollmentDAO --|> BaseDAO
    ScheduleDAO --|> BaseDAO
    RegistrationPeriodDAO --|> BaseDAO

    AdminDashboardScreen --|> BaseDashboardScreen
    StudentDashboardScreen --|> BaseDashboardScreen
    InstructorScreen --|> BaseDashboardScreen

    Admin --|> Person
    Instructor --|> Person
    Student --|> Person

    Student "1" o-- "0..*" Enrollment
    Course "1" o-- "0..*" Enrollment
    Course "1" o-- "0..*" ScheduleEntry
    RegistrationService --> Course
    RegistrationService --> Student
    RegistrationService --> Enrollment
```

## 3) Runtime flow: startup and login

```mermaid
sequenceDiagram
    participant User
    participant App
    participant DBM as DatabaseManager
    participant Login as LoginScreen/LoginController
    participant Auth as AuthService
    participant DAO as DAO layer
    participant DB as UniversityDB
    participant Nav as NavigationManager

    User->>App: Start application
    App->>DBM: getInstance()
    DBM->>DAO: verify schema + initialize DAOs
    DAO->>DB: open connection / check tables and views
    DB-->>DBM: ready
    App->>Nav: show LoginScreen
    User->>Login: enter email/password
    Login->>Auth: login(email, password)
    Auth->>DBM: find user by email
    DBM->>DAO: findAdminByEmail / findInstructorByEmail / findStudentByEmail
    DAO->>DB: query credentials
    DB-->>Auth: matching Person or empty
    Auth-->>Login: Person or error
    Login->>Nav: route to dashboard by role
```

## 4) What each layer does

- `ui`: screens, controllers, navigation, and dashboard composition.
- `service`: business rules such as authentication, registration, grading, and permissions.
- `dao`: all SQL access and schema-specific logic.
- `model`: domain objects for people, courses, enrollments, schedules, and periods.
- `util`: reusable UI helpers, navigation, result wrappers, and table helpers.
- `dto`: lightweight report objects like `SystemStats`.
- `exception`: app-specific error types.

## 5) Reading order

1. `App`
2. `DatabaseManager`
3. `AuthService`
4. `LoginScreen` and `LoginController`
5. `BaseDashboardScreen` and the three dashboard screens
6. `RegistrationService`
7. The DAO classes
8. The model classes

This is the fastest path to understanding the project end-to-end.

## 6) Database ER diagram

```mermaid
erDiagram
    DEPARTMENTS {
        nvarchar department_id PK
        nvarchar department_name
        nvarchar description
    }

    MAJORS {
        nvarchar major_id PK
        nvarchar major_name
        nvarchar department_id FK
    }

    ADMINS {
        nvarchar id PK
        nvarchar email
        nvarchar password
        nvarchar admin_level
    }

    INSTRUCTORS {
        nvarchar id PK
        nvarchar email
        nvarchar password
        nvarchar department_id FK
        nvarchar title
        nvarchar status
    }

    STUDENTS {
        nvarchar id PK
        nvarchar email
        nvarchar password
        nvarchar major_id FK
        int year
        decimal gpa
    }

    COURSES {
        nvarchar course_id PK
        nvarchar course_name
        nvarchar department_id FK
        int credits
    }

    COURSE_OFFERINGS {
        nvarchar offering_id PK
        nvarchar course_id FK
        nvarchar term
        int academic_year
        nvarchar section_code
        int capacity
        nvarchar status
    }

    ENROLLMENTS {
        nvarchar enrollment_id PK
        nvarchar student_id FK
        nvarchar offering_id FK
        nvarchar status
        nvarchar grade
        decimal total_grade
    }

    COURSE_INSTRUCTORS {
        nvarchar offering_id FK
        nvarchar instructor_id FK
        nvarchar role
    }

    COURSE_PREREQUISITES {
        nvarchar course_id FK
        nvarchar prerequisite_id FK
    }

    ROOMS {
        nvarchar room_id PK
        nvarchar room_type
        int capacity
    }

    TIME_SLOTS {
        int slot_id PK
        time start_time
        time end_time
    }

    ROOM_SCHEDULE {
        int schedule_id PK
        nvarchar offering_id FK
        nvarchar room_id FK
        nvarchar instructor_id FK
        int slot_id FK
        nvarchar day_of_week
        nvarchar meeting_type
    }

    ASSESSMENT_COMPONENTS {
        nvarchar component_code PK
        nvarchar component_name
        int week_no
        nvarchar category
        decimal max_marks
    }

    STUDENT_ASSESSMENT_SCORES {
        int score_id PK
        nvarchar enrollment_id FK
        nvarchar component_code FK
        decimal score
    }

    REGISTRATION_PERIODS {
        int period_id PK
        nvarchar term
        int academic_year
        date add_start_date
        date add_end_date
        date drop_end_date
        nvarchar status
    }

    DEPARTMENTS ||--o{ MAJORS : contains
    DEPARTMENTS ||--o{ INSTRUCTORS : employs
    DEPARTMENTS ||--o{ COURSES : owns
    MAJORS ||--o{ STUDENTS : enrolls
    COURSES ||--o{ COURSE_OFFERINGS : offers
    COURSES ||--o{ COURSE_PREREQUISITES : requires
    INSTRUCTORS ||--o{ COURSE_INSTRUCTORS : teaches
    COURSE_OFFERINGS ||--o{ COURSE_INSTRUCTORS : staffed_by
    STUDENTS ||--o{ ENROLLMENTS : registers
    COURSE_OFFERINGS ||--o{ ENROLLMENTS : has
    COURSE_OFFERINGS ||--o{ ROOM_SCHEDULE : scheduled_as
    ROOMS ||--o{ ROOM_SCHEDULE : hosts
    TIME_SLOTS ||--o{ ROOM_SCHEDULE : timeslot
    INSTRUCTORS ||--o{ ROOM_SCHEDULE : assigned_to
    ENROLLMENTS ||--o{ STUDENT_ASSESSMENT_SCORES : earns
    ASSESSMENT_COMPONENTS ||--o{ STUDENT_ASSESSMENT_SCORES : defines
```

## 7) UI screen flow

```mermaid
flowchart TD
    Start([App start]) --> Loading[Loading screen]
    Loading --> DBCheck[DatabaseManager verifies schema]
    DBCheck --> Login[LoginScreen / LoginController]

    Login -->|Admin credentials| AdminDash[AdminDashboardScreen]
    Login -->|Instructor credentials| InstructorDash[InstructorScreen]
    Login -->|Student credentials| StudentDash[StudentDashboardScreen]

    AdminDash --> AdminFeatures[Admin management tabs]
    InstructorDash --> InstructorFeatures[Grade / course tools]
    StudentDash --> StudentFeatures[Course search / registration / schedule]

    AdminFeatures --> CourseDetails[CourseDetailsScreen]
    InstructorFeatures --> CourseDetails
    StudentFeatures --> CourseDetails

    AdminDash -->|Logout| Login
    InstructorDash -->|Logout| Login
    StudentDash -->|Logout| Login

    AdminDash --> Shell[BaseDashboardScreen]
    InstructorDash --> Shell
    StudentDash --> Shell
    Shell --> Tabs[ChromeTab / ChromeTabPane]
```
