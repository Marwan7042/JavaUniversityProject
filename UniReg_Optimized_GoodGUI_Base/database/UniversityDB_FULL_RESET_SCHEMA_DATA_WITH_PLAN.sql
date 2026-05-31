/* ============================================================
   University Registration System - FULL DATABASE RESET SCRIPT

   What this file does:
   1. Drops UniversityDB if it already exists.
   2. Creates UniversityDB again.
   3. Creates the full schema.
   4. Inserts realistic dummy/demo data.
   5. Adds course_academic_plan for Major + Year + Term course filtering.
   6. Normalizes offering status to OPEN/CLOSED.
   7. Creates the SQL login used by the Java app.

   WARNING:
   This script DELETES the existing UniversityDB completely.

   Recommended run order:
   Just run this one file in SSMS.

   Java default DB credentials:
   Server:   localhost
   Database: UniversityDB
   User:     university_user
   Password: UniPass123!
   ============================================================ */
GO



/* ===================== PART 1: SCHEMA ===================== */

USE [master]
GO

-- ============================================================
-- DROP AND RECREATE DATABASE
-- Compatible with SQL Server 2022 / SQL Express
-- ============================================================
IF DB_ID(N'UniversityDB') IS NOT NULL
BEGIN
    ALTER DATABASE [UniversityDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [UniversityDB];
END
GO

CREATE DATABASE [UniversityDB];
GO

ALTER DATABASE [UniversityDB] SET COMPATIBILITY_LEVEL = 160;
GO

ALTER DATABASE [UniversityDB] SET RECOVERY SIMPLE;
GO

ALTER DATABASE [UniversityDB] SET QUERY_STORE = OFF;
GO

ALTER DATABASE [UniversityDB] SET MULTI_USER;
GO

USE [UniversityDB]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================
-- TABLE: departments
-- ============================================================
CREATE TABLE [dbo].[departments] (
    [department_id]   [nvarchar](10)  NOT NULL,
    [department_name] [nvarchar](100) NOT NULL,
    [description]     [nvarchar](500) NULL,
    [created_at]      [datetime2](7)  NULL CONSTRAINT [DF_departments_created_at] DEFAULT (GETDATE()),

    CONSTRAINT [PK_departments] PRIMARY KEY CLUSTERED ([department_id] ASC)
)
GO

-- ============================================================
-- TABLE: majors
-- ============================================================
CREATE TABLE [dbo].[majors] (
    [major_id]      [nvarchar](10)  NOT NULL,
    [major_name]    [nvarchar](100) NOT NULL,
    [department_id] [nvarchar](10)  NOT NULL,
    [total_credits] [int]           NULL CONSTRAINT [DF_majors_total_credits] DEFAULT (120),
    [created_at]    [datetime2](7)  NULL CONSTRAINT [DF_majors_created_at]    DEFAULT (GETDATE()),

    CONSTRAINT [PK_majors]             PRIMARY KEY CLUSTERED ([major_id] ASC),
    CONSTRAINT [FK_majors_departments] FOREIGN KEY ([department_id])
        REFERENCES [dbo].[departments] ([department_id])
)
GO

-- ============================================================
-- TABLE: rooms
-- ============================================================
CREATE TABLE [dbo].[rooms] (
    [room_id]   [nvarchar](20) NOT NULL,
    [building]  [nvarchar](50) NULL,
    [capacity]  [int]          NULL,
    [room_type] [nvarchar](20) NULL CONSTRAINT [DF_rooms_room_type] DEFAULT ('LECTURE'),

    CONSTRAINT [PK_rooms]          PRIMARY KEY CLUSTERED ([room_id] ASC),
    CONSTRAINT [CK_rooms_capacity] CHECK ([capacity] IS NULL OR [capacity] > 0),
    CONSTRAINT [CK_rooms_room_type] CHECK ([room_type] IN ('LECTURE', 'LAB', 'SEMINAR', 'AUDITORIUM'))
)
GO

-- ============================================================
-- TABLE: time_slots
-- 4 slots only: 08:30-10:10, 10:30-12:10, 12:30-14:10, 14:30-16:10
-- ============================================================
CREATE TABLE [dbo].[time_slots] (
    [slot_id]    [int]     NOT NULL,
    [start_time] [time](7) NOT NULL,
    [end_time]   [time](7) NOT NULL,

    CONSTRAINT [PK_time_slots] PRIMARY KEY CLUSTERED ([slot_id] ASC),
    CONSTRAINT [CK_time_slots_time_order] CHECK ([start_time] < [end_time])
)
GO

-- ============================================================
-- TABLE: registration_periods
-- Controls when students can add/drop courses per term/year.
-- ============================================================
CREATE TABLE [dbo].[registration_periods] (
    [period_id]      [int] IDENTITY(1,1) NOT NULL,
    [term]           [nvarchar](20) NOT NULL,
    [academic_year]  [int] NOT NULL,
    [add_start_date] [date] NOT NULL,
    [add_end_date]   [date] NOT NULL,
    [drop_end_date]  [date] NOT NULL,
    [status]         [nvarchar](20) NOT NULL CONSTRAINT [DF_registration_periods_status] DEFAULT ('OPEN'),
    [created_at]     [datetime2](7) NULL CONSTRAINT [DF_registration_periods_created_at] DEFAULT (GETDATE()),

    CONSTRAINT [PK_registration_periods] PRIMARY KEY CLUSTERED ([period_id] ASC),
    CONSTRAINT [UQ_registration_period_term_year] UNIQUE ([term], [academic_year]),
    CONSTRAINT [CK_registration_period_term] CHECK ([term] IN ('TERM1', 'TERM2', 'SUMMER')),
    CONSTRAINT [CK_registration_period_year] CHECK ([academic_year] BETWEEN 2000 AND 2100),
    CONSTRAINT [CK_registration_period_status] CHECK ([status] IN ('OPEN', 'CLOSED')),
    CONSTRAINT [CK_registration_period_dates] CHECK (
        [add_start_date] <= [add_end_date]
        AND [add_end_date] <= [drop_end_date]
    )
)
GO

-- ============================================================
-- TABLE: admins
-- ============================================================
CREATE TABLE [dbo].[admins] (
    [id]          [nvarchar](20)  NOT NULL,
    [first_name]  [nvarchar](50)  NOT NULL,
    [last_name]   [nvarchar](50)  NOT NULL,
    [email]       [nvarchar](100) NOT NULL,
    [password]    [nvarchar](255) NOT NULL,
    [admin_level] [nvarchar](20)  NULL CONSTRAINT [DF_admins_admin_level] DEFAULT ('STANDARD'),
    [created_at]  [datetime2](7)  NULL CONSTRAINT [DF_admins_created_at]  DEFAULT (GETDATE()),

    CONSTRAINT [PK_admins]       PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UQ_admins_email] UNIQUE ([email]),
    CONSTRAINT [CK_admins_level] CHECK ([admin_level] IN ('STANDARD', 'MODERATOR', 'SUPER'))
)
GO

-- ============================================================
-- TABLE: instructors
-- ============================================================
CREATE TABLE [dbo].[instructors] (
    [id]            [nvarchar](20)  NOT NULL,
    [first_name]    [nvarchar](50)  NOT NULL,
    [last_name]     [nvarchar](50)  NOT NULL,
    [email]         [nvarchar](100) NOT NULL,
    [password]      [nvarchar](255) NOT NULL,
    [phone]         [nvarchar](20)  NULL,
    [department_id] [nvarchar](10)  NULL,
    [title]         [nvarchar](50)  NULL,
    [status]        [nvarchar](20)  NULL CONSTRAINT [DF_instructors_status]     DEFAULT ('ACTIVE'),
    [created_at]    [datetime2](7)  NULL CONSTRAINT [DF_instructors_created_at] DEFAULT (GETDATE()),

    CONSTRAINT [PK_instructors]             PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UQ_instructors_email]       UNIQUE ([email]),
    CONSTRAINT [FK_instructors_departments] FOREIGN KEY ([department_id])
        REFERENCES [dbo].[departments] ([department_id]),
    CONSTRAINT [CK_instructors_title] CHECK ([title] IN (
        'Teaching Assistant',
        'Lecturer',
        'Assistant Professor',
        'Associate Professor',
        'Professor'
    )),
    CONSTRAINT [CK_instructors_status] CHECK ([status] IN ('ACTIVE', 'INACTIVE', 'ON_LEAVE'))
)
GO

-- ============================================================
-- TABLE: students
-- ============================================================
CREATE TABLE [dbo].[students] (
    [id]             [nvarchar](20)  NOT NULL,
    [first_name]     [nvarchar](50)  NOT NULL,
    [last_name]      [nvarchar](50)  NOT NULL,
    [email]          [nvarchar](100) NOT NULL,
    [personal_email] [nvarchar](100) NULL,
    [password]       [nvarchar](255) NOT NULL,
    [phone]          [nvarchar](20)  NULL,
    [major_id]       [nvarchar](10)  NULL,
    [year]           [int]           NULL CONSTRAINT [DF_students_year]       DEFAULT (1),
    [status]         [nvarchar](20)  NULL CONSTRAINT [DF_students_status]     DEFAULT ('ACTIVE'),
    [created_at]     [datetime2](7)  NULL CONSTRAINT [DF_students_created_at] DEFAULT (GETDATE()),

    CONSTRAINT [PK_students]        PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UQ_students_email]  UNIQUE ([email]),
    CONSTRAINT [FK_students_majors] FOREIGN KEY ([major_id])
        REFERENCES [dbo].[majors] ([major_id]),
    CONSTRAINT [CK_students_year]   CHECK ([year] BETWEEN 1 AND 5),
    CONSTRAINT [CK_students_status] CHECK ([status] IN (
        'ACTIVE', 'INACTIVE', 'GRADUATED', 'SUSPENDED'
    ))
)
GO

CREATE UNIQUE INDEX [UQ_students_personal_email]
ON [dbo].[students] ([personal_email])
WHERE [personal_email] IS NOT NULL
GO

-- ============================================================
-- TABLE: courses
-- Course catalog only.
-- The same course can have many offerings in different terms/years.
-- ============================================================
CREATE TABLE [dbo].[courses] (
    [course_id]     [nvarchar](20)  NOT NULL,
    [course_name]   [nvarchar](150) NOT NULL,
    [description]   [nvarchar](500) NULL,
    [department_id] [nvarchar](10)  NOT NULL,
    [credits]       [int]           NULL CONSTRAINT [DF_courses_credits] DEFAULT (3),
    [created_at]    [datetime2](7)  NULL CONSTRAINT [DF_courses_created_at] DEFAULT (GETDATE()),

    CONSTRAINT [PK_courses]             PRIMARY KEY CLUSTERED ([course_id] ASC),
    CONSTRAINT [FK_courses_departments] FOREIGN KEY ([department_id])
        REFERENCES [dbo].[departments] ([department_id]),
    CONSTRAINT [CK_courses_credits] CHECK ([credits] BETWEEN 1 AND 6)
)
GO

-- ============================================================
-- TABLE: course_offerings
-- A specific offering/section of a course in a specific term/year.
-- Example: OFF001 = CS101 offered in FALL 2025.
-- ============================================================
CREATE TABLE [dbo].[course_offerings] (
    [offering_id]   [nvarchar](20) NOT NULL,
    [course_id]     [nvarchar](20) NOT NULL,
    [term]          [nvarchar](20) NOT NULL,
    [academic_year] [int]          NOT NULL,
    [section_code]  [nvarchar](20) NOT NULL CONSTRAINT [DF_course_offerings_section] DEFAULT ('L01'),
    [capacity]      [int]          NOT NULL CONSTRAINT [DF_course_offerings_capacity] DEFAULT (30),
    [status]        [nvarchar](20) NOT NULL CONSTRAINT [DF_course_offerings_status] DEFAULT ('OPEN'),
    [created_at]    [datetime2](7) NULL CONSTRAINT [DF_course_offerings_created_at] DEFAULT (GETDATE()),

    CONSTRAINT [PK_course_offerings] PRIMARY KEY CLUSTERED ([offering_id] ASC),

    CONSTRAINT [UQ_course_offering_section]
        UNIQUE ([course_id], [term], [academic_year], [section_code]),

    CONSTRAINT [FK_course_offerings_courses]
        FOREIGN KEY ([course_id])
        REFERENCES [dbo].[courses] ([course_id])
        ON DELETE CASCADE,

    CONSTRAINT [FK_course_offerings_registration_period]
        FOREIGN KEY ([term], [academic_year])
        REFERENCES [dbo].[registration_periods] ([term], [academic_year]),

    CONSTRAINT [CK_course_offerings_term]
        CHECK ([term] IN ('TERM1', 'TERM2', 'SUMMER')),

    CONSTRAINT [CK_course_offerings_year]
        CHECK ([academic_year] BETWEEN 2000 AND 2100),

    CONSTRAINT [CK_course_offerings_capacity]
        CHECK ([capacity] BETWEEN 1 AND 500),

    CONSTRAINT [CK_course_offerings_status]
        CHECK ([status] IN ('OPEN', 'CLOSED', 'CANCELLED', 'COMPLETED'))
)
GO

-- ============================================================
-- TABLE: course_prerequisites
-- Prerequisites are attached to the course catalog, not to one offering.
-- ============================================================
CREATE TABLE [dbo].[course_prerequisites] (
    [course_id]       [nvarchar](20) NOT NULL,
    [prerequisite_id] [nvarchar](20) NOT NULL,

    CONSTRAINT [PK_course_prerequisites] PRIMARY KEY CLUSTERED ([course_id] ASC, [prerequisite_id] ASC),
    CONSTRAINT [FK_cp_course]            FOREIGN KEY ([course_id])
        REFERENCES [dbo].[courses] ([course_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_cp_prereq]            FOREIGN KEY ([prerequisite_id])
        REFERENCES [dbo].[courses] ([course_id]),
    CONSTRAINT [CK_cp_no_self_reference] CHECK ([course_id] <> [prerequisite_id])
)
GO

-- ============================================================
-- TABLE: course_instructors
-- Instructor assignment is attached to an offering, not the generic course.
-- ============================================================
CREATE TABLE [dbo].[course_instructors] (
    [offering_id]   [nvarchar](20) NOT NULL,
    [instructor_id] [nvarchar](20) NOT NULL,
    [role]          [nvarchar](20) NULL CONSTRAINT [DF_course_instructors_role] DEFAULT ('LECTURE'),

    CONSTRAINT [PK_course_instructors] PRIMARY KEY CLUSTERED ([offering_id] ASC, [instructor_id] ASC),
    CONSTRAINT [FK_ci_offering]         FOREIGN KEY ([offering_id])
        REFERENCES [dbo].[course_offerings] ([offering_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ci_instructor]       FOREIGN KEY ([instructor_id])
        REFERENCES [dbo].[instructors] ([id]) ON DELETE CASCADE,
    CONSTRAINT [CK_ci_role]             CHECK ([role] IN ('LECTURE', 'LAB', 'SEMINAR', 'ASSISTANT'))
)
GO

-- ============================================================
-- TABLE: room_schedule
-- Schedule is attached to the offering.
-- Conflict checks are handled by trigger because term/year is stored in course_offerings.
-- ============================================================
CREATE TABLE [dbo].[room_schedule] (
    [schedule_id]   [int] IDENTITY(1,1) NOT NULL,
    [offering_id]   [nvarchar](20) NOT NULL,
    [room_id]       [nvarchar](20) NOT NULL,
    [instructor_id] [nvarchar](20) NULL,
    [day_of_week]   [nvarchar](20) NOT NULL,
    [slot_id]       [int]          NOT NULL,
    [meeting_type]  [nvarchar](20) NOT NULL CONSTRAINT [DF_room_schedule_meeting_type] DEFAULT ('LECTURE'),

    CONSTRAINT [PK_room_schedule] PRIMARY KEY CLUSTERED ([schedule_id] ASC),

    CONSTRAINT [UQ_offering_schedule]
        UNIQUE ([offering_id], [day_of_week], [slot_id]),

    CONSTRAINT [FK_rs_offering] FOREIGN KEY ([offering_id])
        REFERENCES [dbo].[course_offerings] ([offering_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_rs_room] FOREIGN KEY ([room_id])
        REFERENCES [dbo].[rooms] ([room_id]),
    CONSTRAINT [FK_rs_instructor] FOREIGN KEY ([instructor_id])
        REFERENCES [dbo].[instructors] ([id]),
    CONSTRAINT [FK_rs_slot] FOREIGN KEY ([slot_id])
        REFERENCES [dbo].[time_slots] ([slot_id]),
    CONSTRAINT [CK_rs_day] CHECK ([day_of_week] IN (
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    )),
    CONSTRAINT [CK_room_schedule_meeting_type] CHECK ([meeting_type] IN ('LECTURE', 'SECTION', 'LAB'))
)
GO

-- ============================================================
-- TRIGGER: Prevent room/instructor conflicts in the same term/year
-- Allows the same room/time in different terms.
-- ============================================================
CREATE TRIGGER [dbo].[TR_room_schedule_no_conflicts]
ON [dbo].[room_schedule]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[course_offerings] oi
            ON i.offering_id = oi.offering_id
        JOIN [dbo].[room_schedule] rs
            ON rs.schedule_id <> i.schedule_id
           AND rs.room_id = i.room_id
           AND rs.day_of_week = i.day_of_week
           AND rs.slot_id = i.slot_id
        JOIN [dbo].[course_offerings] ors
            ON rs.offering_id = ors.offering_id
           AND ors.term = oi.term
           AND ors.academic_year = oi.academic_year
    )
    BEGIN
        THROW 50001, 'Room schedule conflict: this room is already used at the same day/time in the same term/year.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[course_offerings] oi
            ON i.offering_id = oi.offering_id
        JOIN [dbo].[room_schedule] rs
            ON rs.schedule_id <> i.schedule_id
           AND rs.instructor_id = i.instructor_id
           AND rs.day_of_week = i.day_of_week
           AND rs.slot_id = i.slot_id
        JOIN [dbo].[course_offerings] ors
            ON rs.offering_id = ors.offering_id
           AND ors.term = oi.term
           AND ors.academic_year = oi.academic_year
        WHERE i.instructor_id IS NOT NULL
    )
    BEGIN
        THROW 50002, 'Instructor schedule conflict: this instructor already teaches at the same day/time in the same term/year.', 1;
    END;
END
GO

-- ============================================================
-- TABLE: enrollments
-- Enrollments point to course_offerings, not directly to courses.
-- ============================================================
CREATE TABLE [dbo].[enrollments] (
    [enrollment_id]   [nvarchar](50) NOT NULL CONSTRAINT [DF_enrollments_id] DEFAULT (CONVERT([nvarchar](50), NEWID())),
    [student_id]      [nvarchar](20) NOT NULL,
    [offering_id]     [nvarchar](20) NOT NULL,
    [enrollment_date] [datetime2](7) NULL CONSTRAINT [DF_enrollments_date] DEFAULT (GETDATE()),
    [status]          [nvarchar](20) NULL CONSTRAINT [DF_enrollments_status] DEFAULT ('ENROLLED'),

    CONSTRAINT [PK_enrollments] PRIMARY KEY CLUSTERED ([enrollment_id] ASC),

    CONSTRAINT [UQ_enrollment_student_offering]
        UNIQUE ([student_id], [offering_id]),

    CONSTRAINT [FK_enr_student] FOREIGN KEY ([student_id])
        REFERENCES [dbo].[students] ([id]) ON DELETE CASCADE,
    CONSTRAINT [FK_enr_offering] FOREIGN KEY ([offering_id])
        REFERENCES [dbo].[course_offerings] ([offering_id]) ON DELETE CASCADE,

    CONSTRAINT [CK_enrollments_status] CHECK ([status] IN (
        'ENROLLED', 'COMPLETED', 'WITHDRAWN', 'INCOMPLETE'
    ))
)
GO

-- ============================================================
-- TABLE: assessment_components
-- AASTMT-style grade structure:
-- W7 Lecture 20 + W7 Section 10 + W12 Lecture 15 + W12 Section 5
-- + Coursework 10 + Final 40 = 100
-- ============================================================
CREATE TABLE [dbo].[assessment_components] (
    [component_id]   [int] IDENTITY(1,1) NOT NULL,
    [component_code] [nvarchar](30)  NOT NULL,
    [component_name] [nvarchar](100) NOT NULL,
    [week_no]        [int]           NULL,
    [category]       [nvarchar](30)  NOT NULL,
    [max_marks]      [decimal](5,2)  NOT NULL,
    [display_order]  [int]           NOT NULL,

    CONSTRAINT [PK_assessment_components] PRIMARY KEY CLUSTERED ([component_id] ASC),
    CONSTRAINT [UQ_assessment_components_code] UNIQUE ([component_code]),
    CONSTRAINT [CK_assessment_components_week] CHECK ([week_no] IS NULL OR [week_no] BETWEEN 1 AND 16),
    CONSTRAINT [CK_assessment_components_max_marks] CHECK ([max_marks] > 0),
    CONSTRAINT [CK_assessment_components_category] CHECK ([category] IN (
        'MIDTERM_1',
        'MIDTERM_2',
        'COURSEWORK',
        'FINAL'
    ))
)
GO

-- ============================================================
-- TABLE: student_assessment_scores
-- Stores each student's score per assessment component.
-- ============================================================
CREATE TABLE [dbo].[student_assessment_scores] (
    [score_id]      [nvarchar](50) NOT NULL CONSTRAINT [DF_student_assessment_scores_id] DEFAULT (CONVERT([nvarchar](50), NEWID())),
    [enrollment_id] [nvarchar](50) NOT NULL,
    [component_id]  [int]          NOT NULL,
    [score]         [decimal](5,2) NULL,
    [graded_at]     [datetime2](7) NULL CONSTRAINT [DF_student_assessment_scores_graded_at] DEFAULT (GETDATE()),

    CONSTRAINT [PK_student_assessment_scores] PRIMARY KEY CLUSTERED ([score_id] ASC),

    CONSTRAINT [UQ_student_assessment_component]
        UNIQUE ([enrollment_id], [component_id]),

    CONSTRAINT [FK_sas_enrollment]
        FOREIGN KEY ([enrollment_id])
        REFERENCES [dbo].[enrollments] ([enrollment_id])
        ON DELETE CASCADE,

    CONSTRAINT [FK_sas_component]
        FOREIGN KEY ([component_id])
        REFERENCES [dbo].[assessment_components] ([component_id]),

    CONSTRAINT [CK_student_assessment_scores_score]
        CHECK ([score] IS NULL OR [score] >= 0)
)
GO

-- ============================================================
-- TRIGGER: Prevent score from exceeding component max marks
-- CHECK constraints cannot compare to another table, so this needs a trigger.
-- ============================================================
CREATE TRIGGER [dbo].[TR_student_assessment_scores_max_marks]
ON [dbo].[student_assessment_scores]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN [dbo].[assessment_components] ac
            ON i.component_id = ac.component_id
        WHERE i.score IS NOT NULL
          AND i.score > ac.max_marks
    )
    BEGIN
        THROW 50003, 'Invalid score: score cannot exceed the assessment component maximum marks.', 1;
    END;
END
GO

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX [IX_students_major_id]
ON [dbo].[students] ([major_id])
GO

CREATE INDEX [IX_instructors_department_id]
ON [dbo].[instructors] ([department_id])
GO

CREATE INDEX [IX_courses_department_id]
ON [dbo].[courses] ([department_id])
GO

CREATE INDEX [IX_course_offerings_course_id]
ON [dbo].[course_offerings] ([course_id])
GO

CREATE INDEX [IX_course_offerings_term_year]
ON [dbo].[course_offerings] ([term], [academic_year])
GO

CREATE INDEX [IX_enrollments_student_id]
ON [dbo].[enrollments] ([student_id])
GO

CREATE INDEX [IX_enrollments_offering_id]
ON [dbo].[enrollments] ([offering_id])
GO

CREATE INDEX [IX_room_schedule_offering_id]
ON [dbo].[room_schedule] ([offering_id])
GO

CREATE INDEX [IX_room_schedule_instructor_id]
ON [dbo].[room_schedule] ([instructor_id])
GO

CREATE INDEX [IX_student_assessment_scores_enrollment_id]
ON [dbo].[student_assessment_scores] ([enrollment_id])
GO

-- ============================================================
-- VIEWS
-- ============================================================

-- Course offering enrollment count
CREATE VIEW [dbo].[vw_course_enrollment] AS
SELECT
    e.offering_id,
    COUNT(*) AS enrolled_count
FROM [dbo].[enrollments] e
WHERE e.status = 'ENROLLED'
GROUP BY e.offering_id
GO

-- Full course offering view
CREATE VIEW [dbo].[vw_course_full] AS
SELECT
    co.offering_id,
    co.course_id,
    c.course_name,
    c.description,
    c.credits,
    co.term,
    co.academic_year,
    co.section_code,
    co.capacity,
    co.status,
    co.created_at,
    d.department_id,
    d.department_name,
    ISNULL(ce.enrolled_count, 0) AS enrolled,
    co.capacity - ISNULL(ce.enrolled_count, 0) AS available_seats,

    (
        SELECT TOP 1 rs.room_id
        FROM [dbo].[room_schedule] rs
        WHERE rs.offering_id = co.offering_id
        ORDER BY rs.schedule_id
    ) AS room_id,

    (
        SELECT STRING_AGG(
            rs.day_of_week + ' ' +
            CONVERT(VARCHAR(5), ts.start_time, 108) + '-' +
            CONVERT(VARCHAR(5), ts.end_time, 108) +
            ' @ ' + rs.room_id,
            ', '
        )
        FROM [dbo].[room_schedule] rs
        JOIN [dbo].[time_slots] ts
            ON rs.slot_id = ts.slot_id
        WHERE rs.offering_id = co.offering_id
    ) AS schedule,

    (
        SELECT STRING_AGG(ci.instructor_id, ', ')
        FROM [dbo].[course_instructors] ci
        WHERE ci.offering_id = co.offering_id
    ) AS instructor_ids,

    (
        SELECT STRING_AGG(i.title + ' ' + i.first_name + ' ' + i.last_name, ', ')
        FROM [dbo].[course_instructors] ci
        JOIN [dbo].[instructors] i
            ON ci.instructor_id = i.id
        WHERE ci.offering_id = co.offering_id
    ) AS instructor_names

FROM [dbo].[course_offerings] co
JOIN [dbo].[courses] c
    ON co.course_id = c.course_id
LEFT JOIN [dbo].[departments] d
    ON c.department_id = d.department_id
LEFT JOIN [dbo].[vw_course_enrollment] ce
    ON co.offering_id = ce.offering_id
GO

-- AASTMT-style gradebook view
CREATE VIEW [dbo].[vw_enrollment_gradebook] AS
SELECT
    e.enrollment_id,
    e.student_id,
    s.first_name + ' ' + s.last_name AS student_name,
    e.offering_id,
    co.course_id,
    c.course_name,
    co.term,
    co.academic_year,
    c.credits,
    e.status,

    SUM(CASE WHEN ac.component_code = 'W7_LEC'  THEN ISNULL(sas.score, 0) ELSE 0 END) AS week7_lecture,
    SUM(CASE WHEN ac.component_code = 'W7_SEC'  THEN ISNULL(sas.score, 0) ELSE 0 END) AS week7_section,
    SUM(CASE WHEN ac.component_code = 'W12_LEC' THEN ISNULL(sas.score, 0) ELSE 0 END) AS week12_lecture,
    SUM(CASE WHEN ac.component_code = 'W12_SEC' THEN ISNULL(sas.score, 0) ELSE 0 END) AS week12_section,
    SUM(CASE WHEN ac.component_code = 'CW'      THEN ISNULL(sas.score, 0) ELSE 0 END) AS coursework,
    SUM(CASE WHEN ac.component_code = 'FINAL'   THEN ISNULL(sas.score, 0) ELSE 0 END) AS final_exam,

    SUM(ISNULL(sas.score, 0)) AS total_grade,
    SUM(ac.max_marks) AS max_grade,

    CAST(
        CASE
            WHEN SUM(ac.max_marks) = 0 THEN 0
            ELSE (SUM(ISNULL(sas.score, 0)) * 100.0 / SUM(ac.max_marks))
        END
        AS DECIMAL(5,2)
    ) AS percentage,

    SUM(CASE WHEN sas.score IS NOT NULL THEN 1 ELSE 0 END) AS graded_components,
    COUNT(ac.component_id) AS total_components,

    CASE
        WHEN e.status = 'WITHDRAWN'  THEN 'W'
        WHEN e.status = 'INCOMPLETE' THEN 'I'
        WHEN SUM(CASE WHEN sas.score IS NOT NULL THEN 1 ELSE 0 END) < COUNT(ac.component_id) THEN NULL
        WHEN SUM(ISNULL(sas.score, 0)) >= 97 THEN 'A+'
        WHEN SUM(ISNULL(sas.score, 0)) >= 93 THEN 'A'
        WHEN SUM(ISNULL(sas.score, 0)) >= 90 THEN 'A-'
        WHEN SUM(ISNULL(sas.score, 0)) >= 87 THEN 'B+'
        WHEN SUM(ISNULL(sas.score, 0)) >= 83 THEN 'B'
        WHEN SUM(ISNULL(sas.score, 0)) >= 80 THEN 'B-'
        WHEN SUM(ISNULL(sas.score, 0)) >= 77 THEN 'C+'
        WHEN SUM(ISNULL(sas.score, 0)) >= 73 THEN 'C'
        WHEN SUM(ISNULL(sas.score, 0)) >= 70 THEN 'C-'
        WHEN SUM(ISNULL(sas.score, 0)) >= 67 THEN 'D+'
        WHEN SUM(ISNULL(sas.score, 0)) >= 63 THEN 'D'
        WHEN SUM(ISNULL(sas.score, 0)) >= 60 THEN 'D-'
        ELSE 'F'
    END AS letter_grade,

    CASE
        WHEN e.status IN ('WITHDRAWN', 'INCOMPLETE') THEN NULL
        WHEN SUM(CASE WHEN sas.score IS NOT NULL THEN 1 ELSE 0 END) < COUNT(ac.component_id) THEN NULL
        WHEN SUM(ISNULL(sas.score, 0)) >= 97 THEN 4.0
        WHEN SUM(ISNULL(sas.score, 0)) >= 93 THEN 4.0
        WHEN SUM(ISNULL(sas.score, 0)) >= 90 THEN 3.7
        WHEN SUM(ISNULL(sas.score, 0)) >= 87 THEN 3.3
        WHEN SUM(ISNULL(sas.score, 0)) >= 83 THEN 3.0
        WHEN SUM(ISNULL(sas.score, 0)) >= 80 THEN 2.7
        WHEN SUM(ISNULL(sas.score, 0)) >= 77 THEN 2.3
        WHEN SUM(ISNULL(sas.score, 0)) >= 73 THEN 2.0
        WHEN SUM(ISNULL(sas.score, 0)) >= 70 THEN 1.7
        WHEN SUM(ISNULL(sas.score, 0)) >= 67 THEN 1.3
        WHEN SUM(ISNULL(sas.score, 0)) >= 63 THEN 1.0
        WHEN SUM(ISNULL(sas.score, 0)) >= 60 THEN 0.7
        ELSE 0.0
    END AS gpa_points

FROM [dbo].[enrollments] e
JOIN [dbo].[students] s
    ON e.student_id = s.id
JOIN [dbo].[course_offerings] co
    ON e.offering_id = co.offering_id
JOIN [dbo].[courses] c
    ON co.course_id = c.course_id
CROSS JOIN [dbo].[assessment_components] ac
LEFT JOIN [dbo].[student_assessment_scores] sas
    ON sas.enrollment_id = e.enrollment_id
   AND sas.component_id = ac.component_id
GROUP BY
    e.enrollment_id,
    e.student_id,
    s.first_name,
    s.last_name,
    e.offering_id,
    co.course_id,
    c.course_name,
    co.term,
    co.academic_year,
    c.credits,
    e.status
GO

-- GPA view calculated from completed gradebook records
CREATE VIEW [dbo].[vw_student_gpa] AS
SELECT
    g.student_id,
    ROUND(
        SUM(g.gpa_points * g.credits) / NULLIF(SUM(g.credits), 0),
        2
    ) AS gpa,
    COUNT(*) AS total_courses,
    SUM(CASE WHEN g.status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_courses,
    SUM(CASE WHEN g.status = 'WITHDRAWN' THEN 1 ELSE 0 END) AS withdrawn_courses
FROM [dbo].[vw_enrollment_gradebook] g
WHERE g.status = 'COMPLETED'
  AND g.gpa_points IS NOT NULL
GROUP BY g.student_id
GO

-- Student full view
CREATE VIEW [dbo].[vw_student_full] AS
SELECT
    s.id,
    s.first_name,
    s.last_name,
    s.first_name + ' ' + s.last_name AS full_name,
    s.email,
    s.personal_email,
    s.phone,
    s.year,
    s.status,
    s.created_at,
    m.major_id,
    m.major_name,
    d.department_id,
    d.department_name,
    ISNULL(g.gpa, 0.00) AS gpa,
    ISNULL(g.total_courses, 0) AS total_courses,
    ISNULL(g.completed_courses, 0) AS completed_courses,
    ISNULL(g.withdrawn_courses, 0) AS withdrawn_courses
FROM [dbo].[students] s
LEFT JOIN [dbo].[majors] m
    ON s.major_id = m.major_id
LEFT JOIN [dbo].[departments] d
    ON m.department_id = d.department_id
LEFT JOIN [dbo].[vw_student_gpa] g
    ON s.id = g.student_id
GO

-- Instructor full view
CREATE VIEW [dbo].[vw_instructor_full] AS
SELECT
    i.id,
    i.first_name,
    i.last_name,
    i.first_name + ' ' + i.last_name AS full_name,
    i.email,
    i.phone,
    i.title,
    i.status,
    i.created_at,
    d.department_id,
    d.department_name,
    COUNT(DISTINCT ci.offering_id) AS assigned_offerings
FROM [dbo].[instructors] i
LEFT JOIN [dbo].[departments] d
    ON i.department_id = d.department_id
LEFT JOIN [dbo].[course_instructors] ci
    ON i.id = ci.instructor_id
GROUP BY
    i.id,
    i.first_name,
    i.last_name,
    i.email,
    i.phone,
    i.title,
    i.status,
    i.created_at,
    d.department_id,
    d.department_name
GO

-- Student transcript view using the AASTMT-style gradebook
CREATE VIEW [dbo].[vw_student_transcript] AS
SELECT
    g.student_id,
    s.first_name + ' ' + s.last_name AS student_name,
    s.email,
    m.major_name,
    g.offering_id,
    g.course_id,
    g.course_name,
    g.term,
    g.academic_year,
    g.credits,
    g.status,
    g.week7_lecture,
    g.week7_section,
    (g.week7_lecture + g.week7_section) AS week7_total,
    g.week12_lecture,
    g.week12_section,
    (g.week12_lecture + g.week12_section) AS week12_total,
    g.coursework,
    g.final_exam,
    g.total_grade,
    g.max_grade,
    g.percentage,
    g.letter_grade,
    g.gpa_points
FROM [dbo].[vw_enrollment_gradebook] g
JOIN [dbo].[students] s
    ON g.student_id = s.id
LEFT JOIN [dbo].[majors] m
    ON s.major_id = m.major_id
GO

-- ============================================================
-- SEED DATA
-- ============================================================

INSERT INTO [dbo].[time_slots] ([slot_id], [start_time], [end_time]) VALUES
(1, '08:30', '10:10'),
(2, '10:30', '12:10'),
(3, '12:30', '14:10'),
(4, '14:30', '16:10')
GO

INSERT INTO [dbo].[registration_periods]
([term], [academic_year], [add_start_date], [add_end_date], [drop_end_date], [status])
VALUES
('TERM1',  2025, '2025-09-01', '2025-09-14', '2025-09-21', 'OPEN'),
('TERM2',  2026, '2026-02-01', '2026-02-14', '2026-02-21', 'OPEN')
GO

INSERT INTO [dbo].[departments] ([department_id], [department_name], [description]) VALUES
('CS',   'Computer Science',        'Covers algorithms, software engineering, AI, and systems.'),
('MATH', 'Mathematics',             'Pure and applied mathematics including calculus and statistics.'),
('EE',   'Electrical Engineering',  'Circuit design, signal processing, and embedded systems.'),
('BUS',  'Business Administration', 'Management, accounting, finance, and entrepreneurship.'),
('ENG',  'English',                 'Literature, linguistics, writing, and communication.')
GO

INSERT INTO [dbo].[majors] ([major_id], [major_name], [department_id], [total_credits]) VALUES
('CS-BS',   'Bachelor of Science in Computer Science', 'CS',   128),
('MATH-BS', 'Bachelor of Science in Mathematics',      'MATH', 120),
('EE-BS',   'Bachelor of Science in Electrical Eng.',  'EE',   132),
('BUS-BS',  'Bachelor of Science in Business Admin.',  'BUS',  120),
('ENG-BA',  'Bachelor of Arts in English',             'ENG',  120)
GO

INSERT INTO [dbo].[rooms] ([room_id], [building], [capacity], [room_type]) VALUES
('A101', 'Alpha Building',  35,  'LECTURE'),
('A102', 'Alpha Building',  35,  'LECTURE'),
('A103', 'Alpha Building',  25,  'SEMINAR'),
('B201', 'Beta Building',   50,  'LECTURE'),
('B202', 'Beta Building',   30,  'LAB'),
('C301', 'Gamma Building',  200, 'AUDITORIUM'),
('C302', 'Gamma Building',  25,  'LAB')
GO

INSERT INTO [dbo].[admins] ([id], [first_name], [last_name], [email], [password], [admin_level]) VALUES
('ADM001', 'System',  'Admin',  'admin@university.edu',    'admin123', 'SUPER'),
('ADM002', 'John',    'Doe',    'j.doe@university.edu',    'mod123',   'MODERATOR'),
('ADM003', 'Emily',   'Carter', 'e.carter@university.edu', 'std123',   'STANDARD')
GO

INSERT INTO [dbo].[instructors] ([id], [first_name], [last_name], [email], [password], [phone], [department_id], [title], [status]) VALUES
('INS001', 'Sarah',   'Mitchell', 's.mitchell@university.edu', 'ins123', '555-0101', 'CS',   'Professor',           'ACTIVE'),
('INS002', 'James',   'Turner',   'j.turner@university.edu',   'ins123', '555-0102', 'CS',   'Associate Professor', 'ACTIVE'),
('INS003', 'Laura',   'Bennett',  'l.bennett@university.edu',  'ins123', '555-0103', 'MATH', 'Assistant Professor', 'ACTIVE'),
('INS004', 'Michael', 'Hayes',    'm.hayes@university.edu',    'ins123', '555-0104', 'EE',   'Professor',           'ACTIVE'),
('INS005', 'Rachel',  'Collins',  'r.collins@university.edu',  'ins123', '555-0105', 'BUS',  'Lecturer',            'ACTIVE')
GO

INSERT INTO [dbo].[students] ([id], [first_name], [last_name], [email], [personal_email], [password], [phone], [major_id], [year], [status]) VALUES
('STU001', 'Alice',  'Johnson',  'a.johnson@university.edu',  'alice@gmail.com',  'stu123', '555-1001', 'CS-BS',   1, 'ACTIVE'),
('STU002', 'Bob',    'Smith',    'b.smith@university.edu',    'bob@gmail.com',    'stu123', '555-1002', 'CS-BS',   2, 'ACTIVE'),
('STU003', 'Carol',  'White',    'c.white@university.edu',    'carol@gmail.com',  'stu123', '555-1003', 'MATH-BS', 1, 'ACTIVE'),
('STU004', 'David',  'Brown',    'd.brown@university.edu',    'david@gmail.com',  'stu123', '555-1004', 'EE-BS',   3, 'ACTIVE'),
('STU005', 'Eva',    'Martinez', 'e.martinez@university.edu', 'eva@gmail.com',    'stu123', '555-1005', 'BUS-BS',  2, 'ACTIVE'),
('STU006', 'Frank',  'Lee',      'f.lee@university.edu',      'frank@gmail.com',  'stu123', '555-1006', 'CS-BS',   1, 'ACTIVE'),
('STU007', 'Grace',  'Wilson',   'g.wilson@university.edu',   'grace@gmail.com',  'stu123', '555-1007', 'ENG-BA',  4, 'ACTIVE'),
('STU008', 'Henry',  'Taylor',   'h.taylor@university.edu',   'henry@gmail.com',  'stu123', '555-1008', 'MATH-BS', 2, 'ACTIVE'),
('STU009', 'Isla',   'Anderson', 'i.anderson@university.edu', 'isla@gmail.com',   'stu123', '555-1009', 'CS-BS',   3, 'ACTIVE'),
('STU010', 'Jake',   'Thomas',   'j.thomas@university.edu',   'jake@gmail.com',   'stu123', '555-1010', 'EE-BS',   1, 'ACTIVE')
GO

INSERT INTO [dbo].[courses] ([course_id], [course_name], [description], [department_id], [credits]) VALUES
('CS101',   'Introduction to Programming', 'Fundamentals of programming using Java.',                    'CS',   3),
('CS201',   'Data Structures',             'Arrays, linked lists, trees, and graphs.',                   'CS',   3),
('CS301',   'Algorithms',                  'Algorithm design, complexity, and optimization.',            'CS',   3),
('CS401',   'Operating Systems',           'Process management, memory, and file systems.',              'CS',   3),
('CS202',   'Database Systems',            'Relational databases, SQL, and normalization.',              'CS',   3),
('MATH101', 'Calculus I',                  'Limits, derivatives, and integrals.',                        'MATH', 3),
('MATH201', 'Linear Algebra',              'Vectors, matrices, and linear transformations.',             'MATH', 3),
('EE101',   'Circuit Analysis',            'Basic circuit laws, resistors, capacitors, and inductors.', 'EE',   3),
('BUS101',  'Principles of Management',    'Introduction to management theory and practice.',            'BUS',  3),
('ENG101',  'English Composition',         'Academic writing, grammar, and research skills.',           'ENG',  3)
GO

INSERT INTO [dbo].[course_offerings]
([offering_id], [course_id], [term], [academic_year], [section_code], [capacity], [status])
VALUES
('OFF001', 'CS101',   'TERM1',  2025, 'L01', 30, 'OPEN'),
('OFF002', 'CS201',   'TERM1',  2025, 'L01', 25, 'OPEN'),
('OFF003', 'CS301',   'TERM1',  2025, 'L01', 20, 'OPEN'),
('OFF004', 'CS401',   'TERM1',  2025, 'L01', 25, 'OPEN'),
('OFF005', 'CS202',   'TERM1',  2025, 'L01', 25, 'OPEN'),
('OFF006', 'MATH101', 'TERM1',  2025, 'L01', 35, 'OPEN'),
('OFF007', 'MATH201', 'TERM1',  2025, 'L01', 30, 'OPEN'),
('OFF008', 'EE101',   'TERM1',  2025, 'L01', 30, 'OPEN'),
('OFF009', 'BUS101',  'TERM1',  2025, 'L01', 40, 'OPEN'),
('OFF010', 'ENG101',  'TERM1',  2025, 'L01', 25, 'OPEN'),
('OFF011', 'CS101',   'TERM2',  2026, 'L01', 30, 'OPEN')
GO

INSERT INTO [dbo].[course_prerequisites] ([course_id], [prerequisite_id]) VALUES
('CS201',   'CS101'),
('CS301',   'CS201'),
('CS401',   'CS301'),
('CS202',   'CS101'),
('MATH201', 'MATH101')
GO

INSERT INTO [dbo].[course_instructors] ([offering_id], [instructor_id], [role]) VALUES
('OFF001', 'INS001', 'LECTURE'),
('OFF002', 'INS001', 'LECTURE'),
('OFF003', 'INS002', 'LECTURE'),
('OFF004', 'INS002', 'LECTURE'),
('OFF005', 'INS001', 'LECTURE'),
('OFF006', 'INS003', 'LECTURE'),
('OFF007', 'INS003', 'LECTURE'),
('OFF008', 'INS004', 'LECTURE'),
('OFF009', 'INS005', 'LECTURE'),
('OFF010', 'INS005', 'LECTURE'),
('OFF011', 'INS001', 'LECTURE')
GO

INSERT INTO [dbo].[room_schedule] ([offering_id], [room_id], [instructor_id], [day_of_week], [slot_id]) VALUES
('OFF001', 'A101', 'INS001', 'Monday',    1),
('OFF001', 'A101', 'INS001', 'Wednesday', 1),
('OFF001', 'A101', 'INS001', 'Friday',    1),

('OFF002', 'A102', 'INS001', 'Tuesday',   2),
('OFF002', 'A102', 'INS001', 'Thursday',  2),

('OFF003', 'A103', 'INS002', 'Tuesday',   1),
('OFF003', 'A103', 'INS002', 'Thursday',  1),

('OFF004', 'B201', 'INS002', 'Monday',    3),
('OFF004', 'B201', 'INS002', 'Wednesday', 3),

('OFF005', 'B202', 'INS001', 'Monday',    4),
('OFF005', 'B202', 'INS001', 'Wednesday', 4),

('OFF006', 'A101', 'INS003', 'Tuesday',   2),
('OFF006', 'A101', 'INS003', 'Thursday',  2),

('OFF007', 'A102', 'INS003', 'Monday',    1),
('OFF007', 'A102', 'INS003', 'Wednesday', 1),

('OFF008', 'B201', 'INS004', 'Monday',    2),
('OFF008', 'B201', 'INS004', 'Wednesday', 2),

('OFF009', 'C301', 'INS005', 'Tuesday',   3),
('OFF009', 'C301', 'INS005', 'Thursday',  3),

('OFF010', 'A103', 'INS005', 'Monday',    4),
('OFF010', 'A103', 'INS005', 'Wednesday', 4),

-- Same CS101 room/time pattern in a different term is allowed by the trigger.
('OFF011', 'A101', 'INS001', 'Monday',    1),
('OFF011', 'A101', 'INS001', 'Wednesday', 1),
('OFF011', 'A101', 'INS001', 'Friday',    1)
GO

INSERT INTO [dbo].[assessment_components]
([component_code], [component_name], [week_no], [category], [max_marks], [display_order])
VALUES
('W7_LEC',  'Week 7 Lecture Exam',   7,  'MIDTERM_1', 20, 1),
('W7_SEC',  'Week 7 Section Exam',   7,  'MIDTERM_1', 10, 2),
('W12_LEC', 'Week 12 Lecture Exam', 12,  'MIDTERM_2', 15, 3),
('W12_SEC', 'Week 12 Section Exam', 12,  'MIDTERM_2', 5,  4),
('CW',      'Coursework',           NULL,'COURSEWORK',10, 5),
('FINAL',   'Final Exam',           NULL,'FINAL',     40, 6)
GO

INSERT INTO [dbo].[enrollments]
([enrollment_id], [student_id], [offering_id], [status])
VALUES
('ENR001', 'STU001', 'OFF001', 'COMPLETED'),
('ENR002', 'STU001', 'OFF006', 'COMPLETED'),
('ENR003', 'STU002', 'OFF001', 'COMPLETED'),
('ENR004', 'STU002', 'OFF002', 'ENROLLED'),
('ENR005', 'STU003', 'OFF006', 'COMPLETED'),
('ENR006', 'STU003', 'OFF007', 'ENROLLED'),
('ENR007', 'STU004', 'OFF008', 'COMPLETED'),
('ENR008', 'STU004', 'OFF001', 'COMPLETED'),
('ENR009', 'STU005', 'OFF009', 'ENROLLED'),
('ENR010', 'STU006', 'OFF001', 'ENROLLED'),
('ENR011', 'STU006', 'OFF006', 'ENROLLED'),
('ENR012', 'STU007', 'OFF010', 'COMPLETED'),
('ENR013', 'STU008', 'OFF006', 'COMPLETED'),
('ENR014', 'STU008', 'OFF007', 'ENROLLED'),
('ENR015', 'STU009', 'OFF002', 'COMPLETED'),
('ENR016', 'STU009', 'OFF003', 'ENROLLED'),
('ENR017', 'STU010', 'OFF008', 'ENROLLED'),
('ENR018', 'STU010', 'OFF001', 'ENROLLED')
GO

INSERT INTO [dbo].[student_assessment_scores]
([enrollment_id], [component_id], [score])
SELECT v.enrollment_id, ac.component_id, v.score
FROM (VALUES
    -- ENR001 total 95
    ('ENR001', 'W7_LEC',  19.00), ('ENR001', 'W7_SEC', 10.00),
    ('ENR001', 'W12_LEC', 14.00), ('ENR001', 'W12_SEC', 5.00),
    ('ENR001', 'CW',       9.00), ('ENR001', 'FINAL',  38.00),

    -- ENR002 total 88
    ('ENR002', 'W7_LEC',  17.00), ('ENR002', 'W7_SEC', 9.00),
    ('ENR002', 'W12_LEC', 13.00), ('ENR002', 'W12_SEC', 4.00),
    ('ENR002', 'CW',       8.00), ('ENR002', 'FINAL',  37.00),

    -- ENR003 total 78
    ('ENR003', 'W7_LEC',  15.00), ('ENR003', 'W7_SEC', 8.00),
    ('ENR003', 'W12_LEC', 11.00), ('ENR003', 'W12_SEC', 4.00),
    ('ENR003', 'CW',       7.00), ('ENR003', 'FINAL',  33.00),

    -- ENR005 total 91
    ('ENR005', 'W7_LEC',  18.00), ('ENR005', 'W7_SEC', 9.00),
    ('ENR005', 'W12_LEC', 14.00), ('ENR005', 'W12_SEC', 4.00),
    ('ENR005', 'CW',       9.00), ('ENR005', 'FINAL',  37.00),

    -- ENR007 total 85
    ('ENR007', 'W7_LEC',  17.00), ('ENR007', 'W7_SEC', 8.00),
    ('ENR007', 'W12_LEC', 13.00), ('ENR007', 'W12_SEC', 4.00),
    ('ENR007', 'CW',       8.00), ('ENR007', 'FINAL',  35.00),

    -- ENR008 total 72
    ('ENR008', 'W7_LEC',  14.00), ('ENR008', 'W7_SEC', 7.00),
    ('ENR008', 'W12_LEC', 10.00), ('ENR008', 'W12_SEC', 4.00),
    ('ENR008', 'CW',       7.00), ('ENR008', 'FINAL',  30.00),

    -- ENR012 total 93
    ('ENR012', 'W7_LEC',  19.00), ('ENR012', 'W7_SEC', 9.00),
    ('ENR012', 'W12_LEC', 14.00), ('ENR012', 'W12_SEC', 5.00),
    ('ENR012', 'CW',       9.00), ('ENR012', 'FINAL',  37.00),

    -- ENR013 total 87
    ('ENR013', 'W7_LEC',  17.00), ('ENR013', 'W7_SEC', 9.00),
    ('ENR013', 'W12_LEC', 13.00), ('ENR013', 'W12_SEC', 4.00),
    ('ENR013', 'CW',       8.00), ('ENR013', 'FINAL',  36.00),

    -- ENR015 total 80
    ('ENR015', 'W7_LEC',  16.00), ('ENR015', 'W7_SEC', 8.00),
    ('ENR015', 'W12_LEC', 12.00), ('ENR015', 'W12_SEC', 4.00),
    ('ENR015', 'CW',       8.00), ('ENR015', 'FINAL',  32.00),

    -- Partial in-progress marks for ENR010
    ('ENR010', 'W7_LEC',  18.00), ('ENR010', 'W7_SEC', 8.00),
    ('ENR010', 'CW',       7.00)
) AS v(enrollment_id, component_code, score)
JOIN [dbo].[assessment_components] ac
    ON ac.component_code = v.component_code
GO

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT 'departments' AS [table], COUNT(*) AS [rows] FROM [dbo].[departments]
UNION ALL SELECT 'majors', COUNT(*) FROM [dbo].[majors]
UNION ALL SELECT 'rooms', COUNT(*) FROM [dbo].[rooms]
UNION ALL SELECT 'time_slots', COUNT(*) FROM [dbo].[time_slots]
UNION ALL SELECT 'registration_periods', COUNT(*) FROM [dbo].[registration_periods]
UNION ALL SELECT 'admins', COUNT(*) FROM [dbo].[admins]
UNION ALL SELECT 'instructors', COUNT(*) FROM [dbo].[instructors]
UNION ALL SELECT 'students', COUNT(*) FROM [dbo].[students]
UNION ALL SELECT 'courses', COUNT(*) FROM [dbo].[courses]
UNION ALL SELECT 'course_offerings', COUNT(*) FROM [dbo].[course_offerings]
UNION ALL SELECT 'course_prerequisites', COUNT(*) FROM [dbo].[course_prerequisites]
UNION ALL SELECT 'course_instructors', COUNT(*) FROM [dbo].[course_instructors]
UNION ALL SELECT 'room_schedule', COUNT(*) FROM [dbo].[room_schedule]
UNION ALL SELECT 'enrollments', COUNT(*) FROM [dbo].[enrollments]
UNION ALL SELECT 'assessment_components', COUNT(*) FROM [dbo].[assessment_components]
UNION ALL SELECT 'student_assessment_scores', COUNT(*) FROM [dbo].[student_assessment_scores]
GO

SELECT TOP 10 * FROM [dbo].[vw_course_full]
GO

SELECT TOP 10 * FROM [dbo].[vw_student_transcript]
ORDER BY student_id, academic_year, term, course_id
GO

SELECT TOP 10 * FROM [dbo].[vw_enrollment_gradebook]
ORDER BY student_id, course_id
GO

SELECT TOP 10 * FROM [dbo].[vw_student_full]
GO

SELECT TOP 10 * FROM [dbo].[vw_instructor_full]
GO


/* ===================== PART 2: DATA SEED ===================== */

USE [UniversityDB];
GO

/* ============================================================
   Option B Realistic Dummy Data Seed
   Generated for the University Registration & Academic Management System.

   Scale:
   - 8 departments
   - 28 majors
   - 80 students
   - 24 instructors/TAs
   - 4 admins
   - 40 courses
   - 60 course offerings
   - active, completed, and withdrawn enrollment history
   - component-based assessment scores
   - no Friday classes

   Login style:
   - Students:    student001@university.edu / stu123
   - Instructors: instructor001@university.edu / ins123
   - Admins:      super.admin@university.edu / admin123

   This script CLEANS OLD DATA first.
   ============================================================ */
GO

-- ============================================================
-- 0. SCHEMA RULE PATCHES
-- ============================================================

-- Allow medical/pharmacy/dentistry-style programs up to year 7.
IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_students_year'
      AND parent_object_id = OBJECT_ID('dbo.students')
)
BEGIN
    ALTER TABLE dbo.students DROP CONSTRAINT CK_students_year;
END;
GO

ALTER TABLE dbo.students
WITH CHECK ADD CONSTRAINT CK_students_year
CHECK ([year] >= 1 AND [year] <= 7);
GO

-- Simplify room types: SECTION is a meeting type, not a room type.
UPDATE dbo.rooms
SET room_type = 'LECTURE'
WHERE room_type IN ('SEMINAR', 'AUDITORIUM') OR room_type IS NULL;
GO

IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_rooms_room_type'
      AND parent_object_id = OBJECT_ID('dbo.rooms')
)
BEGIN
    ALTER TABLE dbo.rooms DROP CONSTRAINT CK_rooms_room_type;
END;
GO

ALTER TABLE dbo.rooms
WITH CHECK ADD CONSTRAINT CK_rooms_room_type
CHECK (room_type IN ('LECTURE', 'LAB'));
GO

CREATE OR ALTER TRIGGER dbo.trg_room_schedule_room_type_guard
ON dbo.room_schedule
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.rooms r
            ON i.room_id = r.room_id
        WHERE
            (i.meeting_type IN ('LECTURE', 'SECTION') AND r.room_type <> 'LECTURE')
            OR
            (i.meeting_type = 'LAB' AND r.room_type <> 'LAB')
    )
    BEGIN
        THROW 51030,
            'Invalid room type: LECTURE and SECTION meetings must use LECTURE rooms; LAB meetings must use LAB rooms.',
            1;
    END
END;
GO

-- ============================================================
-- 1. CLEAN OLD DATA
-- ============================================================

DELETE FROM dbo.student_assessment_scores;
DELETE FROM dbo.enrollments;
DELETE FROM dbo.room_schedule;
DELETE FROM dbo.course_instructors;
DELETE FROM dbo.course_prerequisites;
DELETE FROM dbo.course_offerings;
DELETE FROM dbo.courses;
DELETE FROM dbo.students;
DELETE FROM dbo.instructors;
DELETE FROM dbo.admins;
DELETE FROM dbo.rooms;
DELETE FROM dbo.time_slots;
DELETE FROM dbo.majors;
DELETE FROM dbo.departments;
DELETE FROM dbo.assessment_components;
DELETE FROM dbo.registration_periods;
GO

DBCC CHECKIDENT ('dbo.room_schedule', RESEED, 0);
DBCC CHECKIDENT ('dbo.assessment_components', RESEED, 0);
DBCC CHECKIDENT ('dbo.registration_periods', RESEED, 0);
GO

-- ============================================================
-- 2. DEPARTMENTS & MAJORS
-- ============================================================

INSERT INTO dbo.departments (department_id, department_name, description) VALUES
    (N'DCS', N'Computer Science & Informatics', N'Computing, software, cybersecurity, artificial intelligence, and data-driven systems.'),
    (N'DENG', N'Engineering', N'Engineering disciplines including mechatronics, electrical, mechanical, and civil engineering.'),
    (N'DPHR', N'Pharmacy', N'PharmD, clinical pharmacy, pharmaceutical sciences, drug formulation, and patient medication care.'),
    (N'DMED', N'Medicine / Medical Sciences', N'Medical and health-science programs including nursing, laboratories, imaging, and clinical practice.'),
    (N'DBUS', N'Business Administration', N'Accounting, finance, marketing, management, and business information systems.'),
    (N'DDEN', N'Dentistry', N'Oral health, dental surgery, clinical dentistry, and dental practice.'),
    (N'DART', N'Arts & Design', N'Graphic design, digital media, interior design, and creative visual communication.'),
    (N'DMCM', N'Mass Communication', N'Journalism, public relations, radio, television, and digital communication.');
GO

INSERT INTO dbo.majors (major_id, major_name, department_id, total_credits) VALUES
    (N'MCS', N'Computer Science', N'DCS', 144),
    (N'MSE', N'Software Engineering', N'DCS', 144),
    (N'MAI', N'Artificial Intelligence', N'DCS', 144),
    (N'MCY', N'Cybersecurity', N'DCS', 144),
    (N'MDS', N'Data Science', N'DCS', 144),
    (N'MEMT', N'Mechatronics Engineering', N'DENG', 160),
    (N'MELC', N'Electrical Engineering', N'DENG', 160),
    (N'MMEC', N'Mechanical Engineering', N'DENG', 160),
    (N'MCIV', N'Civil Engineering', N'DENG', 160),
    (N'MPHD', N'PharmD', N'DPHR', 190),
    (N'MCPH', N'Clinical Pharmacy', N'DPHR', 190),
    (N'MPSC', N'Pharmaceutical Sciences', N'DPHR', 180),
    (N'MMBS', N'Medicine and Surgery', N'DMED', 220),
    (N'MNUR', N'Nursing', N'DMED', 150),
    (N'MMLS', N'Medical Laboratory Sciences', N'DMED', 160),
    (N'MRAD', N'Radiology and Medical Imaging', N'DMED', 160),
    (N'MACC', N'Accounting', N'DBUS', 144),
    (N'MFIN', N'Finance', N'DBUS', 144),
    (N'MMKT', N'Marketing', N'DBUS', 144),
    (N'MBIS', N'Business Information Systems', N'DBUS', 144),
    (N'MODM', N'Oral and Dental Medicine', N'DDEN', 190),
    (N'MDSG', N'Dental Surgery', N'DDEN', 190),
    (N'MGRA', N'Graphic Design', N'DART', 144),
    (N'MINT', N'Interior Design', N'DART', 144),
    (N'MDM', N'Digital Media', N'DART', 144),
    (N'MJRN', N'Journalism', N'DMCM', 144),
    (N'MPR', N'Public Relations', N'DMCM', 144),
    (N'MRTV', N'Radio and Television', N'DMCM', 144);
GO

-- ============================================================
-- 3. ADMINS, INSTRUCTORS, STUDENTS
-- ============================================================

INSERT INTO dbo.admins (id, first_name, last_name, email, password, admin_level) VALUES
    (N'ADM001', N'Super', N'Admin', N'super.admin@university.edu', N'admin123', N'SUPER'),
    (N'ADM002', N'Moderator', N'Admin', N'moderator.admin@university.edu', N'admin123', N'MODERATOR'),
    (N'ADM003', N'Standard', N'Admin', N'standard.admin@university.edu', N'admin123', N'STANDARD'),
    (N'ADM004', N'Academic', N'Officer', N'academic.officer@university.edu', N'admin123', N'MODERATOR');
GO

INSERT INTO dbo.instructors (id, first_name, last_name, email, password, phone, department_id, title, status) VALUES
    (N'INS001', N'Ahmed', N'Hassan', N'instructor001@university.edu', N'ins123', N'0105500001', N'DCS', N'Professor', N'ACTIVE'),
    (N'INS002', N'Mona', N'Ibrahim', N'instructor002@university.edu', N'ins123', N'0105500002', N'DCS', N'Lecturer', N'ACTIVE'),
    (N'INS003', N'Omar', N'Khaled', N'instructor003@university.edu', N'ins123', N'0105500003', N'DCS', N'Teaching Assistant', N'ACTIVE'),
    (N'INS004', N'Nour', N'Fouad', N'instructor004@university.edu', N'ins123', N'0105500004', N'DENG', N'Professor', N'ACTIVE'),
    (N'INS005', N'Youssef', N'Nassar', N'instructor005@university.edu', N'ins123', N'0105500005', N'DENG', N'Lecturer', N'ACTIVE'),
    (N'INS006', N'Laila', N'Saleh', N'instructor006@university.edu', N'ins123', N'0105500006', N'DENG', N'Teaching Assistant', N'ACTIVE'),
    (N'INS007', N'Karim', N'Mansour', N'instructor007@university.edu', N'ins123', N'0105500007', N'DPHR', N'Professor', N'ACTIVE'),
    (N'INS008', N'Salma', N'Adel', N'instructor008@university.edu', N'ins123', N'0105500008', N'DPHR', N'Lecturer', N'ACTIVE'),
    (N'INS009', N'Hassan', N'Sami', N'instructor009@university.edu', N'ins123', N'0105500009', N'DPHR', N'Teaching Assistant', N'ACTIVE'),
    (N'INS010', N'Dina', N'Shawky', N'instructor010@university.edu', N'ins123', N'0105500010', N'DMED', N'Professor', N'ACTIVE'),
    (N'INS011', N'Mostafa', N'Farouk', N'instructor011@university.edu', N'ins123', N'0105500011', N'DMED', N'Lecturer', N'ACTIVE'),
    (N'INS012', N'Farida', N'Kamal', N'instructor012@university.edu', N'ins123', N'0105500012', N'DMED', N'Teaching Assistant', N'ACTIVE'),
    (N'INS013', N'Tarek', N'Maher', N'instructor013@university.edu', N'ins123', N'0105500013', N'DBUS', N'Professor', N'ACTIVE'),
    (N'INS014', N'Heba', N'Saber', N'instructor014@university.edu', N'ins123', N'0105500014', N'DBUS', N'Lecturer', N'ACTIVE'),
    (N'INS015', N'Mahmoud', N'Galal', N'instructor015@university.edu', N'ins123', N'0105500015', N'DBUS', N'Teaching Assistant', N'ACTIVE'),
    (N'INS016', N'Yara', N'Amin', N'instructor016@university.edu', N'ins123', N'0105500016', N'DDEN', N'Professor', N'ACTIVE'),
    (N'INS017', N'Amr', N'Zaki', N'instructor017@university.edu', N'ins123', N'0105500017', N'DDEN', N'Lecturer', N'ACTIVE'),
    (N'INS018', N'Nada', N'Lotfy', N'instructor018@university.edu', N'ins123', N'0105500018', N'DDEN', N'Teaching Assistant', N'ACTIVE'),
    (N'INS019', N'Sherif', N'Rashad', N'instructor019@university.edu', N'ins123', N'0105500019', N'DART', N'Professor', N'ACTIVE'),
    (N'INS020', N'Rana', N'Bassem', N'instructor020@university.edu', N'ins123', N'0105500020', N'DART', N'Lecturer', N'ACTIVE'),
    (N'INS021', N'Hady', N'Gaber', N'instructor021@university.edu', N'ins123', N'0105500021', N'DART', N'Teaching Assistant', N'ACTIVE'),
    (N'INS022', N'Mariam', N'Nabil', N'instructor022@university.edu', N'ins123', N'0105500022', N'DMCM', N'Professor', N'ACTIVE'),
    (N'INS023', N'Aly', N'Samir', N'instructor023@university.edu', N'ins123', N'0105500023', N'DMCM', N'Lecturer', N'ACTIVE'),
    (N'INS024', N'Jana', N'Tawfik', N'instructor024@university.edu', N'ins123', N'0105500024', N'DMCM', N'Teaching Assistant', N'ACTIVE');
GO

INSERT INTO dbo.students (id, first_name, last_name, email, personal_email, password, phone, major_id, year, status) VALUES
    (N'STU001', N'Adam', N'Hassan', N'student001@university.edu', N'student001.personal@gmail.com', N'stu123', N'0112000001', N'MMLS', 2, N'ACTIVE'),
    (N'STU002', N'Sara', N'Fouad', N'student002@university.edu', N'student002.personal@gmail.com', N'stu123', N'0112000002', N'MMEC', 4, N'ACTIVE'),
    (N'STU003', N'Omar', N'Mansour', N'student003@university.edu', N'student003.personal@gmail.com', N'stu123', N'0112000003', N'MACC', 4, N'ACTIVE'),
    (N'STU004', N'Nour', N'Shawky', N'student004@university.edu', N'student004.personal@gmail.com', N'stu123', N'0112000004', N'MSE', 3, N'ACTIVE'),
    (N'STU005', N'Youssef', N'Maher', N'student005@university.edu', N'student005.personal@gmail.com', N'stu123', N'0112000005', N'MPHD', 7, N'ACTIVE'),
    (N'STU006', N'Laila', N'Amin', N'student006@university.edu', N'student006.personal@gmail.com', N'stu123', N'0112000006', N'MNUR', 2, N'ACTIVE'),
    (N'STU007', N'Karim', N'Rashad', N'student007@university.edu', N'student007.personal@gmail.com', N'stu123', N'0112000007', N'MSE', 3, N'ACTIVE'),
    (N'STU008', N'Salma', N'Samir', N'student008@university.edu', N'student008.personal@gmail.com', N'stu123', N'0112000008', N'MPSC', 7, N'ACTIVE'),
    (N'STU009', N'Hassan', N'Younes', N'student009@university.edu', N'student009.personal@gmail.com', N'stu123', N'0112000009', N'MPR', 5, N'ACTIVE'),
    (N'STU010', N'Dina', N'Ahmed', N'student010@university.edu', N'student010.personal@gmail.com', N'stu123', N'0112000010', N'MCY', 4, N'ACTIVE'),
    (N'STU011', N'Mostafa', N'Hassan', N'student011@university.edu', N'student011.personal@gmail.com', N'stu123', N'0112000011', N'MCPH', 6, N'ACTIVE'),
    (N'STU012', N'Farida', N'Fouad', N'student012@university.edu', N'student012.personal@gmail.com', N'stu123', N'0112000012', N'MMBS', 2, N'ACTIVE'),
    (N'STU013', N'Tarek', N'Mansour', N'student013@university.edu', N'student013.personal@gmail.com', N'stu123', N'0112000013', N'MNUR', 3, N'ACTIVE'),
    (N'STU014', N'Heba', N'Shawky', N'student014@university.edu', N'student014.personal@gmail.com', N'stu123', N'0112000014', N'MJRN', 4, N'ACTIVE'),
    (N'STU015', N'Mahmoud', N'Maher', N'student015@university.edu', N'student015.personal@gmail.com', N'stu123', N'0112000015', N'MODM', 1, N'ACTIVE'),
    (N'STU016', N'Yara', N'Amin', N'student016@university.edu', N'student016.personal@gmail.com', N'stu123', N'0112000016', N'MPHD', 6, N'ACTIVE'),
    (N'STU017', N'Amr', N'Rashad', N'student017@university.edu', N'student017.personal@gmail.com', N'stu123', N'0112000017', N'MPHD', 3, N'ACTIVE'),
    (N'STU018', N'Nada', N'Samir', N'student018@university.edu', N'student018.personal@gmail.com', N'stu123', N'0112000018', N'MCPH', 2, N'ACTIVE'),
    (N'STU019', N'Sherif', N'Younes', N'student019@university.edu', N'student019.personal@gmail.com', N'stu123', N'0112000019', N'MBIS', 3, N'ACTIVE'),
    (N'STU020', N'Rana', N'Ahmed', N'student020@university.edu', N'student020.personal@gmail.com', N'stu123', N'0112000020', N'MELC', 3, N'ACTIVE'),
    (N'STU021', N'Hady', N'Hassan', N'student021@university.edu', N'student021.personal@gmail.com', N'stu123', N'0112000021', N'MGRA', 3, N'ACTIVE'),
    (N'STU022', N'Mariam', N'Fouad', N'student022@university.edu', N'student022.personal@gmail.com', N'stu123', N'0112000022', N'MMBS', 5, N'ACTIVE'),
    (N'STU023', N'Aly', N'Mansour', N'student023@university.edu', N'student023.personal@gmail.com', N'stu123', N'0112000023', N'MCY', 1, N'ACTIVE'),
    (N'STU024', N'Jana', N'Shawky', N'student024@university.edu', N'student024.personal@gmail.com', N'stu123', N'0112000024', N'MCY', 2, N'ACTIVE'),
    (N'STU025', N'Mazen', N'Maher', N'student025@university.edu', N'student025.personal@gmail.com', N'stu123', N'0112000025', N'MRTV', 2, N'ACTIVE'),
    (N'STU026', N'Malak', N'Amin', N'student026@university.edu', N'student026.personal@gmail.com', N'stu123', N'0112000026', N'MMBS', 2, N'ACTIVE'),
    (N'STU027', N'Seif', N'Rashad', N'student027@university.edu', N'student027.personal@gmail.com', N'stu123', N'0112000027', N'MDS', 4, N'ACTIVE'),
    (N'STU028', N'Judy', N'Samir', N'student028@university.edu', N'student028.personal@gmail.com', N'stu123', N'0112000028', N'MINT', 2, N'ACTIVE'),
    (N'STU029', N'Ziad', N'Younes', N'student029@university.edu', N'student029.personal@gmail.com', N'stu123', N'0112000029', N'MELC', 2, N'ACTIVE'),
    (N'STU030', N'Habiba', N'Ahmed', N'student030@university.edu', N'student030.personal@gmail.com', N'stu123', N'0112000030', N'MACC', 1, N'ACTIVE'),
    (N'STU031', N'Yassin', N'Hassan', N'student031@university.edu', N'student031.personal@gmail.com', N'stu123', N'0112000031', N'MAI', 4, N'ACTIVE'),
    (N'STU032', N'Hana', N'Fouad', N'student032@university.edu', N'student032.personal@gmail.com', N'stu123', N'0112000032', N'MPSC', 4, N'ACTIVE'),
    (N'STU033', N'Eyad', N'Mansour', N'student033@university.edu', N'student033.personal@gmail.com', N'stu123', N'0112000033', N'MMLS', 3, N'ACTIVE'),
    (N'STU034', N'Lara', N'Shawky', N'student034@university.edu', N'student034.personal@gmail.com', N'stu123', N'0112000034', N'MCPH', 5, N'ACTIVE'),
    (N'STU035', N'Fares', N'Maher', N'student035@university.edu', N'student035.personal@gmail.com', N'stu123', N'0112000035', N'MDSG', 4, N'ACTIVE'),
    (N'STU036', N'Maya', N'Amin', N'student036@university.edu', N'student036.personal@gmail.com', N'stu123', N'0112000036', N'MELC', 4, N'ACTIVE'),
    (N'STU037', N'Ali', N'Rashad', N'student037@university.edu', N'student037.personal@gmail.com', N'stu123', N'0112000037', N'MMBS', 1, N'ACTIVE'),
    (N'STU038', N'Nadine', N'Samir', N'student038@university.edu', N'student038.personal@gmail.com', N'stu123', N'0112000038', N'MDS', 2, N'ACTIVE'),
    (N'STU039', N'Khaled', N'Younes', N'student039@university.edu', N'student039.personal@gmail.com', N'stu123', N'0112000039', N'MNUR', 7, N'ACTIVE'),
    (N'STU040', N'Reem', N'Ahmed', N'student040@university.edu', N'student040.personal@gmail.com', N'stu123', N'0112000040', N'MNUR', 4, N'ACTIVE'),
    (N'STU041', N'Adam', N'Hassan', N'student041@university.edu', N'student041.personal@gmail.com', N'stu123', N'0112000041', N'MAI', 4, N'ACTIVE'),
    (N'STU042', N'Sara', N'Fouad', N'student042@university.edu', N'student042.personal@gmail.com', N'stu123', N'0112000042', N'MSE', 5, N'ACTIVE'),
    (N'STU043', N'Omar', N'Mansour', N'student043@university.edu', N'student043.personal@gmail.com', N'stu123', N'0112000043', N'MDS', 1, N'ACTIVE'),
    (N'STU044', N'Nour', N'Shawky', N'student044@university.edu', N'student044.personal@gmail.com', N'stu123', N'0112000044', N'MAI', 5, N'ACTIVE'),
    (N'STU045', N'Youssef', N'Maher', N'student045@university.edu', N'student045.personal@gmail.com', N'stu123', N'0112000045', N'MDS', 4, N'ACTIVE'),
    (N'STU046', N'Laila', N'Amin', N'student046@university.edu', N'student046.personal@gmail.com', N'stu123', N'0112000046', N'MEMT', 4, N'ACTIVE'),
    (N'STU047', N'Karim', N'Rashad', N'student047@university.edu', N'student047.personal@gmail.com', N'stu123', N'0112000047', N'MMKT', 1, N'ACTIVE'),
    (N'STU048', N'Salma', N'Samir', N'student048@university.edu', N'student048.personal@gmail.com', N'stu123', N'0112000048', N'MEMT', 3, N'ACTIVE'),
    (N'STU049', N'Hassan', N'Younes', N'student049@university.edu', N'student049.personal@gmail.com', N'stu123', N'0112000049', N'MDSG', 3, N'ACTIVE'),
    (N'STU050', N'Dina', N'Ahmed', N'student050@university.edu', N'student050.personal@gmail.com', N'stu123', N'0112000050', N'MPHD', 7, N'ACTIVE'),
    (N'STU051', N'Mostafa', N'Hassan', N'student051@university.edu', N'student051.personal@gmail.com', N'stu123', N'0112000051', N'MMEC', 4, N'ACTIVE'),
    (N'STU052', N'Farida', N'Fouad', N'student052@university.edu', N'student052.personal@gmail.com', N'stu123', N'0112000052', N'MMKT', 4, N'ACTIVE'),
    (N'STU053', N'Tarek', N'Mansour', N'student053@university.edu', N'student053.personal@gmail.com', N'stu123', N'0112000053', N'MBIS', 5, N'ACTIVE'),
    (N'STU054', N'Heba', N'Shawky', N'student054@university.edu', N'student054.personal@gmail.com', N'stu123', N'0112000054', N'MCY', 5, N'ACTIVE'),
    (N'STU055', N'Mahmoud', N'Maher', N'student055@university.edu', N'student055.personal@gmail.com', N'stu123', N'0112000055', N'MRAD', 7, N'ACTIVE'),
    (N'STU056', N'Yara', N'Amin', N'student056@university.edu', N'student056.personal@gmail.com', N'stu123', N'0112000056', N'MCIV', 5, N'ACTIVE'),
    (N'STU057', N'Amr', N'Rashad', N'student057@university.edu', N'student057.personal@gmail.com', N'stu123', N'0112000057', N'MCS', 2, N'ACTIVE'),
    (N'STU058', N'Nada', N'Samir', N'student058@university.edu', N'student058.personal@gmail.com', N'stu123', N'0112000058', N'MFIN', 4, N'ACTIVE'),
    (N'STU059', N'Sherif', N'Younes', N'student059@university.edu', N'student059.personal@gmail.com', N'stu123', N'0112000059', N'MCS', 2, N'ACTIVE'),
    (N'STU060', N'Rana', N'Ahmed', N'student060@university.edu', N'student060.personal@gmail.com', N'stu123', N'0112000060', N'MODM', 3, N'ACTIVE'),
    (N'STU061', N'Hady', N'Hassan', N'student061@university.edu', N'student061.personal@gmail.com', N'stu123', N'0112000061', N'MINT', 4, N'ACTIVE'),
    (N'STU062', N'Mariam', N'Fouad', N'student062@university.edu', N'student062.personal@gmail.com', N'stu123', N'0112000062', N'MBIS', 4, N'ACTIVE'),
    (N'STU063', N'Aly', N'Mansour', N'student063@university.edu', N'student063.personal@gmail.com', N'stu123', N'0112000063', N'MINT', 1, N'ACTIVE'),
    (N'STU064', N'Jana', N'Shawky', N'student064@university.edu', N'student064.personal@gmail.com', N'stu123', N'0112000064', N'MRTV', 4, N'ACTIVE'),
    (N'STU065', N'Mazen', N'Maher', N'student065@university.edu', N'student065.personal@gmail.com', N'stu123', N'0112000065', N'MCPH', 3, N'ACTIVE'),
    (N'STU066', N'Malak', N'Amin', N'student066@university.edu', N'student066.personal@gmail.com', N'stu123', N'0112000066', N'MDSG', 6, N'ACTIVE'),
    (N'STU067', N'Seif', N'Rashad', N'student067@university.edu', N'student067.personal@gmail.com', N'stu123', N'0112000067', N'MCPH', 6, N'ACTIVE'),
    (N'STU068', N'Judy', N'Samir', N'student068@university.edu', N'student068.personal@gmail.com', N'stu123', N'0112000068', N'MDSG', 7, N'ACTIVE'),
    (N'STU069', N'Ziad', N'Younes', N'student069@university.edu', N'student069.personal@gmail.com', N'stu123', N'0112000069', N'MACC', 4, N'ACTIVE'),
    (N'STU070', N'Habiba', N'Ahmed', N'student070@university.edu', N'student070.personal@gmail.com', N'stu123', N'0112000070', N'MDSG', 6, N'ACTIVE'),
    (N'STU071', N'Yassin', N'Hassan', N'student071@university.edu', N'student071.personal@gmail.com', N'stu123', N'0112000071', N'MPHD', 2, N'ACTIVE'),
    (N'STU072', N'Hana', N'Fouad', N'student072@university.edu', N'student072.personal@gmail.com', N'stu123', N'0112000072', N'MRAD', 7, N'ACTIVE'),
    (N'STU073', N'Eyad', N'Mansour', N'student073@university.edu', N'student073.personal@gmail.com', N'stu123', N'0112000073', N'MDSG', 4, N'ACTIVE'),
    (N'STU074', N'Lara', N'Shawky', N'student074@university.edu', N'student074.personal@gmail.com', N'stu123', N'0112000074', N'MCS', 2, N'ACTIVE'),
    (N'STU075', N'Fares', N'Maher', N'student075@university.edu', N'student075.personal@gmail.com', N'stu123', N'0112000075', N'MGRA', 5, N'ACTIVE'),
    (N'STU076', N'Maya', N'Amin', N'student076@university.edu', N'student076.personal@gmail.com', N'stu123', N'0112000076', N'MDM', 5, N'ACTIVE'),
    (N'STU077', N'Ali', N'Rashad', N'student077@university.edu', N'student077.personal@gmail.com', N'stu123', N'0112000077', N'MFIN', 1, N'ACTIVE'),
    (N'STU078', N'Nadine', N'Samir', N'student078@university.edu', N'student078.personal@gmail.com', N'stu123', N'0112000078', N'MFIN', 4, N'ACTIVE'),
    (N'STU079', N'Khaled', N'Younes', N'student079@university.edu', N'student079.personal@gmail.com', N'stu123', N'0112000079', N'MDSG', 5, N'ACTIVE'),
    (N'STU080', N'Reem', N'Ahmed', N'student080@university.edu', N'student080.personal@gmail.com', N'stu123', N'0112000080', N'MCIV', 5, N'ACTIVE');
GO

-- ============================================================
-- 4. ROOMS & TIME SLOTS
-- ============================================================

INSERT INTO dbo.rooms (room_id, building, capacity, room_type) VALUES
    (N'L001', N'Technology Building A', 40, N'LECTURE'),
    (N'L002', N'Technology Building A', 40, N'LECTURE'),
    (N'L003', N'Technology Building A', 90, N'LECTURE'),
    (N'L004', N'Engineering Complex', 50, N'LECTURE'),
    (N'L005', N'Engineering Complex', 45, N'LECTURE'),
    (N'L006', N'Engineering Complex', 70, N'LECTURE'),
    (N'L007', N'Medical Sciences Building', 45, N'LECTURE'),
    (N'L008', N'Medical Sciences Building', 40, N'LECTURE'),
    (N'L009', N'Medical Sciences Building', 90, N'LECTURE'),
    (N'L010', N'Clinical Sciences Building', 40, N'LECTURE'),
    (N'L011', N'Clinical Sciences Building', 60, N'LECTURE'),
    (N'L012', N'Clinical Sciences Building', 70, N'LECTURE'),
    (N'L013', N'Business Building', 40, N'LECTURE'),
    (N'L014', N'Business Building', 40, N'LECTURE'),
    (N'L015', N'Dental Clinics Building', 45, N'LECTURE'),
    (N'L016', N'Dental Clinics Building', 45, N'LECTURE'),
    (N'L017', N'Design Studios Building', 40, N'LECTURE'),
    (N'L018', N'Design Studios Building', 45, N'LECTURE'),
    (N'L019', N'Media Center', 60, N'LECTURE'),
    (N'L020', N'Media Center', 45, N'LECTURE'),
    (N'LAB001', N'Technology Building A', 30, N'LAB'),
    (N'LAB002', N'Technology Building A', 28, N'LAB'),
    (N'LAB003', N'Engineering Complex', 22, N'LAB'),
    (N'LAB004', N'Engineering Complex', 24, N'LAB'),
    (N'LAB005', N'Medical Sciences Building', 30, N'LAB'),
    (N'LAB006', N'Medical Sciences Building', 28, N'LAB'),
    (N'LAB007', N'Clinical Sciences Building', 28, N'LAB'),
    (N'LAB008', N'Clinical Sciences Building', 24, N'LAB'),
    (N'LAB009', N'Business Building', 24, N'LAB'),
    (N'LAB010', N'Dental Clinics Building', 28, N'LAB'),
    (N'LAB011', N'Dental Clinics Building', 22, N'LAB'),
    (N'LAB012', N'Design Studios Building', 22, N'LAB'),
    (N'LAB013', N'Media Center', 30, N'LAB');
GO

INSERT INTO dbo.time_slots (slot_id, start_time, end_time) VALUES
    (1, '08:30', '10:00'),
    (2, '10:15', '11:45'),
    (3, '12:00', '13:30'),
    (4, '13:45', '15:15'),
    (5, '15:30', '17:00'),
    (6, '17:15', '18:45');
GO

-- ============================================================
-- 5. REGISTRATION PERIODS & ASSESSMENT COMPONENTS
-- ============================================================

INSERT INTO dbo.registration_periods (term, academic_year, add_start_date, add_end_date, drop_end_date, status) VALUES
    (N'TERM2', 2025, '2025-02-01', '2025-02-20', '2025-03-15', N'CLOSED'),
    (N'SUMMER', 2025, '2025-06-01', '2025-06-10', '2025-06-20', N'CLOSED'),
    (N'TERM1', 2026, '2026-01-01', '2026-12-31', '2026-12-31', N'OPEN'),
    (N'TERM2', 2026, '2026-09-01', '2026-09-15', '2026-10-01', N'CLOSED');
GO

INSERT INTO dbo.assessment_components (component_code, component_name, week_no, category, max_marks, display_order) VALUES
    (N'W7_LEC', N'Week 7 Lecture Assessment', 7, N'MIDTERM_1', 20.0, 1),
    (N'W7_SEC', N'Week 7 Section Assessment', 7, N'MIDTERM_1', 10.0, 2),
    (N'W12_LEC', N'Week 12 Lecture Assessment', 12, N'MIDTERM_2', 15.0, 3),
    (N'W12_SEC', N'Week 12 Section Assessment', 12, N'MIDTERM_2', 5.0, 4),
    (N'CW', N'Coursework', NULL, N'COURSEWORK', 10.0, 5),
    (N'FINAL', N'Final Exam', NULL, N'FINAL', 40.0, 6);
GO

-- ============================================================
-- 6. COURSES & PREREQUISITES
-- ============================================================

INSERT INTO dbo.courses (course_id, course_name, description, department_id, credits) VALUES
    (N'CS101', N'Introduction to Programming', N'Programming fundamentals, problem solving, variables, control flow, and basic algorithms.', N'DCS', 3),
    (N'CS102', N'Object-Oriented Programming', N'Classes, objects, inheritance, polymorphism, encapsulation, and software modularity.', N'DCS', 3),
    (N'CS201', N'Data Structures', N'Arrays, linked lists, stacks, queues, trees, heaps, hashing, and algorithmic efficiency.', N'DCS', 4),
    (N'CS202', N'Database Systems', N'Relational modeling, SQL, normalization, indexing, transactions, and database application development.', N'DCS', 3),
    (N'CS301', N'Operating Systems', N'Processes, threads, CPU scheduling, memory management, file systems, and synchronization.', N'DCS', 3),
    (N'CS302', N'Computer Networks', N'Network models, TCP/IP, routing, switching, transport protocols, and network security basics.', N'DCS', 3),
    (N'CS401', N'Artificial Intelligence', N'Search, knowledge representation, machine learning basics, planning, and intelligent agents.', N'DCS', 3),
    (N'CS405', N'Cybersecurity Fundamentals', N'Security principles, cryptography basics, network attacks, access control, and risk management.', N'DCS', 3),
    (N'ENG101', N'Engineering Mathematics', N'Calculus, linear algebra, and mathematical methods for engineering applications.', N'DENG', 3),
    (N'ENG102', N'Engineering Physics', N'Mechanics, waves, electricity, magnetism, and lab-based physical measurements.', N'DENG', 4),
    (N'ENG201', N'Thermodynamics', N'Energy, heat transfer, thermodynamic cycles, properties of substances, and applications.', N'DENG', 3),
    (N'ENG202', N'Circuit Analysis', N'DC and AC circuit analysis, network theorems, circuit components, and measurement labs.', N'DENG', 3),
    (N'ENG301', N'Structural Engineering', N'Structural loads, materials, beams, columns, and design principles.', N'DENG', 4),
    (N'ENG305', N'Control Systems', N'Feedback systems, stability, transfer functions, controllers, and system response.', N'DENG', 3),
    (N'PH101', N'Human Anatomy', N'Human body systems, organs, anatomical terminology, and clinical relevance.', N'DPHR', 4),
    (N'PH102', N'Organic Chemistry', N'Organic compounds, reactions, functional groups, stereochemistry, and pharmaceutical applications.', N'DPHR', 4),
    (N'PH201', N'Pharmacology', N'Drug mechanisms, pharmacokinetics, pharmacodynamics, therapeutic classes, and safety.', N'DPHR', 5),
    (N'PH301', N'Clinical Pharmacy', N'Patient-centered pharmacy practice, medication review, dosing, interactions, and clinical care.', N'DPHR', 5),
    (N'PH401', N'Pharmaceutical Quality Control', N'Drug quality, stability, testing, manufacturing standards, and regulatory quality systems.', N'DPHR', 4),
    (N'MED101', N'Medical Biology', N'Cell biology, genetics, tissues, and biological foundations for health sciences.', N'DMED', 4),
    (N'MED102', N'Human Physiology', N'Functions of human body systems and mechanisms of homeostasis.', N'DMED', 4),
    (N'MED201', N'Pathology Basics', N'Disease mechanisms, inflammation, cellular injury, neoplasia, and clinical examples.', N'DMED', 4),
    (N'MED301', N'Clinical Skills', N'Patient communication, examination basics, clinical reasoning, and documentation.', N'DMED', 5),
    (N'MED401', N'Community Medicine', N'Public health, epidemiology, preventive medicine, and population health management.', N'DMED', 4),
    (N'BUS101', N'Principles of Management', N'Planning, organizing, leadership, control, organizational behavior, and business ethics.', N'DBUS', 3),
    (N'ACC201', N'Financial Accounting', N'Accounting cycle, financial statements, assets, liabilities, equity, and reporting principles.', N'DBUS', 3),
    (N'FIN201', N'Corporate Finance', N'Time value of money, investment decisions, capital structure, and financial analysis.', N'DBUS', 3),
    (N'MKT201', N'Marketing Management', N'Market research, consumer behavior, segmentation, positioning, and marketing strategy.', N'DBUS', 3),
    (N'BIS301', N'Business Information Systems', N'Business processes, ERP concepts, analytics, information systems, and digital transformation.', N'DBUS', 3),
    (N'DEN101', N'Dental Anatomy', N'Tooth morphology, oral structures, dental terminology, and clinical identification.', N'DDEN', 4),
    (N'DEN201', N'Oral Histology', N'Oral tissues, development, microscopic anatomy, and dental tissue structure.', N'DDEN', 4),
    (N'DEN301', N'Operative Dentistry', N'Cavity preparation, restorative materials, clinical techniques, and patient care.', N'DDEN', 5),
    (N'DEN401', N'Oral Surgery', N'Minor oral surgery, extraction principles, complications, and clinical surgical protocols.', N'DDEN', 5),
    (N'ART101', N'Design Fundamentals', N'Visual elements, composition, color theory, typography basics, and creative process.', N'DART', 3),
    (N'DES201', N'Digital Illustration', N'Vector illustration, digital drawing workflow, design assets, and visual storytelling.', N'DART', 3),
    (N'DGM201', N'Digital Media Production', N'Digital content planning, video basics, audio, editing, and online publishing.', N'DART', 3),
    (N'ANI301', N'Animation Principles', N'Motion principles, storyboarding, timing, character animation, and production workflow.', N'DART', 3),
    (N'MCM101', N'Introduction to Mass Communication', N'Media systems, communication theories, audience studies, and media ethics.', N'DMCM', 3),
    (N'JRN201', N'News Writing and Reporting', N'News values, reporting, interviewing, writing structure, verification, and newsroom practice.', N'DMCM', 3),
    (N'PR301', N'Public Relations Campaigns', N'PR planning, media relations, crisis communication, campaign strategy, and evaluation.', N'DMCM', 3);
GO

INSERT INTO dbo.course_prerequisites (course_id, prerequisite_id) VALUES
    (N'CS102', N'CS101'),
    (N'CS201', N'CS102'),
    (N'CS202', N'CS102'),
    (N'CS301', N'CS201'),
    (N'CS302', N'CS202'),
    (N'CS401', N'CS202'),
    (N'CS405', N'CS301'),
    (N'ENG201', N'ENG101'),
    (N'ENG202', N'ENG102'),
    (N'ENG301', N'ENG201'),
    (N'ENG305', N'ENG202'),
    (N'PH201', N'PH102'),
    (N'PH301', N'PH201'),
    (N'PH401', N'PH301'),
    (N'MED201', N'MED102'),
    (N'MED301', N'MED201'),
    (N'MED401', N'MED301'),
    (N'ACC201', N'BUS101'),
    (N'FIN201', N'BUS101'),
    (N'MKT201', N'BUS101'),
    (N'BIS301', N'BUS101'),
    (N'DEN201', N'DEN101'),
    (N'DEN301', N'DEN201'),
    (N'DEN401', N'DEN301'),
    (N'DES201', N'ART101'),
    (N'DGM201', N'ART101'),
    (N'ANI301', N'DGM201'),
    (N'JRN201', N'MCM101'),
    (N'PR301', N'MCM101');
GO

-- ============================================================
-- 7. COURSE OFFERINGS, TEACHING ROLES & SCHEDULES
-- ============================================================

INSERT INTO dbo.course_offerings (offering_id, course_id, term, academic_year, section_code, capacity, status) VALUES
    (N'OFF001', N'CS101', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF002', N'CS102', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF003', N'CS201', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF004', N'CS202', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF005', N'ENG101', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF006', N'ENG102', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF007', N'ENG201', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF008', N'PH101', N'TERM2', 2025, N'H01', 35, N'COMPLETED'),
    (N'OFF009', N'PH102', N'TERM2', 2025, N'H01', 35, N'COMPLETED'),
    (N'OFF010', N'MED101', N'TERM2', 2025, N'H01', 35, N'COMPLETED'),
    (N'OFF011', N'MED102', N'TERM2', 2025, N'H01', 35, N'COMPLETED'),
    (N'OFF012', N'BUS101', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF013', N'DEN101', N'TERM2', 2025, N'H01', 35, N'COMPLETED'),
    (N'OFF014', N'ART101', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF015', N'MCM101', N'TERM2', 2025, N'H01', 45, N'COMPLETED'),
    (N'OFF016', N'CS101', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF017', N'CS102', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF018', N'CS201', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF019', N'CS202', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF020', N'CS301', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF021', N'CS302', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF022', N'CS401', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF023', N'CS405', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF024', N'ENG101', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF025', N'ENG102', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF026', N'ENG201', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF027', N'ENG202', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF028', N'ENG301', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF029', N'ENG305', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF030', N'PH101', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF031', N'PH102', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF032', N'PH201', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF033', N'PH301', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF034', N'PH401', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF035', N'MED101', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF036', N'MED102', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF037', N'MED201', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF038', N'MED301', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF039', N'MED401', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF040', N'BUS101', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF041', N'ACC201', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF042', N'FIN201', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF043', N'MKT201', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF044', N'BIS301', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF045', N'DEN101', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF046', N'DEN201', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF047', N'DEN301', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF048', N'DEN401', N'TERM1', 2026, N'L01', 35, N'OPEN'),
    (N'OFF049', N'ART101', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF050', N'DES201', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF051', N'DGM201', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF052', N'ANI301', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF053', N'MCM101', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF054', N'JRN201', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF055', N'PR301', N'TERM1', 2026, N'L01', 45, N'OPEN'),
    (N'OFF056', N'CS101', N'TERM1', 2026, N'L02', 45, N'OPEN'),
    (N'OFF057', N'CS102', N'TERM1', 2026, N'L02', 45, N'OPEN'),
    (N'OFF058', N'BUS101', N'TERM1', 2026, N'L02', 45, N'OPEN'),
    (N'OFF059', N'MED101', N'TERM1', 2026, N'L02', 45, N'OPEN'),
    (N'OFF060', N'ENG101', N'TERM1', 2026, N'L02', 45, N'OPEN');
GO

INSERT INTO dbo.course_instructors (offering_id, instructor_id, role) VALUES
    (N'OFF001', N'INS001', N'LECTURE'),
    (N'OFF002', N'INS001', N'LECTURE'),
    (N'OFF003', N'INS001', N'LECTURE'),
    (N'OFF003', N'INS003', N'LAB'),
    (N'OFF004', N'INS001', N'LECTURE'),
    (N'OFF005', N'INS004', N'LECTURE'),
    (N'OFF006', N'INS005', N'LECTURE'),
    (N'OFF006', N'INS006', N'LAB'),
    (N'OFF007', N'INS004', N'LECTURE'),
    (N'OFF008', N'INS007', N'LECTURE'),
    (N'OFF008', N'INS009', N'ASSISTANT'),
    (N'OFF009', N'INS007', N'LECTURE'),
    (N'OFF009', N'INS009', N'ASSISTANT'),
    (N'OFF010', N'INS011', N'LECTURE'),
    (N'OFF010', N'INS012', N'ASSISTANT'),
    (N'OFF011', N'INS011', N'LECTURE'),
    (N'OFF011', N'INS012', N'ASSISTANT'),
    (N'OFF012', N'INS014', N'LECTURE'),
    (N'OFF012', N'INS015', N'ASSISTANT'),
    (N'OFF013', N'INS016', N'LECTURE'),
    (N'OFF013', N'INS018', N'ASSISTANT'),
    (N'OFF014', N'INS019', N'LECTURE'),
    (N'OFF015', N'INS023', N'LECTURE'),
    (N'OFF016', N'INS002', N'LECTURE'),
    (N'OFF017', N'INS001', N'LECTURE'),
    (N'OFF018', N'INS001', N'LECTURE'),
    (N'OFF018', N'INS003', N'LAB'),
    (N'OFF019', N'INS001', N'LECTURE'),
    (N'OFF020', N'INS002', N'LECTURE'),
    (N'OFF021', N'INS001', N'LECTURE'),
    (N'OFF022', N'INS001', N'LECTURE'),
    (N'OFF023', N'INS002', N'LECTURE'),
    (N'OFF024', N'INS005', N'LECTURE'),
    (N'OFF025', N'INS005', N'LECTURE'),
    (N'OFF025', N'INS006', N'LAB'),
    (N'OFF026', N'INS004', N'LECTURE'),
    (N'OFF027', N'INS004', N'LECTURE'),
    (N'OFF028', N'INS004', N'LECTURE'),
    (N'OFF028', N'INS006', N'LAB'),
    (N'OFF029', N'INS004', N'LECTURE'),
    (N'OFF030', N'INS007', N'LECTURE'),
    (N'OFF030', N'INS009', N'ASSISTANT'),
    (N'OFF031', N'INS007', N'LECTURE'),
    (N'OFF031', N'INS009', N'ASSISTANT'),
    (N'OFF032', N'INS007', N'LECTURE'),
    (N'OFF032', N'INS009', N'LAB'),
    (N'OFF033', N'INS007', N'LECTURE'),
    (N'OFF033', N'INS009', N'LAB'),
    (N'OFF034', N'INS007', N'LECTURE'),
    (N'OFF034', N'INS009', N'ASSISTANT'),
    (N'OFF035', N'INS011', N'LECTURE'),
    (N'OFF035', N'INS012', N'ASSISTANT'),
    (N'OFF036', N'INS010', N'LECTURE'),
    (N'OFF036', N'INS012', N'ASSISTANT'),
    (N'OFF037', N'INS010', N'LECTURE'),
    (N'OFF037', N'INS012', N'ASSISTANT'),
    (N'OFF038', N'INS010', N'LECTURE'),
    (N'OFF038', N'INS012', N'LAB'),
    (N'OFF039', N'INS011', N'LECTURE'),
    (N'OFF039', N'INS012', N'ASSISTANT'),
    (N'OFF040', N'INS013', N'LECTURE'),
    (N'OFF040', N'INS015', N'ASSISTANT'),
    (N'OFF041', N'INS013', N'LECTURE'),
    (N'OFF042', N'INS014', N'LECTURE'),
    (N'OFF043', N'INS013', N'LECTURE'),
    (N'OFF044', N'INS014', N'LECTURE'),
    (N'OFF044', N'INS015', N'ASSISTANT'),
    (N'OFF045', N'INS016', N'LECTURE'),
    (N'OFF045', N'INS018', N'ASSISTANT'),
    (N'OFF046', N'INS017', N'LECTURE'),
    (N'OFF046', N'INS018', N'ASSISTANT'),
    (N'OFF047', N'INS017', N'LECTURE'),
    (N'OFF047', N'INS018', N'LAB'),
    (N'OFF048', N'INS016', N'LECTURE'),
    (N'OFF048', N'INS018', N'LAB'),
    (N'OFF049', N'INS020', N'LECTURE'),
    (N'OFF050', N'INS019', N'LECTURE'),
    (N'OFF050', N'INS021', N'LAB'),
    (N'OFF051', N'INS019', N'LECTURE'),
    (N'OFF051', N'INS021', N'LAB'),
    (N'OFF052', N'INS020', N'LECTURE'),
    (N'OFF052', N'INS021', N'LAB'),
    (N'OFF053', N'INS022', N'LECTURE'),
    (N'OFF054', N'INS022', N'LECTURE'),
    (N'OFF055', N'INS023', N'LECTURE'),
    (N'OFF056', N'INS002', N'LECTURE'),
    (N'OFF057', N'INS001', N'LECTURE'),
    (N'OFF058', N'INS014', N'LECTURE'),
    (N'OFF058', N'INS015', N'ASSISTANT'),
    (N'OFF059', N'INS011', N'LECTURE'),
    (N'OFF059', N'INS012', N'ASSISTANT'),
    (N'OFF060', N'INS004', N'LECTURE');
GO

INSERT INTO dbo.room_schedule (offering_id, room_id, instructor_id, day_of_week, slot_id, meeting_type) VALUES
    (N'OFF001', N'L009', N'INS001', N'Monday', 5, N'LECTURE'),
    (N'OFF002', N'L013', N'INS001', N'Wednesday', 1, N'LECTURE'),
    (N'OFF003', N'L012', N'INS001', N'Thursday', 5, N'LECTURE'),
    (N'OFF003', N'LAB012', N'INS003', N'Wednesday', 2, N'LAB'),
    (N'OFF004', N'L010', N'INS001', N'Thursday', 2, N'LECTURE'),
    (N'OFF005', N'L009', N'INS004', N'Saturday', 4, N'LECTURE'),
    (N'OFF006', N'L012', N'INS005', N'Sunday', 3, N'LECTURE'),
    (N'OFF006', N'LAB005', N'INS006', N'Sunday', 6, N'LAB'),
    (N'OFF007', N'L008', N'INS004', N'Wednesday', 6, N'LECTURE'),
    (N'OFF008', N'L018', N'INS007', N'Tuesday', 3, N'LECTURE'),
    (N'OFF008', N'L011', N'INS009', N'Sunday', 6, N'SECTION'),
    (N'OFF009', N'L013', N'INS007', N'Saturday', 3, N'LECTURE'),
    (N'OFF009', N'L007', N'INS009', N'Monday', 1, N'SECTION'),
    (N'OFF010', N'L013', N'INS011', N'Thursday', 4, N'LECTURE'),
    (N'OFF010', N'L005', N'INS012', N'Saturday', 1, N'SECTION'),
    (N'OFF011', N'L018', N'INS011', N'Sunday', 6, N'LECTURE'),
    (N'OFF011', N'L019', N'INS012', N'Wednesday', 3, N'SECTION'),
    (N'OFF012', N'L005', N'INS014', N'Monday', 2, N'LECTURE'),
    (N'OFF012', N'L003', N'INS015', N'Wednesday', 4, N'SECTION'),
    (N'OFF013', N'L006', N'INS016', N'Sunday', 6, N'LECTURE'),
    (N'OFF013', N'L020', N'INS018', N'Thursday', 4, N'SECTION'),
    (N'OFF014', N'L015', N'INS019', N'Tuesday', 5, N'LECTURE'),
    (N'OFF015', N'L004', N'INS023', N'Thursday', 6, N'LECTURE'),
    (N'OFF016', N'L014', N'INS002', N'Saturday', 3, N'LECTURE'),
    (N'OFF017', N'L009', N'INS001', N'Saturday', 6, N'LECTURE'),
    (N'OFF018', N'L017', N'INS001', N'Thursday', 3, N'LECTURE'),
    (N'OFF018', N'LAB009', N'INS003', N'Monday', 2, N'LAB'),
    (N'OFF019', N'L004', N'INS001', N'Tuesday', 1, N'LECTURE'),
    (N'OFF020', N'L008', N'INS002', N'Sunday', 1, N'LECTURE'),
    (N'OFF021', N'L003', N'INS001', N'Thursday', 4, N'LECTURE'),
    (N'OFF022', N'L017', N'INS001', N'Sunday', 3, N'LECTURE'),
    (N'OFF023', N'L007', N'INS002', N'Wednesday', 6, N'LECTURE'),
    (N'OFF024', N'L012', N'INS005', N'Thursday', 6, N'LECTURE'),
    (N'OFF025', N'L008', N'INS005', N'Saturday', 2, N'LECTURE'),
    (N'OFF025', N'LAB001', N'INS006', N'Saturday', 3, N'LAB'),
    (N'OFF026', N'L002', N'INS004', N'Saturday', 1, N'LECTURE'),
    (N'OFF027', N'L003', N'INS004', N'Saturday', 3, N'LECTURE'),
    (N'OFF028', N'L007', N'INS004', N'Thursday', 4, N'LECTURE'),
    (N'OFF028', N'LAB008', N'INS006', N'Wednesday', 5, N'LAB'),
    (N'OFF029', N'L004', N'INS004', N'Tuesday', 2, N'LECTURE'),
    (N'OFF030', N'L014', N'INS007', N'Monday', 4, N'LECTURE'),
    (N'OFF030', N'L002', N'INS009', N'Tuesday', 6, N'SECTION'),
    (N'OFF031', N'L011', N'INS007', N'Tuesday', 6, N'LECTURE'),
    (N'OFF031', N'L007', N'INS009', N'Saturday', 2, N'SECTION'),
    (N'OFF032', N'L006', N'INS007', N'Sunday', 4, N'LECTURE'),
    (N'OFF032', N'LAB004', N'INS009', N'Monday', 4, N'LAB'),
    (N'OFF033', N'L002', N'INS007', N'Wednesday', 1, N'LECTURE'),
    (N'OFF033', N'LAB001', N'INS009', N'Thursday', 5, N'LAB'),
    (N'OFF034', N'L013', N'INS007', N'Tuesday', 2, N'LECTURE'),
    (N'OFF034', N'L014', N'INS009', N'Tuesday', 3, N'SECTION'),
    (N'OFF035', N'L007', N'INS011', N'Sunday', 3, N'LECTURE'),
    (N'OFF035', N'L018', N'INS012', N'Saturday', 5, N'SECTION'),
    (N'OFF036', N'L019', N'INS010', N'Saturday', 1, N'LECTURE'),
    (N'OFF036', N'L017', N'INS012', N'Tuesday', 5, N'SECTION'),
    (N'OFF037', N'L006', N'INS010', N'Wednesday', 1, N'LECTURE'),
    (N'OFF037', N'L013', N'INS012', N'Thursday', 2, N'SECTION'),
    (N'OFF038', N'L002', N'INS010', N'Wednesday', 5, N'LECTURE'),
    (N'OFF038', N'LAB007', N'INS012', N'Wednesday', 1, N'LAB'),
    (N'OFF039', N'L003', N'INS011', N'Tuesday', 3, N'LECTURE'),
    (N'OFF039', N'L020', N'INS012', N'Saturday', 4, N'SECTION'),
    (N'OFF040', N'L017', N'INS013', N'Wednesday', 2, N'LECTURE'),
    (N'OFF040', N'L012', N'INS015', N'Monday', 2, N'SECTION'),
    (N'OFF041', N'L006', N'INS013', N'Monday', 3, N'LECTURE'),
    (N'OFF042', N'L017', N'INS014', N'Wednesday', 6, N'LECTURE'),
    (N'OFF043', N'L005', N'INS013', N'Thursday', 1, N'LECTURE'),
    (N'OFF044', N'L018', N'INS014', N'Saturday', 6, N'LECTURE'),
    (N'OFF044', N'L010', N'INS015', N'Sunday', 3, N'SECTION'),
    (N'OFF045', N'L009', N'INS016', N'Wednesday', 4, N'LECTURE'),
    (N'OFF045', N'L014', N'INS018', N'Saturday', 1, N'SECTION'),
    (N'OFF046', N'L005', N'INS017', N'Saturday', 3, N'LECTURE'),
    (N'OFF046', N'L006', N'INS018', N'Thursday', 3, N'SECTION'),
    (N'OFF047', N'L004', N'INS017', N'Wednesday', 1, N'LECTURE'),
    (N'OFF047', N'LAB003', N'INS018', N'Saturday', 6, N'LAB'),
    (N'OFF048', N'L005', N'INS016', N'Wednesday', 5, N'LECTURE'),
    (N'OFF048', N'LAB001', N'INS018', N'Tuesday', 2, N'LAB'),
    (N'OFF049', N'L007', N'INS020', N'Saturday', 3, N'LECTURE'),
    (N'OFF050', N'L014', N'INS019', N'Monday', 5, N'LECTURE'),
    (N'OFF050', N'LAB003', N'INS021', N'Wednesday', 6, N'LAB'),
    (N'OFF051', N'L001', N'INS019', N'Sunday', 4, N'LECTURE'),
    (N'OFF051', N'LAB006', N'INS021', N'Sunday', 6, N'LAB'),
    (N'OFF052', N'L004', N'INS020', N'Monday', 2, N'LECTURE'),
    (N'OFF052', N'LAB008', N'INS021', N'Tuesday', 1, N'LAB'),
    (N'OFF053', N'L010', N'INS022', N'Tuesday', 3, N'LECTURE'),
    (N'OFF054', N'L007', N'INS022', N'Saturday', 6, N'LECTURE'),
    (N'OFF055', N'L009', N'INS023', N'Monday', 1, N'LECTURE'),
    (N'OFF056', N'L011', N'INS002', N'Thursday', 5, N'LECTURE'),
    (N'OFF057', N'L019', N'INS001', N'Monday', 2, N'LECTURE'),
    (N'OFF058', N'L014', N'INS014', N'Saturday', 5, N'LECTURE'),
    (N'OFF058', N'L011', N'INS015', N'Monday', 6, N'SECTION'),
    (N'OFF059', N'L007', N'INS011', N'Tuesday', 5, N'LECTURE'),
    (N'OFF059', N'L014', N'INS012', N'Monday', 1, N'SECTION'),
    (N'OFF060', N'L003', N'INS004', N'Monday', 4, N'LECTURE');
GO

-- ============================================================
-- 8. ENROLLMENTS & ASSESSMENT SCORES
-- ============================================================

INSERT INTO dbo.enrollments (enrollment_id, student_id, offering_id, enrollment_date, status) VALUES
    (N'ENR00001', N'STU001', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00002', N'STU001', N'OFF011', '2025-03-01', N'COMPLETED'),
    (N'ENR00003', N'STU002', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00004', N'STU002', N'OFF005', '2025-03-01', N'COMPLETED'),
    (N'ENR00005', N'STU003', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00006', N'STU003', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00008', N'STU004', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00009', N'STU004', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00010', N'STU005', N'OFF009', '2025-03-01', N'COMPLETED'),
    (N'ENR00011', N'STU005', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00012', N'STU005', N'OFF008', '2025-03-01', N'COMPLETED'),
    (N'ENR00013', N'STU005', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00014', N'STU006', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00015', N'STU006', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00016', N'STU006', N'OFF010', '2025-03-01', N'COMPLETED'),
    (N'ENR00017', N'STU007', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00018', N'STU007', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00019', N'STU007', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00021', N'STU008', N'OFF009', '2025-03-01', N'COMPLETED'),
    (N'ENR00022', N'STU008', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00023', N'STU008', N'OFF008', '2025-03-01', N'COMPLETED'),
    (N'ENR00025', N'STU008', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00026', N'STU009', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00027', N'STU009', N'OFF015', '2025-03-01', N'COMPLETED'),
    (N'ENR00028', N'STU010', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00030', N'STU010', N'OFF003', '2025-03-01', N'WITHDRAWN'),
    (N'ENR00031', N'STU011', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00032', N'STU011', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00034', N'STU011', N'OFF009', '2025-03-01', N'COMPLETED'),
    (N'ENR00035', N'STU011', N'OFF008', '2025-03-01', N'WITHDRAWN'),
    (N'ENR00036', N'STU012', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00037', N'STU012', N'OFF011', '2025-03-01', N'COMPLETED'),
    (N'ENR00038', N'STU012', N'OFF010', '2025-03-01', N'COMPLETED'),
    (N'ENR00039', N'STU013', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00040', N'STU013', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00041', N'STU013', N'OFF011', '2025-03-01', N'WITHDRAWN'),
    (N'ENR00042', N'STU014', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00043', N'STU014', N'OFF015', '2025-03-01', N'COMPLETED'),
    (N'ENR00044', N'STU016', N'OFF008', '2025-03-01', N'COMPLETED'),
    (N'ENR00045', N'STU016', N'OFF009', '2025-03-01', N'COMPLETED'),
    (N'ENR00046', N'STU016', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00047', N'STU016', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00048', N'STU016', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00049', N'STU017', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00050', N'STU017', N'OFF008', '2025-03-01', N'COMPLETED'),
    (N'ENR00051', N'STU018', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00054', N'STU019', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00056', N'STU019', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00058', N'STU020', N'OFF006', '2025-03-01', N'COMPLETED'),
    (N'ENR00059', N'STU020', N'OFF007', '2025-03-01', N'COMPLETED'),
    (N'ENR00060', N'STU021', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00061', N'STU021', N'OFF014', '2025-03-01', N'COMPLETED'),
    (N'ENR00062', N'STU021', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00063', N'STU022', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00066', N'STU022', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00067', N'STU024', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00068', N'STU024', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00070', N'STU025', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00071', N'STU025', N'OFF015', '2025-03-01', N'COMPLETED'),
    (N'ENR00072', N'STU026', N'OFF011', '2025-03-01', N'COMPLETED'),
    (N'ENR00073', N'STU026', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00074', N'STU026', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00075', N'STU027', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00076', N'STU027', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00078', N'STU028', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00079', N'STU028', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00080', N'STU029', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00081', N'STU029', N'OFF007', '2025-03-01', N'COMPLETED'),
    (N'ENR00082', N'STU031', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00083', N'STU031', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00086', N'STU032', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00087', N'STU032', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00089', N'STU032', N'OFF008', '2025-03-01', N'COMPLETED'),
    (N'ENR00090', N'STU033', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00091', N'STU033', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00092', N'STU034', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00093', N'STU034', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00095', N'STU034', N'OFF008', '2025-03-01', N'COMPLETED'),
    (N'ENR00097', N'STU035', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00099', N'STU035', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00100', N'STU035', N'OFF013', '2025-03-01', N'COMPLETED'),
    (N'ENR00102', N'STU036', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00103', N'STU036', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00104', N'STU036', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00105', N'STU038', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00107', N'STU038', N'OFF002', '2025-03-01', N'COMPLETED'),
    (N'ENR00108', N'STU039', N'OFF010', '2025-03-01', N'COMPLETED'),
    (N'ENR00109', N'STU039', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00110', N'STU040', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00111', N'STU040', N'OFF011', '2025-03-01', N'COMPLETED'),
    (N'ENR00113', N'STU041', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00114', N'STU041', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00116', N'STU041', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00118', N'STU042', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00119', N'STU042', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00120', N'STU042', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00122', N'STU044', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00123', N'STU044', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00124', N'STU044', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00126', N'STU045', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00127', N'STU045', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00128', N'STU045', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00131', N'STU046', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00132', N'STU046', N'OFF007', '2025-03-01', N'COMPLETED'),
    (N'ENR00133', N'STU046', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00134', N'STU048', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00135', N'STU048', N'OFF007', '2025-03-01', N'COMPLETED'),
    (N'ENR00136', N'STU048', N'OFF006', '2025-03-01', N'WITHDRAWN'),
    (N'ENR00137', N'STU049', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00139', N'STU050', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00142', N'STU051', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00144', N'STU051', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00145', N'STU052', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00146', N'STU052', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00149', N'STU052', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00150', N'STU053', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00151', N'STU053', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00152', N'STU053', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00153', N'STU054', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00154', N'STU054', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00157', N'STU055', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00158', N'STU055', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00160', N'STU055', N'OFF010', '2025-03-01', N'COMPLETED'),
    (N'ENR00161', N'STU056', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00162', N'STU056', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00163', N'STU056', N'OFF005', '2025-03-01', N'COMPLETED'),
    (N'ENR00165', N'STU057', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00166', N'STU057', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00168', N'STU058', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00169', N'STU058', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00170', N'STU059', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00171', N'STU059', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00172', N'STU060', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00173', N'STU060', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00175', N'STU060', N'OFF013', '2025-03-01', N'COMPLETED'),
    (N'ENR00176', N'STU061', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00177', N'STU061', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00178', N'STU061', N'OFF014', '2025-03-01', N'COMPLETED'),
    (N'ENR00180', N'STU062', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00181', N'STU062', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00184', N'STU062', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00185', N'STU064', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00186', N'STU064', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00187', N'STU064', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00189', N'STU064', N'OFF015', '2025-03-01', N'COMPLETED'),
    (N'ENR00190', N'STU065', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00191', N'STU065', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00193', N'STU066', N'OFF013', '2025-03-01', N'COMPLETED'),
    (N'ENR00194', N'STU066', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00197', N'STU067', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00198', N'STU067', N'OFF009', '2025-03-01', N'COMPLETED'),
    (N'ENR00200', N'STU067', N'OFF004', '2025-03-01', N'WITHDRAWN'),
    (N'ENR00201', N'STU068', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00202', N'STU068', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00203', N'STU068', N'OFF013', '2025-03-01', N'COMPLETED'),
    (N'ENR00204', N'STU068', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00206', N'STU069', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00207', N'STU069', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00209', N'STU069', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00210', N'STU070', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00211', N'STU070', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00213', N'STU070', N'OFF003', '2025-03-01', N'WITHDRAWN'),
    (N'ENR00214', N'STU071', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00215', N'STU071', N'OFF004', '2025-03-01', N'COMPLETED'),
    (N'ENR00217', N'STU071', N'OFF008', '2025-03-01', N'WITHDRAWN'),
    (N'ENR00218', N'STU072', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00219', N'STU072', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00220', N'STU073', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00221', N'STU073', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00224', N'STU074', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00225', N'STU074', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00226', N'STU074', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00227', N'STU074', N'OFF004', '2025-03-01', N'WITHDRAWN'),
    (N'ENR00228', N'STU075', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00229', N'STU075', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00230', N'STU075', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00232', N'STU076', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00233', N'STU076', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00234', N'STU076', N'OFF014', '2025-03-01', N'COMPLETED'),
    (N'ENR00237', N'STU078', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00238', N'STU078', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00239', N'STU079', N'OFF003', '2025-03-01', N'COMPLETED'),
    (N'ENR00240', N'STU079', N'OFF013', '2025-03-01', N'COMPLETED'),
    (N'ENR00242', N'STU080', N'OFF001', '2025-03-01', N'COMPLETED'),
    (N'ENR00243', N'STU080', N'OFF012', '2025-03-01', N'COMPLETED'),
    (N'ENR00247', N'STU001', N'OFF037', '2026-05-20', N'ENROLLED'),
    (N'ENR00248', N'STU001', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00249', N'STU001', N'OFF059', '2026-05-20', N'ENROLLED'),
    (N'ENR00250', N'STU002', N'OFF029', '2026-05-20', N'ENROLLED'),
    (N'ENR00251', N'STU002', N'OFF027', '2026-05-20', N'ENROLLED'),
    (N'ENR00252', N'STU002', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00253', N'STU003', N'OFF043', '2026-05-20', N'ENROLLED'),
    (N'ENR00254', N'STU003', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00255', N'STU003', N'OFF041', '2026-05-20', N'ENROLLED'),
    (N'ENR00256', N'STU004', N'OFF021', '2026-05-20', N'ENROLLED'),
    (N'ENR00257', N'STU004', N'OFF057', '2026-05-20', N'ENROLLED'),
    (N'ENR00258', N'STU004', N'OFF022', '2026-05-20', N'ENROLLED'),
    (N'ENR00259', N'STU004', N'OFF023', '2026-05-20', N'ENROLLED'),
    (N'ENR00260', N'STU005', N'OFF034', '2026-05-20', N'ENROLLED'),
    (N'ENR00261', N'STU005', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00262', N'STU005', N'OFF032', '2026-05-20', N'ENROLLED'),
    (N'ENR00263', N'STU005', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00264', N'STU006', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00265', N'STU006', N'OFF036', '2026-05-20', N'ENROLLED'),
    (N'ENR00266', N'STU006', N'OFF055', '2026-05-20', N'ENROLLED'),
    (N'ENR00267', N'STU007', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00268', N'STU007', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00269', N'STU007', N'OFF020', '2026-05-20', N'ENROLLED'),
    (N'ENR00270', N'STU007', N'OFF021', '2026-05-20', N'ENROLLED'),
    (N'ENR00271', N'STU008', N'OFF032', '2026-05-20', N'ENROLLED'),
    (N'ENR00272', N'STU008', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00273', N'STU008', N'OFF034', '2026-05-20', N'ENROLLED'),
    (N'ENR00274', N'STU008', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00275', N'STU009', N'OFF054', '2026-05-20', N'ENROLLED'),
    (N'ENR00276', N'STU009', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00277', N'STU009', N'OFF055', '2026-05-20', N'ENROLLED'),
    (N'ENR00278', N'STU010', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00279', N'STU010', N'OFF057', '2026-05-20', N'ENROLLED'),
    (N'ENR00280', N'STU010', N'OFF021', '2026-05-20', N'ENROLLED'),
    (N'ENR00281', N'STU011', N'OFF034', '2026-05-20', N'ENROLLED'),
    (N'ENR00282', N'STU011', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00283', N'STU011', N'OFF033', '2026-05-20', N'ENROLLED'),
    (N'ENR00284', N'STU011', N'OFF030', '2026-05-20', N'ENROLLED'),
    (N'ENR00285', N'STU012', N'OFF037', '2026-05-20', N'ENROLLED'),
    (N'ENR00286', N'STU012', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00287', N'STU012', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00288', N'STU013', N'OFF036', '2026-05-20', N'ENROLLED'),
    (N'ENR00289', N'STU013', N'OFF037', '2026-05-20', N'ENROLLED'),
    (N'ENR00290', N'STU013', N'OFF039', '2026-05-20', N'ENROLLED'),
    (N'ENR00291', N'STU013', N'OFF035', '2026-05-20', N'ENROLLED'),
    (N'ENR00292', N'STU014', N'OFF054', '2026-05-20', N'ENROLLED'),
    (N'ENR00293', N'STU014', N'OFF055', '2026-05-20', N'ENROLLED'),
    (N'ENR00294', N'STU014', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00295', N'STU015', N'OFF045', '2026-05-20', N'ENROLLED'),
    (N'ENR00296', N'STU015', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00297', N'STU015', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00298', N'STU015', N'OFF022', '2026-05-20', N'ENROLLED'),
    (N'ENR00299', N'STU016', N'OFF032', '2026-05-20', N'ENROLLED'),
    (N'ENR00300', N'STU016', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00301', N'STU016', N'OFF034', '2026-05-20', N'ENROLLED'),
    (N'ENR00302', N'STU017', N'OFF032', '2026-05-20', N'ENROLLED'),
    (N'ENR00303', N'STU017', N'OFF033', '2026-05-20', N'ENROLLED'),
    (N'ENR00304', N'STU017', N'OFF034', '2026-05-20', N'ENROLLED'),
    (N'ENR00305', N'STU017', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00306', N'STU018', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00307', N'STU018', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00308', N'STU018', N'OFF031', '2026-05-20', N'ENROLLED'),
    (N'ENR00309', N'STU019', N'OFF041', '2026-05-20', N'ENROLLED'),
    (N'ENR00310', N'STU019', N'OFF044', '2026-05-20', N'ENROLLED'),
    (N'ENR00311', N'STU019', N'OFF042', '2026-05-20', N'ENROLLED'),
    (N'ENR00312', N'STU020', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00313', N'STU020', N'OFF028', '2026-05-20', N'ENROLLED'),
    (N'ENR00314', N'STU020', N'OFF027', '2026-05-20', N'ENROLLED'),
    (N'ENR00315', N'STU020', N'OFF024', '2026-05-20', N'ENROLLED'),
    (N'ENR00316', N'STU021', N'OFF051', '2026-05-20', N'ENROLLED'),
    (N'ENR00317', N'STU021', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00318', N'STU021', N'OFF052', '2026-05-20', N'ENROLLED'),
    (N'ENR00319', N'STU022', N'OFF036', '2026-05-20', N'ENROLLED'),
    (N'ENR00320', N'STU022', N'OFF037', '2026-05-20', N'ENROLLED'),
    (N'ENR00321', N'STU022', N'OFF039', '2026-05-20', N'ENROLLED'),
    (N'ENR00322', N'STU022', N'OFF035', '2026-05-20', N'ENROLLED'),
    (N'ENR00323', N'STU023', N'OFF056', '2026-05-20', N'ENROLLED'),
    (N'ENR00324', N'STU023', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00325', N'STU023', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00326', N'STU023', N'OFF060', '2026-05-20', N'ENROLLED'),
    (N'ENR00327', N'STU024', N'OFF022', '2026-05-20', N'ENROLLED'),
    (N'ENR00328', N'STU024', N'OFF020', '2026-05-20', N'ENROLLED'),
    (N'ENR00329', N'STU024', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00330', N'STU025', N'OFF055', '2026-05-20', N'ENROLLED'),
    (N'ENR00331', N'STU025', N'OFF054', '2026-05-20', N'ENROLLED'),
    (N'ENR00332', N'STU025', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00333', N'STU026', N'OFF035', '2026-05-20', N'ENROLLED'),
    (N'ENR00334', N'STU026', N'OFF037', '2026-05-20', N'ENROLLED'),
    (N'ENR00335', N'STU026', N'OFF059', '2026-05-20', N'ENROLLED'),
    (N'ENR00336', N'STU026', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00337', N'STU027', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00338', N'STU027', N'OFF023', '2026-05-20', N'ENROLLED'),
    (N'ENR00339', N'STU027', N'OFF020', '2026-05-20', N'ENROLLED'),
    (N'ENR00340', N'STU027', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00341', N'STU028', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00342', N'STU028', N'OFF032', '2026-05-20', N'ENROLLED'),
    (N'ENR00343', N'STU028', N'OFF020', '2026-05-20', N'ENROLLED'),
    (N'ENR00344', N'STU029', N'OFF025', '2026-05-20', N'ENROLLED'),
    (N'ENR00345', N'STU029', N'OFF024', '2026-05-20', N'ENROLLED'),
    (N'ENR00346', N'STU029', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00347', N'STU030', N'OFF058', '2026-05-20', N'ENROLLED'),
    (N'ENR00348', N'STU030', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00349', N'STU030', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00350', N'STU031', N'OFF020', '2026-05-20', N'ENROLLED'),
    (N'ENR00351', N'STU031', N'OFF023', '2026-05-20', N'ENROLLED'),
    (N'ENR00352', N'STU031', N'OFF057', '2026-05-20', N'ENROLLED'),
    (N'ENR00353', N'STU031', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00354', N'STU032', N'OFF031', '2026-05-20', N'ENROLLED'),
    (N'ENR00355', N'STU032', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00356', N'STU032', N'OFF032', '2026-05-20', N'ENROLLED'),
    (N'ENR00357', N'STU033', N'OFF035', '2026-05-20', N'ENROLLED'),
    (N'ENR00358', N'STU033', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00359', N'STU033', N'OFF039', '2026-05-20', N'ENROLLED'),
    (N'ENR00360', N'STU034', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00361', N'STU034', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00362', N'STU034', N'OFF033', '2026-05-20', N'ENROLLED'),
    (N'ENR00363', N'STU035', N'OFF046', '2026-05-20', N'ENROLLED'),
    (N'ENR00364', N'STU035', N'OFF047', '2026-05-20', N'ENROLLED'),
    (N'ENR00365', N'STU035', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00366', N'STU035', N'OFF048', '2026-05-20', N'ENROLLED'),
    (N'ENR00367', N'STU036', N'OFF060', '2026-05-20', N'ENROLLED'),
    (N'ENR00368', N'STU036', N'OFF024', '2026-05-20', N'ENROLLED'),
    (N'ENR00369', N'STU036', N'OFF027', '2026-05-20', N'ENROLLED'),
    (N'ENR00370', N'STU037', N'OFF036', '2026-05-20', N'ENROLLED'),
    (N'ENR00371', N'STU037', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00372', N'STU037', N'OFF035', '2026-05-20', N'ENROLLED'),
    (N'ENR00373', N'STU037', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00374', N'STU038', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00375', N'STU038', N'OFF056', '2026-05-20', N'ENROLLED'),
    (N'ENR00376', N'STU038', N'OFF018', '2026-05-20', N'ENROLLED'),
    (N'ENR00377', N'STU038', N'OFF022', '2026-05-20', N'ENROLLED'),
    (N'ENR00378', N'STU039', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00379', N'STU039', N'OFF036', '2026-05-20', N'ENROLLED'),
    (N'ENR00380', N'STU039', N'OFF039', '2026-05-20', N'ENROLLED'),
    (N'ENR00381', N'STU039', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00382', N'STU040', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00383', N'STU040', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00384', N'STU040', N'OFF037', '2026-05-20', N'ENROLLED'),
    (N'ENR00385', N'STU040', N'OFF059', '2026-05-20', N'ENROLLED'),
    (N'ENR00386', N'STU041', N'OFF022', '2026-05-20', N'ENROLLED'),
    (N'ENR00387', N'STU041', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00388', N'STU041', N'OFF021', '2026-05-20', N'ENROLLED'),
    (N'ENR00389', N'STU041', N'OFF018', '2026-05-20', N'ENROLLED'),
    (N'ENR00390', N'STU042', N'OFF020', '2026-05-20', N'ENROLLED'),
    (N'ENR00391', N'STU042', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00392', N'STU042', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00393', N'STU043', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00394', N'STU043', N'OFF056', '2026-05-20', N'ENROLLED'),
    (N'ENR00395', N'STU043', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00396', N'STU044', N'OFF023', '2026-05-20', N'ENROLLED'),
    (N'ENR00397', N'STU044', N'OFF021', '2026-05-20', N'ENROLLED'),
    (N'ENR00398', N'STU044', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00399', N'STU045', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00400', N'STU045', N'OFF022', '2026-05-20', N'ENROLLED'),
    (N'ENR00401', N'STU045', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00402', N'STU046', N'OFF025', '2026-05-20', N'ENROLLED'),
    (N'ENR00403', N'STU046', N'OFF024', '2026-05-20', N'ENROLLED'),
    (N'ENR00404', N'STU046', N'OFF028', '2026-05-20', N'ENROLLED'),
    (N'ENR00405', N'STU047', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00406', N'STU047', N'OFF058', '2026-05-20', N'ENROLLED'),
    (N'ENR00407', N'STU047', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00408', N'STU047', N'OFF044', '2026-05-20', N'ENROLLED'),
    (N'ENR00409', N'STU048', N'OFF025', '2026-05-20', N'ENROLLED'),
    (N'ENR00410', N'STU048', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00411', N'STU048', N'OFF024', '2026-05-20', N'ENROLLED'),
    (N'ENR00412', N'STU048', N'OFF028', '2026-05-20', N'ENROLLED'),
    (N'ENR00413', N'STU049', N'OFF045', '2026-05-20', N'ENROLLED'),
    (N'ENR00414', N'STU049', N'OFF048', '2026-05-20', N'ENROLLED'),
    (N'ENR00415', N'STU049', N'OFF046', '2026-05-20', N'ENROLLED'),
    (N'ENR00416', N'STU049', N'OFF047', '2026-05-20', N'ENROLLED'),
    (N'ENR00417', N'STU050', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00418', N'STU050', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00419', N'STU050', N'OFF033', '2026-05-20', N'ENROLLED'),
    (N'ENR00420', N'STU051', N'OFF026', '2026-05-20', N'ENROLLED'),
    (N'ENR00421', N'STU051', N'OFF060', '2026-05-20', N'ENROLLED'),
    (N'ENR00422', N'STU051', N'OFF029', '2026-05-20', N'ENROLLED'),
    (N'ENR00423', N'STU052', N'OFF042', '2026-05-20', N'ENROLLED'),
    (N'ENR00424', N'STU052', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00425', N'STU052', N'OFF043', '2026-05-20', N'ENROLLED'),
    (N'ENR00426', N'STU053', N'OFF044', '2026-05-20', N'ENROLLED'),
    (N'ENR00427', N'STU053', N'OFF042', '2026-05-20', N'ENROLLED'),
    (N'ENR00428', N'STU053', N'OFF043', '2026-05-20', N'ENROLLED'),
    (N'ENR00429', N'STU053', N'OFF041', '2026-05-20', N'ENROLLED'),
    (N'ENR00430', N'STU054', N'OFF018', '2026-05-20', N'ENROLLED'),
    (N'ENR00431', N'STU054', N'OFF023', '2026-05-20', N'ENROLLED'),
    (N'ENR00432', N'STU054', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00433', N'STU055', N'OFF038', '2026-05-20', N'ENROLLED'),
    (N'ENR00434', N'STU055', N'OFF039', '2026-05-20', N'ENROLLED'),
    (N'ENR00435', N'STU055', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00436', N'STU056', N'OFF027', '2026-05-20', N'ENROLLED'),
    (N'ENR00437', N'STU056', N'OFF029', '2026-05-20', N'ENROLLED'),
    (N'ENR00438', N'STU056', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00439', N'STU056', N'OFF028', '2026-05-20', N'ENROLLED'),
    (N'ENR00440', N'STU057', N'OFF020', '2026-05-20', N'ENROLLED'),
    (N'ENR00441', N'STU057', N'OFF057', '2026-05-20', N'ENROLLED'),
    (N'ENR00442', N'STU057', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00443', N'STU058', N'OFF041', '2026-05-20', N'ENROLLED'),
    (N'ENR00444', N'STU058', N'OFF044', '2026-05-20', N'ENROLLED'),
    (N'ENR00445', N'STU058', N'OFF043', '2026-05-20', N'ENROLLED'),
    (N'ENR00446', N'STU058', N'OFF058', '2026-05-20', N'ENROLLED'),
    (N'ENR00447', N'STU059', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00448', N'STU059', N'OFF056', '2026-05-20', N'ENROLLED'),
    (N'ENR00449', N'STU059', N'OFF020', '2026-05-20', N'ENROLLED'),
    (N'ENR00450', N'STU060', N'OFF048', '2026-05-20', N'ENROLLED'),
    (N'ENR00451', N'STU060', N'OFF047', '2026-05-20', N'ENROLLED'),
    (N'ENR00452', N'STU060', N'OFF046', '2026-05-20', N'ENROLLED'),
    (N'ENR00453', N'STU061', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00454', N'STU061', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00455', N'STU061', N'OFF050', '2026-05-20', N'ENROLLED'),
    (N'ENR00456', N'STU061', N'OFF051', '2026-05-20', N'ENROLLED'),
    (N'ENR00457', N'STU062', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00458', N'STU062', N'OFF043', '2026-05-20', N'ENROLLED'),
    (N'ENR00459', N'STU062', N'OFF041', '2026-05-20', N'ENROLLED'),
    (N'ENR00460', N'STU063', N'OFF049', '2026-05-20', N'ENROLLED'),
    (N'ENR00461', N'STU063', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00462', N'STU063', N'OFF028', '2026-05-20', N'ENROLLED'),
    (N'ENR00463', N'STU063', N'OFF051', '2026-05-20', N'ENROLLED'),
    (N'ENR00464', N'STU064', N'OFF054', '2026-05-20', N'ENROLLED'),
    (N'ENR00465', N'STU064', N'OFF055', '2026-05-20', N'ENROLLED'),
    (N'ENR00466', N'STU064', N'OFF057', '2026-05-20', N'ENROLLED'),
    (N'ENR00467', N'STU065', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00468', N'STU065', N'OFF030', '2026-05-20', N'ENROLLED'),
    (N'ENR00469', N'STU065', N'OFF033', '2026-05-20', N'ENROLLED'),
    (N'ENR00470', N'STU065', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00471', N'STU066', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00472', N'STU066', N'OFF046', '2026-05-20', N'ENROLLED'),
    (N'ENR00473', N'STU066', N'OFF048', '2026-05-20', N'ENROLLED'),
    (N'ENR00474', N'STU067', N'OFF033', '2026-05-20', N'ENROLLED'),
    (N'ENR00475', N'STU067', N'OFF032', '2026-05-20', N'ENROLLED'),
    (N'ENR00476', N'STU067', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00477', N'STU067', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00478', N'STU068', N'OFF048', '2026-05-20', N'ENROLLED'),
    (N'ENR00479', N'STU068', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00480', N'STU068', N'OFF047', '2026-05-20', N'ENROLLED'),
    (N'ENR00481', N'STU069', N'OFF041', '2026-05-20', N'ENROLLED'),
    (N'ENR00482', N'STU069', N'OFF042', '2026-05-20', N'ENROLLED'),
    (N'ENR00483', N'STU069', N'OFF043', '2026-05-20', N'ENROLLED'),
    (N'ENR00484', N'STU070', N'OFF048', '2026-05-20', N'ENROLLED'),
    (N'ENR00485', N'STU070', N'OFF047', '2026-05-20', N'ENROLLED'),
    (N'ENR00486', N'STU070', N'OFF046', '2026-05-20', N'ENROLLED'),
    (N'ENR00487', N'STU071', N'OFF031', '2026-05-20', N'ENROLLED'),
    (N'ENR00488', N'STU071', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00489', N'STU071', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00490', N'STU072', N'OFF059', '2026-05-20', N'ENROLLED'),
    (N'ENR00491', N'STU072', N'OFF039', '2026-05-20', N'ENROLLED'),
    (N'ENR00492', N'STU072', N'OFF035', '2026-05-20', N'ENROLLED'),
    (N'ENR00493', N'STU072', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00494', N'STU073', N'OFF046', '2026-05-20', N'ENROLLED'),
    (N'ENR00495', N'STU073', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00496', N'STU073', N'OFF048', '2026-05-20', N'ENROLLED'),
    (N'ENR00497', N'STU074', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00498', N'STU074', N'OFF020', '2026-05-20', N'ENROLLED'),
    (N'ENR00499', N'STU074', N'OFF057', '2026-05-20', N'ENROLLED'),
    (N'ENR00500', N'STU075', N'OFF051', '2026-05-20', N'ENROLLED'),
    (N'ENR00501', N'STU075', N'OFF052', '2026-05-20', N'ENROLLED'),
    (N'ENR00502', N'STU075', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00503', N'STU076', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00504', N'STU076', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00505', N'STU076', N'OFF050', '2026-05-20', N'ENROLLED'),
    (N'ENR00506', N'STU077', N'OFF040', '2026-05-20', N'ENROLLED'),
    (N'ENR00507', N'STU077', N'OFF016', '2026-05-20', N'ENROLLED'),
    (N'ENR00508', N'STU077', N'OFF058', '2026-05-20', N'ENROLLED'),
    (N'ENR00509', N'STU078', N'OFF041', '2026-05-20', N'ENROLLED'),
    (N'ENR00510', N'STU078', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00511', N'STU078', N'OFF042', '2026-05-20', N'ENROLLED'),
    (N'ENR00512', N'STU079', N'OFF047', '2026-05-20', N'ENROLLED'),
    (N'ENR00513', N'STU079', N'OFF048', '2026-05-20', N'ENROLLED'),
    (N'ENR00514', N'STU079', N'OFF046', '2026-05-20', N'ENROLLED'),
    (N'ENR00515', N'STU080', N'OFF028', '2026-05-20', N'ENROLLED'),
    (N'ENR00516', N'STU080', N'OFF017', '2026-05-20', N'ENROLLED'),
    (N'ENR00517', N'STU080', N'OFF025', '2026-05-20', N'ENROLLED');
GO


INSERT INTO dbo.student_assessment_scores (score_id, enrollment_id, component_id, score) VALUES
    (N'SCR000001', N'ENR00001', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.7),
    (N'SCR000002', N'ENR00001', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.7),
    (N'SCR000003', N'ENR00001', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.4),
    (N'SCR000004', N'ENR00001', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.5),
    (N'SCR000005', N'ENR00001', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.9),
    (N'SCR000006', N'ENR00001', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 31.2),
    (N'SCR000007', N'ENR00002', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.0),
    (N'SCR000008', N'ENR00002', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.3),
    (N'SCR000009', N'ENR00002', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.7),
    (N'SCR000010', N'ENR00002', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.4),
    (N'SCR000011', N'ENR00002', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR000012', N'ENR00002', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 28.0),
    (N'SCR000013', N'ENR00003', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 20.0),
    (N'SCR000014', N'ENR00003', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.8),
    (N'SCR000015', N'ENR00003', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.2),
    (N'SCR000016', N'ENR00003', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.9),
    (N'SCR000017', N'ENR00003', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.6),
    (N'SCR000018', N'ENR00003', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 40.0),
    (N'SCR000019', N'ENR00004', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.1),
    (N'SCR000020', N'ENR00004', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.8),
    (N'SCR000021', N'ENR00004', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.7),
    (N'SCR000022', N'ENR00004', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000023', N'ENR00004', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.7),
    (N'SCR000024', N'ENR00004', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.4),
    (N'SCR000025', N'ENR00005', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.5),
    (N'SCR000026', N'ENR00005', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.9),
    (N'SCR000027', N'ENR00005', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.9),
    (N'SCR000028', N'ENR00005', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.3),
    (N'SCR000029', N'ENR00005', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.1),
    (N'SCR000030', N'ENR00005', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.6),
    (N'SCR000031', N'ENR00006', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.1),
    (N'SCR000032', N'ENR00006', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR000033', N'ENR00006', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.9),
    (N'SCR000034', N'ENR00006', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.6),
    (N'SCR000035', N'ENR00006', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.7),
    (N'SCR000036', N'ENR00006', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 28.8),
    (N'SCR000043', N'ENR00008', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.7),
    (N'SCR000044', N'ENR00008', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.0),
    (N'SCR000045', N'ENR00008', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.9),
    (N'SCR000046', N'ENR00008', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.2),
    (N'SCR000047', N'ENR00008', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR000048', N'ENR00008', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 33.2),
    (N'SCR000049', N'ENR00009', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.6),
    (N'SCR000050', N'ENR00009', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR000051', N'ENR00009', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.2),
    (N'SCR000052', N'ENR00009', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.7),
    (N'SCR000053', N'ENR00009', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.0),
    (N'SCR000054', N'ENR00009', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.4),
    (N'SCR000055', N'ENR00010', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.9),
    (N'SCR000056', N'ENR00010', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.2),
    (N'SCR000057', N'ENR00010', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.2),
    (N'SCR000058', N'ENR00010', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.3),
    (N'SCR000059', N'ENR00010', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.1),
    (N'SCR000060', N'ENR00010', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.9),
    (N'SCR000061', N'ENR00011', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.7),
    (N'SCR000062', N'ENR00011', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.5),
    (N'SCR000063', N'ENR00011', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.5),
    (N'SCR000064', N'ENR00011', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.2),
    (N'SCR000065', N'ENR00011', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.1),
    (N'SCR000066', N'ENR00011', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.2),
    (N'SCR000067', N'ENR00012', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.5),
    (N'SCR000068', N'ENR00012', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.9),
    (N'SCR000069', N'ENR00012', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.6),
    (N'SCR000070', N'ENR00012', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.5),
    (N'SCR000071', N'ENR00012', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.6),
    (N'SCR000072', N'ENR00012', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.3),
    (N'SCR000073', N'ENR00013', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.2),
    (N'SCR000074', N'ENR00013', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.2),
    (N'SCR000075', N'ENR00013', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.5),
    (N'SCR000076', N'ENR00013', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.4),
    (N'SCR000077', N'ENR00013', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.5),
    (N'SCR000078', N'ENR00013', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.1),
    (N'SCR000079', N'ENR00014', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.9),
    (N'SCR000080', N'ENR00014', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.4),
    (N'SCR000081', N'ENR00014', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.4),
    (N'SCR000082', N'ENR00014', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.7),
    (N'SCR000083', N'ENR00014', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.0),
    (N'SCR000084', N'ENR00014', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.2),
    (N'SCR000085', N'ENR00015', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.1),
    (N'SCR000086', N'ENR00015', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR000087', N'ENR00015', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.4),
    (N'SCR000088', N'ENR00015', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.5),
    (N'SCR000089', N'ENR00015', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR000090', N'ENR00015', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.3),
    (N'SCR000091', N'ENR00016', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.9),
    (N'SCR000092', N'ENR00016', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.9),
    (N'SCR000093', N'ENR00016', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.0),
    (N'SCR000094', N'ENR00016', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.4),
    (N'SCR000095', N'ENR00016', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR000096', N'ENR00016', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 33.1),
    (N'SCR000097', N'ENR00017', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.2),
    (N'SCR000098', N'ENR00017', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.5),
    (N'SCR000099', N'ENR00017', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.2),
    (N'SCR000100', N'ENR00017', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.1),
    (N'SCR000101', N'ENR00017', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.5),
    (N'SCR000102', N'ENR00017', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 21.0),
    (N'SCR000103', N'ENR00018', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.8),
    (N'SCR000104', N'ENR00018', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.8),
    (N'SCR000105', N'ENR00018', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.0),
    (N'SCR000106', N'ENR00018', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.9),
    (N'SCR000107', N'ENR00018', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.7),
    (N'SCR000108', N'ENR00018', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 22.7),
    (N'SCR000109', N'ENR00019', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 8.5),
    (N'SCR000110', N'ENR00019', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.8),
    (N'SCR000111', N'ENR00019', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 7.1),
    (N'SCR000112', N'ENR00019', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.2),
    (N'SCR000113', N'ENR00019', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.6),
    (N'SCR000114', N'ENR00019', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 18.7),
    (N'SCR000121', N'ENR00021', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.9),
    (N'SCR000122', N'ENR00021', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.9),
    (N'SCR000123', N'ENR00021', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.4),
    (N'SCR000124', N'ENR00021', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000125', N'ENR00021', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.9),
    (N'SCR000126', N'ENR00021', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 40.0),
    (N'SCR000127', N'ENR00022', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.6),
    (N'SCR000128', N'ENR00022', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR000129', N'ENR00022', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.9),
    (N'SCR000130', N'ENR00022', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.3),
    (N'SCR000131', N'ENR00022', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.8),
    (N'SCR000132', N'ENR00022', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 40.0),
    (N'SCR000133', N'ENR00023', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.2),
    (N'SCR000134', N'ENR00023', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.2),
    (N'SCR000135', N'ENR00023', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.3),
    (N'SCR000136', N'ENR00023', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000137', N'ENR00023', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR000138', N'ENR00023', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 36.7),
    (N'SCR000145', N'ENR00025', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.8),
    (N'SCR000146', N'ENR00025', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.3),
    (N'SCR000147', N'ENR00025', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.3),
    (N'SCR000148', N'ENR00025', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR000149', N'ENR00025', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.1),
    (N'SCR000150', N'ENR00025', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 36.3),
    (N'SCR000151', N'ENR00026', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.4),
    (N'SCR000152', N'ENR00026', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.1),
    (N'SCR000153', N'ENR00026', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.1),
    (N'SCR000154', N'ENR00026', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000155', N'ENR00026', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.7),
    (N'SCR000156', N'ENR00026', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 33.3),
    (N'SCR000157', N'ENR00027', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.1),
    (N'SCR000158', N'ENR00027', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.0),
    (N'SCR000159', N'ENR00027', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.4),
    (N'SCR000160', N'ENR00027', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.7),
    (N'SCR000161', N'ENR00027', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.1),
    (N'SCR000162', N'ENR00027', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.4),
    (N'SCR000163', N'ENR00028', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.7),
    (N'SCR000164', N'ENR00028', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.8),
    (N'SCR000165', N'ENR00028', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.4),
    (N'SCR000166', N'ENR00028', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.3),
    (N'SCR000167', N'ENR00028', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.9),
    (N'SCR000168', N'ENR00028', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 23.1),
    (N'SCR000175', N'ENR00031', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.7),
    (N'SCR000176', N'ENR00031', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.5),
    (N'SCR000177', N'ENR00031', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.6),
    (N'SCR000178', N'ENR00031', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.7),
    (N'SCR000179', N'ENR00031', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.6),
    (N'SCR000180', N'ENR00031', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.9),
    (N'SCR000181', N'ENR00032', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.0),
    (N'SCR000182', N'ENR00032', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR000183', N'ENR00032', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.9),
    (N'SCR000184', N'ENR00032', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.6),
    (N'SCR000185', N'ENR00032', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.5),
    (N'SCR000186', N'ENR00032', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.9),
    (N'SCR000193', N'ENR00034', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.0),
    (N'SCR000194', N'ENR00034', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR000195', N'ENR00034', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.8),
    (N'SCR000196', N'ENR00034', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.5),
    (N'SCR000197', N'ENR00034', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.6),
    (N'SCR000198', N'ENR00034', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.5),
    (N'SCR000199', N'ENR00036', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.4),
    (N'SCR000200', N'ENR00036', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.2),
    (N'SCR000201', N'ENR00036', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.7),
    (N'SCR000202', N'ENR00036', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR000203', N'ENR00036', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.5),
    (N'SCR000204', N'ENR00036', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.6),
    (N'SCR000205', N'ENR00037', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.4),
    (N'SCR000206', N'ENR00037', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.5),
    (N'SCR000207', N'ENR00037', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.1),
    (N'SCR000208', N'ENR00037', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000209', N'ENR00037', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR000210', N'ENR00037', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.0),
    (N'SCR000211', N'ENR00038', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.0),
    (N'SCR000212', N'ENR00038', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.6),
    (N'SCR000213', N'ENR00038', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.5),
    (N'SCR000214', N'ENR00038', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000215', N'ENR00038', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.9),
    (N'SCR000216', N'ENR00038', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 36.4),
    (N'SCR000217', N'ENR00039', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.1),
    (N'SCR000218', N'ENR00039', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.1),
    (N'SCR000219', N'ENR00039', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.9),
    (N'SCR000220', N'ENR00039', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.5),
    (N'SCR000221', N'ENR00039', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.9),
    (N'SCR000222', N'ENR00039', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.3),
    (N'SCR000223', N'ENR00040', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.5),
    (N'SCR000224', N'ENR00040', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.5),
    (N'SCR000225', N'ENR00040', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.3),
    (N'SCR000226', N'ENR00040', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.1),
    (N'SCR000227', N'ENR00040', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.1),
    (N'SCR000228', N'ENR00040', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 24.2),
    (N'SCR000229', N'ENR00042', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.6),
    (N'SCR000230', N'ENR00042', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.9),
    (N'SCR000231', N'ENR00042', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.8),
    (N'SCR000232', N'ENR00042', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000233', N'ENR00042', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.5),
    (N'SCR000234', N'ENR00042', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 37.5),
    (N'SCR000235', N'ENR00043', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.7),
    (N'SCR000236', N'ENR00043', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.9),
    (N'SCR000237', N'ENR00043', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.4),
    (N'SCR000238', N'ENR00043', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000239', N'ENR00043', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR000240', N'ENR00043', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.7),
    (N'SCR000241', N'ENR00044', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.4),
    (N'SCR000242', N'ENR00044', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.9),
    (N'SCR000243', N'ENR00044', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.1),
    (N'SCR000244', N'ENR00044', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.9),
    (N'SCR000245', N'ENR00044', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.9),
    (N'SCR000246', N'ENR00044', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.5),
    (N'SCR000247', N'ENR00045', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.0),
    (N'SCR000248', N'ENR00045', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.2),
    (N'SCR000249', N'ENR00045', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.0),
    (N'SCR000250', N'ENR00045', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.9),
    (N'SCR000251', N'ENR00045', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.6),
    (N'SCR000252', N'ENR00045', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 27.6),
    (N'SCR000253', N'ENR00046', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.8),
    (N'SCR000254', N'ENR00046', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.9),
    (N'SCR000255', N'ENR00046', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.3),
    (N'SCR000256', N'ENR00046', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.6),
    (N'SCR000257', N'ENR00046', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.4),
    (N'SCR000258', N'ENR00046', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 27.9),
    (N'SCR000259', N'ENR00047', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.0),
    (N'SCR000260', N'ENR00047', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.2),
    (N'SCR000261', N'ENR00047', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.9),
    (N'SCR000262', N'ENR00047', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR000263', N'ENR00047', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.9),
    (N'SCR000264', N'ENR00047', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 28.4),
    (N'SCR000265', N'ENR00048', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.0),
    (N'SCR000266', N'ENR00048', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.9),
    (N'SCR000267', N'ENR00048', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.0),
    (N'SCR000268', N'ENR00048', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.6),
    (N'SCR000269', N'ENR00048', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.0),
    (N'SCR000270', N'ENR00048', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 28.5),
    (N'SCR000271', N'ENR00049', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 9.9),
    (N'SCR000272', N'ENR00049', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 4.6),
    (N'SCR000273', N'ENR00049', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.1),
    (N'SCR000274', N'ENR00049', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 1.4),
    (N'SCR000275', N'ENR00049', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.9),
    (N'SCR000276', N'ENR00049', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 21.2),
    (N'SCR000277', N'ENR00050', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 9.1),
    (N'SCR000278', N'ENR00050', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.0),
    (N'SCR000279', N'ENR00050', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.4),
    (N'SCR000280', N'ENR00050', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.7),
    (N'SCR000281', N'ENR00050', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.1),
    (N'SCR000282', N'ENR00050', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 18.0),
    (N'SCR000283', N'ENR00051', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.2),
    (N'SCR000284', N'ENR00051', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.8),
    (N'SCR000285', N'ENR00051', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.8),
    (N'SCR000286', N'ENR00051', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.6),
    (N'SCR000287', N'ENR00051', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.7),
    (N'SCR000288', N'ENR00051', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.4),
    (N'SCR000301', N'ENR00054', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.3),
    (N'SCR000302', N'ENR00054', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.2),
    (N'SCR000303', N'ENR00054', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.3),
    (N'SCR000304', N'ENR00054', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.2),
    (N'SCR000305', N'ENR00054', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.8),
    (N'SCR000306', N'ENR00054', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 24.9),
    (N'SCR000313', N'ENR00056', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.4),
    (N'SCR000314', N'ENR00056', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.3),
    (N'SCR000315', N'ENR00056', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.1),
    (N'SCR000316', N'ENR00056', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.5),
    (N'SCR000317', N'ENR00056', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.1),
    (N'SCR000318', N'ENR00056', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.5),
    (N'SCR000325', N'ENR00058', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.7),
    (N'SCR000326', N'ENR00058', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR000327', N'ENR00058', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.4),
    (N'SCR000328', N'ENR00058', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000329', N'ENR00058', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.3),
    (N'SCR000330', N'ENR00058', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.9),
    (N'SCR000331', N'ENR00059', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.5),
    (N'SCR000332', N'ENR00059', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.7),
    (N'SCR000333', N'ENR00059', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.1),
    (N'SCR000334', N'ENR00059', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.4),
    (N'SCR000335', N'ENR00059', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR000336', N'ENR00059', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.8),
    (N'SCR000337', N'ENR00060', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.0),
    (N'SCR000338', N'ENR00060', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.2),
    (N'SCR000339', N'ENR00060', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.5),
    (N'SCR000340', N'ENR00060', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 1.6),
    (N'SCR000341', N'ENR00060', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.5),
    (N'SCR000342', N'ENR00060', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 19.1),
    (N'SCR000343', N'ENR00061', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.9),
    (N'SCR000344', N'ENR00061', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.0),
    (N'SCR000345', N'ENR00061', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 7.8),
    (N'SCR000346', N'ENR00061', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 1.9),
    (N'SCR000347', N'ENR00061', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.5),
    (N'SCR000348', N'ENR00061', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 22.6),
    (N'SCR000349', N'ENR00062', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.6),
    (N'SCR000350', N'ENR00062', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.3),
    (N'SCR000351', N'ENR00062', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.1),
    (N'SCR000352', N'ENR00062', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.2),
    (N'SCR000353', N'ENR00062', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.7),
    (N'SCR000354', N'ENR00062', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 23.7),
    (N'SCR000355', N'ENR00063', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.2),
    (N'SCR000356', N'ENR00063', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.6),
    (N'SCR000357', N'ENR00063', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.2),
    (N'SCR000358', N'ENR00063', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.5),
    (N'SCR000359', N'ENR00063', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.9),
    (N'SCR000360', N'ENR00063', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 36.9),
    (N'SCR000373', N'ENR00066', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.3),
    (N'SCR000374', N'ENR00066', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.1),
    (N'SCR000375', N'ENR00066', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.2),
    (N'SCR000376', N'ENR00066', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.0),
    (N'SCR000377', N'ENR00066', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.8),
    (N'SCR000378', N'ENR00066', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.8),
    (N'SCR000379', N'ENR00067', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.5),
    (N'SCR000380', N'ENR00067', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR000381', N'ENR00067', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.0),
    (N'SCR000382', N'ENR00067', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000383', N'ENR00067', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR000384', N'ENR00067', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 36.6),
    (N'SCR000385', N'ENR00068', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.6),
    (N'SCR000386', N'ENR00068', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.2),
    (N'SCR000387', N'ENR00068', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 15.0),
    (N'SCR000388', N'ENR00068', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.5),
    (N'SCR000389', N'ENR00068', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR000390', N'ENR00068', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.2),
    (N'SCR000397', N'ENR00070', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.5),
    (N'SCR000398', N'ENR00070', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.3),
    (N'SCR000399', N'ENR00070', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.8),
    (N'SCR000400', N'ENR00070', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.2),
    (N'SCR000401', N'ENR00070', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.8),
    (N'SCR000402', N'ENR00070', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.1),
    (N'SCR000403', N'ENR00071', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.2),
    (N'SCR000404', N'ENR00071', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.2),
    (N'SCR000405', N'ENR00071', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.0),
    (N'SCR000406', N'ENR00071', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000407', N'ENR00071', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.5),
    (N'SCR000408', N'ENR00071', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.1),
    (N'SCR000409', N'ENR00072', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.6),
    (N'SCR000410', N'ENR00072', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR000411', N'ENR00072', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.1),
    (N'SCR000412', N'ENR00072', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.9),
    (N'SCR000413', N'ENR00072', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.1),
    (N'SCR000414', N'ENR00072', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 27.4),
    (N'SCR000415', N'ENR00073', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.4),
    (N'SCR000416', N'ENR00073', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.8),
    (N'SCR000417', N'ENR00073', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.2),
    (N'SCR000418', N'ENR00073', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.1),
    (N'SCR000419', N'ENR00073', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.9),
    (N'SCR000420', N'ENR00073', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.7),
    (N'SCR000421', N'ENR00074', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.0),
    (N'SCR000422', N'ENR00074', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR000423', N'ENR00074', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.1),
    (N'SCR000424', N'ENR00074', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.1),
    (N'SCR000425', N'ENR00074', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.8),
    (N'SCR000426', N'ENR00074', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 27.6),
    (N'SCR000427', N'ENR00075', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.4),
    (N'SCR000428', N'ENR00075', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.5),
    (N'SCR000429', N'ENR00075', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.2),
    (N'SCR000430', N'ENR00075', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.6),
    (N'SCR000431', N'ENR00075', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.8),
    (N'SCR000432', N'ENR00075', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 40.0),
    (N'SCR000433', N'ENR00076', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.7),
    (N'SCR000434', N'ENR00076', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.2),
    (N'SCR000435', N'ENR00076', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.4),
    (N'SCR000436', N'ENR00076', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.7),
    (N'SCR000437', N'ENR00076', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.6),
    (N'SCR000438', N'ENR00076', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.5),
    (N'SCR000445', N'ENR00078', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 9.6),
    (N'SCR000446', N'ENR00078', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 3.7),
    (N'SCR000447', N'ENR00078', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 6.5),
    (N'SCR000448', N'ENR00078', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.7),
    (N'SCR000449', N'ENR00078', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.5),
    (N'SCR000450', N'ENR00078', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 18.1),
    (N'SCR000451', N'ENR00079', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.4),
    (N'SCR000452', N'ENR00079', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 4.8),
    (N'SCR000453', N'ENR00079', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.6),
    (N'SCR000454', N'ENR00079', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 1.8),
    (N'SCR000455', N'ENR00079', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.7),
    (N'SCR000456', N'ENR00079', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.0),
    (N'SCR000457', N'ENR00080', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.9),
    (N'SCR000458', N'ENR00080', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR000459', N'ENR00080', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.9),
    (N'SCR000460', N'ENR00080', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.1),
    (N'SCR000461', N'ENR00080', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.0),
    (N'SCR000462', N'ENR00080', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.3),
    (N'SCR000463', N'ENR00081', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.5),
    (N'SCR000464', N'ENR00081', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR000465', N'ENR00081', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.8),
    (N'SCR000466', N'ENR00081', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.3),
    (N'SCR000467', N'ENR00081', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.6),
    (N'SCR000468', N'ENR00081', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 28.4),
    (N'SCR000469', N'ENR00082', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.1),
    (N'SCR000470', N'ENR00082', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.0),
    (N'SCR000471', N'ENR00082', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 7.8),
    (N'SCR000472', N'ENR00082', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.8),
    (N'SCR000473', N'ENR00082', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.4),
    (N'SCR000474', N'ENR00082', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.7),
    (N'SCR000475', N'ENR00083', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 8.8),
    (N'SCR000476', N'ENR00083', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.0),
    (N'SCR000477', N'ENR00083', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 7.0),
    (N'SCR000478', N'ENR00083', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.4),
    (N'SCR000479', N'ENR00083', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 3.9),
    (N'SCR000480', N'ENR00083', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 22.3),
    (N'SCR000493', N'ENR00086', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.4),
    (N'SCR000494', N'ENR00086', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.7),
    (N'SCR000495', N'ENR00086', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.5),
    (N'SCR000496', N'ENR00086', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.2),
    (N'SCR000497', N'ENR00086', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.6),
    (N'SCR000498', N'ENR00086', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.1),
    (N'SCR000499', N'ENR00087', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.5),
    (N'SCR000500', N'ENR00087', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.3),
    (N'SCR000501', N'ENR00087', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.8),
    (N'SCR000502', N'ENR00087', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.6),
    (N'SCR000503', N'ENR00087', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.8),
    (N'SCR000504', N'ENR00087', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.8),
    (N'SCR000511', N'ENR00089', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.0),
    (N'SCR000512', N'ENR00089', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR000513', N'ENR00089', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.6),
    (N'SCR000514', N'ENR00089', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.2),
    (N'SCR000515', N'ENR00089', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR000516', N'ENR00089', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.0),
    (N'SCR000517', N'ENR00090', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.5),
    (N'SCR000518', N'ENR00090', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.2),
    (N'SCR000519', N'ENR00090', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.1),
    (N'SCR000520', N'ENR00090', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.1),
    (N'SCR000521', N'ENR00090', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.4),
    (N'SCR000522', N'ENR00090', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 31.8),
    (N'SCR000523', N'ENR00091', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.9),
    (N'SCR000524', N'ENR00091', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.5),
    (N'SCR000525', N'ENR00091', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.2),
    (N'SCR000526', N'ENR00091', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.3),
    (N'SCR000527', N'ENR00091', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.8),
    (N'SCR000528', N'ENR00091', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.8),
    (N'SCR000529', N'ENR00092', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.3),
    (N'SCR000530', N'ENR00092', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.6),
    (N'SCR000531', N'ENR00092', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.4),
    (N'SCR000532', N'ENR00092', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.2),
    (N'SCR000533', N'ENR00092', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.7),
    (N'SCR000534', N'ENR00092', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 24.6),
    (N'SCR000535', N'ENR00093', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.2),
    (N'SCR000536', N'ENR00093', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.9),
    (N'SCR000537', N'ENR00093', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.2),
    (N'SCR000538', N'ENR00093', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.2),
    (N'SCR000539', N'ENR00093', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.0),
    (N'SCR000540', N'ENR00093', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 26.6),
    (N'SCR000547', N'ENR00095', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.3),
    (N'SCR000548', N'ENR00095', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR000549', N'ENR00095', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.7),
    (N'SCR000550', N'ENR00095', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.4),
    (N'SCR000551', N'ENR00095', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.9),
    (N'SCR000552', N'ENR00095', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 26.7),
    (N'SCR000559', N'ENR00097', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.0),
    (N'SCR000560', N'ENR00097', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR000561', N'ENR00097', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.9),
    (N'SCR000562', N'ENR00097', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.3),
    (N'SCR000563', N'ENR00097', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.8),
    (N'SCR000564', N'ENR00097', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 27.0),
    (N'SCR000571', N'ENR00099', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.2),
    (N'SCR000572', N'ENR00099', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR000573', N'ENR00099', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.4),
    (N'SCR000574', N'ENR00099', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.3),
    (N'SCR000575', N'ENR00099', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.0),
    (N'SCR000576', N'ENR00099', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 31.0),
    (N'SCR000577', N'ENR00100', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.8),
    (N'SCR000578', N'ENR00100', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR000579', N'ENR00100', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.3),
    (N'SCR000580', N'ENR00100', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.3),
    (N'SCR000581', N'ENR00100', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.6),
    (N'SCR000582', N'ENR00100', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.5),
    (N'SCR000589', N'ENR00102', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.1),
    (N'SCR000590', N'ENR00102', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.8),
    (N'SCR000591', N'ENR00102', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.2),
    (N'SCR000592', N'ENR00102', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.4),
    (N'SCR000593', N'ENR00102', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.5),
    (N'SCR000594', N'ENR00102', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 21.1),
    (N'SCR000595', N'ENR00103', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.4),
    (N'SCR000596', N'ENR00103', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.4),
    (N'SCR000597', N'ENR00103', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 6.9),
    (N'SCR000598', N'ENR00103', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.6),
    (N'SCR000599', N'ENR00103', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.3),
    (N'SCR000600', N'ENR00103', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 22.1),
    (N'SCR000601', N'ENR00104', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 9.9),
    (N'SCR000602', N'ENR00104', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.7),
    (N'SCR000603', N'ENR00104', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 7.3),
    (N'SCR000604', N'ENR00104', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 1.5),
    (N'SCR000605', N'ENR00104', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.5),
    (N'SCR000606', N'ENR00104', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 22.3),
    (N'SCR000607', N'ENR00105', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.7),
    (N'SCR000608', N'ENR00105', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.5),
    (N'SCR000609', N'ENR00105', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.6),
    (N'SCR000610', N'ENR00105', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000611', N'ENR00105', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.6),
    (N'SCR000612', N'ENR00105', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.3),
    (N'SCR000619', N'ENR00107', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.2),
    (N'SCR000620', N'ENR00107', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.3),
    (N'SCR000621', N'ENR00107', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.9),
    (N'SCR000622', N'ENR00107', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.1),
    (N'SCR000623', N'ENR00107', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.6),
    (N'SCR000624', N'ENR00107', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 33.1),
    (N'SCR000625', N'ENR00108', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.0),
    (N'SCR000626', N'ENR00108', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.0),
    (N'SCR000627', N'ENR00108', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.4),
    (N'SCR000628', N'ENR00108', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.1),
    (N'SCR000629', N'ENR00108', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.0),
    (N'SCR000630', N'ENR00108', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 26.2),
    (N'SCR000631', N'ENR00109', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.0),
    (N'SCR000632', N'ENR00109', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.8),
    (N'SCR000633', N'ENR00109', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.2),
    (N'SCR000634', N'ENR00109', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.7),
    (N'SCR000635', N'ENR00109', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.7),
    (N'SCR000636', N'ENR00109', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.0),
    (N'SCR000637', N'ENR00110', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.3),
    (N'SCR000638', N'ENR00110', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR000639', N'ENR00110', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.1),
    (N'SCR000640', N'ENR00110', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.8),
    (N'SCR000641', N'ENR00110', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.2),
    (N'SCR000642', N'ENR00110', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.2),
    (N'SCR000643', N'ENR00111', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.4),
    (N'SCR000644', N'ENR00111', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR000645', N'ENR00111', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.1),
    (N'SCR000646', N'ENR00111', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR000647', N'ENR00111', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.6),
    (N'SCR000648', N'ENR00111', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.9),
    (N'SCR000655', N'ENR00113', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.7),
    (N'SCR000656', N'ENR00113', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.2),
    (N'SCR000657', N'ENR00113', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.8),
    (N'SCR000658', N'ENR00113', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR000659', N'ENR00113', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.1),
    (N'SCR000660', N'ENR00113', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 23.4),
    (N'SCR000661', N'ENR00114', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.5),
    (N'SCR000662', N'ENR00114', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.9),
    (N'SCR000663', N'ENR00114', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.5),
    (N'SCR000664', N'ENR00114', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.7),
    (N'SCR000665', N'ENR00114', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.0),
    (N'SCR000666', N'ENR00114', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 23.0),
    (N'SCR000673', N'ENR00116', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 8.3),
    (N'SCR000674', N'ENR00116', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 3.8),
    (N'SCR000675', N'ENR00116', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 6.1),
    (N'SCR000676', N'ENR00116', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 1.9),
    (N'SCR000677', N'ENR00116', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.1),
    (N'SCR000678', N'ENR00116', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 20.7),
    (N'SCR000685', N'ENR00118', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.3),
    (N'SCR000686', N'ENR00118', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.7),
    (N'SCR000687', N'ENR00118', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.4),
    (N'SCR000688', N'ENR00118', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.6),
    (N'SCR000689', N'ENR00118', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.2),
    (N'SCR000690', N'ENR00118', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.6),
    (N'SCR000691', N'ENR00119', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.4),
    (N'SCR000692', N'ENR00119', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.5),
    (N'SCR000693', N'ENR00119', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.1),
    (N'SCR000694', N'ENR00119', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.2),
    (N'SCR000695', N'ENR00119', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.8),
    (N'SCR000696', N'ENR00119', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 37.4),
    (N'SCR000697', N'ENR00120', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.9),
    (N'SCR000698', N'ENR00120', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR000699', N'ENR00120', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.4),
    (N'SCR000700', N'ENR00120', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.5),
    (N'SCR000701', N'ENR00120', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.7),
    (N'SCR000702', N'ENR00120', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 37.8),
    (N'SCR000709', N'ENR00122', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.3),
    (N'SCR000710', N'ENR00122', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.8),
    (N'SCR000711', N'ENR00122', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.8),
    (N'SCR000712', N'ENR00122', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.3),
    (N'SCR000713', N'ENR00122', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.2),
    (N'SCR000714', N'ENR00122', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.5),
    (N'SCR000715', N'ENR00123', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.5),
    (N'SCR000716', N'ENR00123', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR000717', N'ENR00123', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.2),
    (N'SCR000718', N'ENR00123', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.6),
    (N'SCR000719', N'ENR00123', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.4),
    (N'SCR000720', N'ENR00123', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.7),
    (N'SCR000721', N'ENR00124', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.0),
    (N'SCR000722', N'ENR00124', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.1),
    (N'SCR000723', N'ENR00124', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.1),
    (N'SCR000724', N'ENR00124', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR000725', N'ENR00124', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.7),
    (N'SCR000726', N'ENR00124', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.8),
    (N'SCR000733', N'ENR00126', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.1),
    (N'SCR000734', N'ENR00126', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.7),
    (N'SCR000735', N'ENR00126', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.4),
    (N'SCR000736', N'ENR00126', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.4),
    (N'SCR000737', N'ENR00126', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.8),
    (N'SCR000738', N'ENR00126', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 24.6),
    (N'SCR000739', N'ENR00127', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.6),
    (N'SCR000740', N'ENR00127', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.3),
    (N'SCR000741', N'ENR00127', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.2),
    (N'SCR000742', N'ENR00127', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.7),
    (N'SCR000743', N'ENR00127', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.4),
    (N'SCR000744', N'ENR00127', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 27.2),
    (N'SCR000745', N'ENR00128', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.8),
    (N'SCR000746', N'ENR00128', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.7),
    (N'SCR000747', N'ENR00128', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.6),
    (N'SCR000748', N'ENR00128', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.4),
    (N'SCR000749', N'ENR00128', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.6),
    (N'SCR000750', N'ENR00128', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.2),
    (N'SCR000763', N'ENR00131', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.0),
    (N'SCR000764', N'ENR00131', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.0),
    (N'SCR000765', N'ENR00131', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.7),
    (N'SCR000766', N'ENR00131', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.6),
    (N'SCR000767', N'ENR00131', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.6),
    (N'SCR000768', N'ENR00131', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 26.4);
GO

INSERT INTO dbo.student_assessment_scores (score_id, enrollment_id, component_id, score) VALUES
    (N'SCR000769', N'ENR00132', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.3),
    (N'SCR000770', N'ENR00132', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.7),
    (N'SCR000771', N'ENR00132', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.8),
    (N'SCR000772', N'ENR00132', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.0),
    (N'SCR000773', N'ENR00132', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.2),
    (N'SCR000774', N'ENR00132', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.5),
    (N'SCR000775', N'ENR00133', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.4),
    (N'SCR000776', N'ENR00133', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.0),
    (N'SCR000777', N'ENR00133', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.8),
    (N'SCR000778', N'ENR00133', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.6),
    (N'SCR000779', N'ENR00133', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.1),
    (N'SCR000780', N'ENR00133', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.4),
    (N'SCR000781', N'ENR00134', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.2),
    (N'SCR000782', N'ENR00134', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.1),
    (N'SCR000783', N'ENR00134', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.7),
    (N'SCR000784', N'ENR00134', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.7),
    (N'SCR000785', N'ENR00134', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.4),
    (N'SCR000786', N'ENR00134', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 27.1),
    (N'SCR000787', N'ENR00135', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.5),
    (N'SCR000788', N'ENR00135', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.6),
    (N'SCR000789', N'ENR00135', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.5),
    (N'SCR000790', N'ENR00135', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.1),
    (N'SCR000791', N'ENR00135', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.7),
    (N'SCR000792', N'ENR00135', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.2),
    (N'SCR000793', N'ENR00137', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.6),
    (N'SCR000794', N'ENR00137', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.4),
    (N'SCR000795', N'ENR00137', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.1),
    (N'SCR000796', N'ENR00137', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.8),
    (N'SCR000797', N'ENR00137', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.4),
    (N'SCR000798', N'ENR00137', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 26.7),
    (N'SCR000805', N'ENR00139', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.8),
    (N'SCR000806', N'ENR00139', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR000807', N'ENR00139', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.2),
    (N'SCR000808', N'ENR00139', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.7),
    (N'SCR000809', N'ENR00139', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.0),
    (N'SCR000810', N'ENR00139', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 33.6),
    (N'SCR000823', N'ENR00142', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.3),
    (N'SCR000824', N'ENR00142', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.7),
    (N'SCR000825', N'ENR00142', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.6),
    (N'SCR000826', N'ENR00142', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000827', N'ENR00142', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.7),
    (N'SCR000828', N'ENR00142', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.2),
    (N'SCR000835', N'ENR00144', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.3),
    (N'SCR000836', N'ENR00144', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR000837', N'ENR00144', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.2),
    (N'SCR000838', N'ENR00144', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.1),
    (N'SCR000839', N'ENR00144', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.9),
    (N'SCR000840', N'ENR00144', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.0),
    (N'SCR000841', N'ENR00145', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.2),
    (N'SCR000842', N'ENR00145', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR000843', N'ENR00145', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.3),
    (N'SCR000844', N'ENR00145', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR000845', N'ENR00145', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.5),
    (N'SCR000846', N'ENR00145', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.9),
    (N'SCR000847', N'ENR00146', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.0),
    (N'SCR000848', N'ENR00146', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.3),
    (N'SCR000849', N'ENR00146', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.9),
    (N'SCR000850', N'ENR00146', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.5),
    (N'SCR000851', N'ENR00146', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.3),
    (N'SCR000852', N'ENR00146', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 28.7),
    (N'SCR000865', N'ENR00149', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.0),
    (N'SCR000866', N'ENR00149', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.8),
    (N'SCR000867', N'ENR00149', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.4),
    (N'SCR000868', N'ENR00149', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000869', N'ENR00149', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.1),
    (N'SCR000870', N'ENR00149', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 31.9),
    (N'SCR000871', N'ENR00150', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.3),
    (N'SCR000872', N'ENR00150', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.0),
    (N'SCR000873', N'ENR00150', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.7),
    (N'SCR000874', N'ENR00150', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.4),
    (N'SCR000875', N'ENR00150', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.7),
    (N'SCR000876', N'ENR00150', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 21.3),
    (N'SCR000877', N'ENR00151', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 9.6),
    (N'SCR000878', N'ENR00151', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.0),
    (N'SCR000879', N'ENR00151', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 6.8),
    (N'SCR000880', N'ENR00151', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 1.8),
    (N'SCR000881', N'ENR00151', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.0),
    (N'SCR000882', N'ENR00151', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 21.9),
    (N'SCR000883', N'ENR00152', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.3),
    (N'SCR000884', N'ENR00152', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.1),
    (N'SCR000885', N'ENR00152', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.9),
    (N'SCR000886', N'ENR00152', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.9),
    (N'SCR000887', N'ENR00152', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.7),
    (N'SCR000888', N'ENR00152', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 21.3),
    (N'SCR000889', N'ENR00153', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.8),
    (N'SCR000890', N'ENR00153', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.8),
    (N'SCR000891', N'ENR00153', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.3),
    (N'SCR000892', N'ENR00153', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.7),
    (N'SCR000893', N'ENR00153', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.7),
    (N'SCR000894', N'ENR00153', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.3),
    (N'SCR000895', N'ENR00154', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.7),
    (N'SCR000896', N'ENR00154', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR000897', N'ENR00154', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.4),
    (N'SCR000898', N'ENR00154', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000899', N'ENR00154', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.9),
    (N'SCR000900', N'ENR00154', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.0),
    (N'SCR000913', N'ENR00157', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.2),
    (N'SCR000914', N'ENR00157', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR000915', N'ENR00157', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.9),
    (N'SCR000916', N'ENR00157', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000917', N'ENR00157', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.7),
    (N'SCR000918', N'ENR00157', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.8),
    (N'SCR000919', N'ENR00158', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 20.0),
    (N'SCR000920', N'ENR00158', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR000921', N'ENR00158', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.8),
    (N'SCR000922', N'ENR00158', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.5),
    (N'SCR000923', N'ENR00158', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.9),
    (N'SCR000924', N'ENR00158', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 37.3),
    (N'SCR000931', N'ENR00160', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.3),
    (N'SCR000932', N'ENR00160', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR000933', N'ENR00160', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 15.0),
    (N'SCR000934', N'ENR00160', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000935', N'ENR00160', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.2),
    (N'SCR000936', N'ENR00160', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.3),
    (N'SCR000937', N'ENR00161', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.8),
    (N'SCR000938', N'ENR00161', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.0),
    (N'SCR000939', N'ENR00161', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.2),
    (N'SCR000940', N'ENR00161', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.1),
    (N'SCR000941', N'ENR00161', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR000942', N'ENR00161', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.1),
    (N'SCR000943', N'ENR00162', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.0),
    (N'SCR000944', N'ENR00162', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR000945', N'ENR00162', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.1),
    (N'SCR000946', N'ENR00162', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.9),
    (N'SCR000947', N'ENR00162', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.1),
    (N'SCR000948', N'ENR00162', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 31.1),
    (N'SCR000949', N'ENR00163', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.4),
    (N'SCR000950', N'ENR00163', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.5),
    (N'SCR000951', N'ENR00163', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.0),
    (N'SCR000952', N'ENR00163', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000953', N'ENR00163', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.6),
    (N'SCR000954', N'ENR00163', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.0),
    (N'SCR000961', N'ENR00165', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.9),
    (N'SCR000962', N'ENR00165', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.7),
    (N'SCR000963', N'ENR00165', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.4),
    (N'SCR000964', N'ENR00165', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR000965', N'ENR00165', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.3),
    (N'SCR000966', N'ENR00165', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.3),
    (N'SCR000967', N'ENR00166', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.9),
    (N'SCR000968', N'ENR00166', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.7),
    (N'SCR000969', N'ENR00166', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.5),
    (N'SCR000970', N'ENR00166', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.6),
    (N'SCR000971', N'ENR00166', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.7),
    (N'SCR000972', N'ENR00166', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 40.0),
    (N'SCR000979', N'ENR00168', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.3),
    (N'SCR000980', N'ENR00168', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR000981', N'ENR00168', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.6),
    (N'SCR000982', N'ENR00168', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.8),
    (N'SCR000983', N'ENR00168', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.0),
    (N'SCR000984', N'ENR00168', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 24.1),
    (N'SCR000985', N'ENR00169', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 8.9),
    (N'SCR000986', N'ENR00169', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.6),
    (N'SCR000987', N'ENR00169', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 6.9),
    (N'SCR000988', N'ENR00169', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.3),
    (N'SCR000989', N'ENR00169', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.4),
    (N'SCR000990', N'ENR00169', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 18.5),
    (N'SCR000991', N'ENR00170', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.9),
    (N'SCR000992', N'ENR00170', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.8),
    (N'SCR000993', N'ENR00170', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.8),
    (N'SCR000994', N'ENR00170', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.3),
    (N'SCR000995', N'ENR00170', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.7),
    (N'SCR000996', N'ENR00170', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 37.2),
    (N'SCR000997', N'ENR00171', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.8),
    (N'SCR000998', N'ENR00171', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.8),
    (N'SCR000999', N'ENR00171', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.0),
    (N'SCR001000', N'ENR00171', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.5),
    (N'SCR001001', N'ENR00171', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.9),
    (N'SCR001002', N'ENR00171', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.9),
    (N'SCR001003', N'ENR00172', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.0),
    (N'SCR001004', N'ENR00172', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.9),
    (N'SCR001005', N'ENR00172', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.8),
    (N'SCR001006', N'ENR00172', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR001007', N'ENR00172', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR001008', N'ENR00172', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.5),
    (N'SCR001009', N'ENR00173', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.1),
    (N'SCR001010', N'ENR00173', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.7),
    (N'SCR001011', N'ENR00173', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.0),
    (N'SCR001012', N'ENR00173', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.5),
    (N'SCR001013', N'ENR00173', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.3),
    (N'SCR001014', N'ENR00173', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 33.2),
    (N'SCR001021', N'ENR00175', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.1),
    (N'SCR001022', N'ENR00175', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR001023', N'ENR00175', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.5),
    (N'SCR001024', N'ENR00175', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.3),
    (N'SCR001025', N'ENR00175', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.3),
    (N'SCR001026', N'ENR00175', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.1),
    (N'SCR001027', N'ENR00176', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.3),
    (N'SCR001028', N'ENR00176', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001029', N'ENR00176', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.2),
    (N'SCR001030', N'ENR00176', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.8),
    (N'SCR001031', N'ENR00176', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.8),
    (N'SCR001032', N'ENR00176', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 36.3),
    (N'SCR001033', N'ENR00177', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.3),
    (N'SCR001034', N'ENR00177', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.3),
    (N'SCR001035', N'ENR00177', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.3),
    (N'SCR001036', N'ENR00177', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.5),
    (N'SCR001037', N'ENR00177', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR001038', N'ENR00177', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.6),
    (N'SCR001039', N'ENR00178', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.4),
    (N'SCR001040', N'ENR00178', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001041', N'ENR00178', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 15.0),
    (N'SCR001042', N'ENR00178', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.3),
    (N'SCR001043', N'ENR00178', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR001044', N'ENR00178', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 37.6),
    (N'SCR001051', N'ENR00180', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.2),
    (N'SCR001052', N'ENR00180', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001053', N'ENR00180', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.3),
    (N'SCR001054', N'ENR00180', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.6),
    (N'SCR001055', N'ENR00180', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.6),
    (N'SCR001056', N'ENR00180', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 39.2),
    (N'SCR001057', N'ENR00181', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.9),
    (N'SCR001058', N'ENR00181', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.8),
    (N'SCR001059', N'ENR00181', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 15.0),
    (N'SCR001060', N'ENR00181', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.5),
    (N'SCR001061', N'ENR00181', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001062', N'ENR00181', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 38.0),
    (N'SCR001075', N'ENR00184', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.4),
    (N'SCR001076', N'ENR00184', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.6),
    (N'SCR001077', N'ENR00184', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.1),
    (N'SCR001078', N'ENR00184', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.9),
    (N'SCR001079', N'ENR00184', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.8),
    (N'SCR001080', N'ENR00184', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 40.0),
    (N'SCR001081', N'ENR00185', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.9),
    (N'SCR001082', N'ENR00185', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.1),
    (N'SCR001083', N'ENR00185', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.7),
    (N'SCR001084', N'ENR00185', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.8),
    (N'SCR001085', N'ENR00185', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.3),
    (N'SCR001086', N'ENR00185', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.6),
    (N'SCR001087', N'ENR00186', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.1),
    (N'SCR001088', N'ENR00186', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.1),
    (N'SCR001089', N'ENR00186', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.2),
    (N'SCR001090', N'ENR00186', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.4),
    (N'SCR001091', N'ENR00186', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.6),
    (N'SCR001092', N'ENR00186', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 33.4),
    (N'SCR001093', N'ENR00187', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.0),
    (N'SCR001094', N'ENR00187', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.0),
    (N'SCR001095', N'ENR00187', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.7),
    (N'SCR001096', N'ENR00187', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.4),
    (N'SCR001097', N'ENR00187', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.1),
    (N'SCR001098', N'ENR00187', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.4),
    (N'SCR001105', N'ENR00189', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.5),
    (N'SCR001106', N'ENR00189', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.9),
    (N'SCR001107', N'ENR00189', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.8),
    (N'SCR001108', N'ENR00189', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR001109', N'ENR00189', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.8),
    (N'SCR001110', N'ENR00189', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 31.9),
    (N'SCR001111', N'ENR00190', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.7),
    (N'SCR001112', N'ENR00190', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.1),
    (N'SCR001113', N'ENR00190', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.3),
    (N'SCR001114', N'ENR00190', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.7),
    (N'SCR001115', N'ENR00190', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.9),
    (N'SCR001116', N'ENR00190', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.5),
    (N'SCR001117', N'ENR00191', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.8),
    (N'SCR001118', N'ENR00191', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR001119', N'ENR00191', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.7),
    (N'SCR001120', N'ENR00191', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.2),
    (N'SCR001121', N'ENR00191', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.9),
    (N'SCR001122', N'ENR00191', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.7),
    (N'SCR001129', N'ENR00193', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.0),
    (N'SCR001130', N'ENR00193', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.3),
    (N'SCR001131', N'ENR00193', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.8),
    (N'SCR001132', N'ENR00193', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.2),
    (N'SCR001133', N'ENR00193', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.4),
    (N'SCR001134', N'ENR00193', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 24.5),
    (N'SCR001135', N'ENR00194', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.3),
    (N'SCR001136', N'ENR00194', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.7),
    (N'SCR001137', N'ENR00194', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 7.6),
    (N'SCR001138', N'ENR00194', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 1.8),
    (N'SCR001139', N'ENR00194', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.3),
    (N'SCR001140', N'ENR00194', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 20.8),
    (N'SCR001153', N'ENR00197', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.7),
    (N'SCR001154', N'ENR00197', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.2),
    (N'SCR001155', N'ENR00197', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.0),
    (N'SCR001156', N'ENR00197', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.9),
    (N'SCR001157', N'ENR00197', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.6),
    (N'SCR001158', N'ENR00197', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 19.5),
    (N'SCR001159', N'ENR00198', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.1),
    (N'SCR001160', N'ENR00198', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR001161', N'ENR00198', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 7.7),
    (N'SCR001162', N'ENR00198', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.9),
    (N'SCR001163', N'ENR00198', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.5),
    (N'SCR001164', N'ENR00198', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 20.7),
    (N'SCR001171', N'ENR00201', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.3),
    (N'SCR001172', N'ENR00201', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.4),
    (N'SCR001173', N'ENR00201', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.6),
    (N'SCR001174', N'ENR00201', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.1),
    (N'SCR001175', N'ENR00201', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR001176', N'ENR00201', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.9),
    (N'SCR001177', N'ENR00202', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.0),
    (N'SCR001178', N'ENR00202', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.9),
    (N'SCR001179', N'ENR00202', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 10.5),
    (N'SCR001180', N'ENR00202', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.7),
    (N'SCR001181', N'ENR00202', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.9),
    (N'SCR001182', N'ENR00202', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 26.3),
    (N'SCR001183', N'ENR00203', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.5),
    (N'SCR001184', N'ENR00203', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR001185', N'ENR00203', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.2),
    (N'SCR001186', N'ENR00203', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.1),
    (N'SCR001187', N'ENR00203', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.1),
    (N'SCR001188', N'ENR00203', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 26.9),
    (N'SCR001189', N'ENR00204', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.1),
    (N'SCR001190', N'ENR00204', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.3),
    (N'SCR001191', N'ENR00204', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.5),
    (N'SCR001192', N'ENR00204', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.6),
    (N'SCR001193', N'ENR00204', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.7),
    (N'SCR001194', N'ENR00204', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 27.3),
    (N'SCR001201', N'ENR00206', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.3),
    (N'SCR001202', N'ENR00206', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR001203', N'ENR00206', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.5),
    (N'SCR001204', N'ENR00206', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR001205', N'ENR00206', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001206', N'ENR00206', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 37.4),
    (N'SCR001207', N'ENR00207', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.5),
    (N'SCR001208', N'ENR00207', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.3),
    (N'SCR001209', N'ENR00207', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.2),
    (N'SCR001210', N'ENR00207', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.6),
    (N'SCR001211', N'ENR00207', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.7),
    (N'SCR001212', N'ENR00207', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 40.0),
    (N'SCR001219', N'ENR00209', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.9),
    (N'SCR001220', N'ENR00209', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.8),
    (N'SCR001221', N'ENR00209', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.2),
    (N'SCR001222', N'ENR00209', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR001223', N'ENR00209', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR001224', N'ENR00209', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 40.0),
    (N'SCR001225', N'ENR00210', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.5),
    (N'SCR001226', N'ENR00210', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.5),
    (N'SCR001227', N'ENR00210', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.2),
    (N'SCR001228', N'ENR00210', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR001229', N'ENR00210', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.7),
    (N'SCR001230', N'ENR00210', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.1),
    (N'SCR001231', N'ENR00211', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.9),
    (N'SCR001232', N'ENR00211', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.3),
    (N'SCR001233', N'ENR00211', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.3),
    (N'SCR001234', N'ENR00211', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.5),
    (N'SCR001235', N'ENR00211', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.0),
    (N'SCR001236', N'ENR00211', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.5),
    (N'SCR001243', N'ENR00214', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.0),
    (N'SCR001244', N'ENR00214', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.3),
    (N'SCR001245', N'ENR00214', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.2),
    (N'SCR001246', N'ENR00214', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 1.7),
    (N'SCR001247', N'ENR00214', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.6),
    (N'SCR001248', N'ENR00214', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 21.9),
    (N'SCR001249', N'ENR00215', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 8.4),
    (N'SCR001250', N'ENR00215', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.5),
    (N'SCR001251', N'ENR00215', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 7.9),
    (N'SCR001252', N'ENR00215', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.0),
    (N'SCR001253', N'ENR00215', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.0),
    (N'SCR001254', N'ENR00215', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 17.4),
    (N'SCR001261', N'ENR00218', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.5),
    (N'SCR001262', N'ENR00218', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR001263', N'ENR00218', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.2),
    (N'SCR001264', N'ENR00218', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.4),
    (N'SCR001265', N'ENR00218', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.9),
    (N'SCR001266', N'ENR00218', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.2),
    (N'SCR001267', N'ENR00219', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.0),
    (N'SCR001268', N'ENR00219', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.1),
    (N'SCR001269', N'ENR00219', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.4),
    (N'SCR001270', N'ENR00219', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.5),
    (N'SCR001271', N'ENR00219', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.5),
    (N'SCR001272', N'ENR00219', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 30.0),
    (N'SCR001273', N'ENR00220', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.8),
    (N'SCR001274', N'ENR00220', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.8),
    (N'SCR001275', N'ENR00220', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 11.7),
    (N'SCR001276', N'ENR00220', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.8),
    (N'SCR001277', N'ENR00220', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR001278', N'ENR00220', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.0),
    (N'SCR001279', N'ENR00221', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.9),
    (N'SCR001280', N'ENR00221', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.4),
    (N'SCR001281', N'ENR00221', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.5),
    (N'SCR001282', N'ENR00221', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR001283', N'ENR00221', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.8),
    (N'SCR001284', N'ENR00221', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 36.7),
    (N'SCR001297', N'ENR00224', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.0),
    (N'SCR001298', N'ENR00224', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.6),
    (N'SCR001299', N'ENR00224', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.7),
    (N'SCR001300', N'ENR00224', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.4),
    (N'SCR001301', N'ENR00224', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.9),
    (N'SCR001302', N'ENR00224', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.4),
    (N'SCR001303', N'ENR00225', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.1),
    (N'SCR001304', N'ENR00225', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001305', N'ENR00225', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.8),
    (N'SCR001306', N'ENR00225', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR001307', N'ENR00225', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.1),
    (N'SCR001308', N'ENR00225', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 36.4),
    (N'SCR001309', N'ENR00226', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 20.0),
    (N'SCR001310', N'ENR00226', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.8),
    (N'SCR001311', N'ENR00226', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 15.0),
    (N'SCR001312', N'ENR00226', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.6),
    (N'SCR001313', N'ENR00226', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001314', N'ENR00226', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 37.8),
    (N'SCR001315', N'ENR00228', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.0),
    (N'SCR001316', N'ENR00228', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.4),
    (N'SCR001317', N'ENR00228', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.5),
    (N'SCR001318', N'ENR00228', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.2),
    (N'SCR001319', N'ENR00228', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.0),
    (N'SCR001320', N'ENR00228', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 35.0),
    (N'SCR001321', N'ENR00229', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.4),
    (N'SCR001322', N'ENR00229', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.3),
    (N'SCR001323', N'ENR00229', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.0),
    (N'SCR001324', N'ENR00229', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.4),
    (N'SCR001325', N'ENR00229', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.5),
    (N'SCR001326', N'ENR00229', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 36.7),
    (N'SCR001327', N'ENR00230', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.8),
    (N'SCR001328', N'ENR00230', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR001329', N'ENR00230', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.5),
    (N'SCR001330', N'ENR00230', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR001331', N'ENR00230', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.8),
    (N'SCR001332', N'ENR00230', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.4),
    (N'SCR001339', N'ENR00232', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.9),
    (N'SCR001340', N'ENR00232', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.9),
    (N'SCR001341', N'ENR00232', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 9.3),
    (N'SCR001342', N'ENR00232', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.1),
    (N'SCR001343', N'ENR00232', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.0),
    (N'SCR001344', N'ENR00232', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.5),
    (N'SCR001345', N'ENR00233', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.2),
    (N'SCR001346', N'ENR00233', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.6),
    (N'SCR001347', N'ENR00233', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.7),
    (N'SCR001348', N'ENR00233', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.9),
    (N'SCR001349', N'ENR00233', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.7),
    (N'SCR001350', N'ENR00233', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 25.6),
    (N'SCR001351', N'ENR00234', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.7),
    (N'SCR001352', N'ENR00234', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR001353', N'ENR00234', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 12.0),
    (N'SCR001354', N'ENR00234', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.6),
    (N'SCR001355', N'ENR00234', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.5),
    (N'SCR001356', N'ENR00234', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 29.0),
    (N'SCR001369', N'ENR00237', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.8),
    (N'SCR001370', N'ENR00237', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR001371', N'ENR00237', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 14.0),
    (N'SCR001372', N'ENR00237', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.4),
    (N'SCR001373', N'ENR00237', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.2),
    (N'SCR001374', N'ENR00237', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 32.8),
    (N'SCR001375', N'ENR00238', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.5),
    (N'SCR001376', N'ENR00238', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.7),
    (N'SCR001377', N'ENR00238', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.4),
    (N'SCR001378', N'ENR00238', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.8),
    (N'SCR001379', N'ENR00238', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.5),
    (N'SCR001380', N'ENR00238', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 34.1),
    (N'SCR001381', N'ENR00239', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.6),
    (N'SCR001382', N'ENR00239', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.6),
    (N'SCR001383', N'ENR00239', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 13.3),
    (N'SCR001384', N'ENR00239', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 4.7),
    (N'SCR001385', N'ENR00239', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.7),
    (N'SCR001386', N'ENR00239', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 40.0),
    (N'SCR001387', N'ENR00240', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.7),
    (N'SCR001388', N'ENR00240', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.8),
    (N'SCR001389', N'ENR00240', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 15.0),
    (N'SCR001390', N'ENR00240', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 5.0),
    (N'SCR001391', N'ENR00240', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001392', N'ENR00240', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 39.7),
    (N'SCR001399', N'ENR00242', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.4),
    (N'SCR001400', N'ENR00242', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 4.1),
    (N'SCR001401', N'ENR00242', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 8.0),
    (N'SCR001402', N'ENR00242', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 3.6),
    (N'SCR001403', N'ENR00242', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.1),
    (N'SCR001404', N'ENR00242', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 17.7),
    (N'SCR001405', N'ENR00243', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.4),
    (N'SCR001406', N'ENR00243', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.2),
    (N'SCR001407', N'ENR00243', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_LEC'), 6.6),
    (N'SCR001408', N'ENR00243', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W12_SEC'), 2.8),
    (N'SCR001409', N'ENR00243', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.1),
    (N'SCR001410', N'ENR00243', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'FINAL'), 18.2),
    (N'SCR001429', N'ENR00248', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.1),
    (N'SCR001430', N'ENR00248', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.3),
    (N'SCR001431', N'ENR00248', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.0),
    (N'SCR001432', N'ENR00250', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.8),
    (N'SCR001433', N'ENR00250', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001434', N'ENR00251', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.2),
    (N'SCR001435', N'ENR00251', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.3),
    (N'SCR001436', N'ENR00251', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001437', N'ENR00255', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.1),
    (N'SCR001438', N'ENR00255', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.1),
    (N'SCR001439', N'ENR00255', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.9),
    (N'SCR001440', N'ENR00256', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.3),
    (N'SCR001441', N'ENR00256', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001442', N'ENR00256', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR001443', N'ENR00257', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.2),
    (N'SCR001444', N'ENR00257', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.7),
    (N'SCR001445', N'ENR00258', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.2),
    (N'SCR001446', N'ENR00258', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.4),
    (N'SCR001447', N'ENR00261', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.9),
    (N'SCR001448', N'ENR00261', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.0),
    (N'SCR001449', N'ENR00261', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.0),
    (N'SCR001450', N'ENR00262', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.8),
    (N'SCR001451', N'ENR00262', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.4),
    (N'SCR001452', N'ENR00262', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR001453', N'ENR00265', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.5),
    (N'SCR001454', N'ENR00265', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001455', N'ENR00266', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.2),
    (N'SCR001456', N'ENR00266', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.5),
    (N'SCR001457', N'ENR00266', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.0),
    (N'SCR001458', N'ENR00267', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.3),
    (N'SCR001459', N'ENR00267', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.6),
    (N'SCR001460', N'ENR00268', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.5),
    (N'SCR001461', N'ENR00268', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.7),
    (N'SCR001462', N'ENR00269', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 8.8),
    (N'SCR001463', N'ENR00269', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 4.8),
    (N'SCR001464', N'ENR00269', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.8),
    (N'SCR001465', N'ENR00270', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.5),
    (N'SCR001466', N'ENR00270', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.4),
    (N'SCR001467', N'ENR00271', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.8),
    (N'SCR001468', N'ENR00271', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR001469', N'ENR00271', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.8),
    (N'SCR001470', N'ENR00272', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.8),
    (N'SCR001471', N'ENR00272', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001472', N'ENR00272', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.3),
    (N'SCR001473', N'ENR00273', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.0),
    (N'SCR001474', N'ENR00273', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001475', N'ENR00275', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.9),
    (N'SCR001476', N'ENR00275', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001477', N'ENR00275', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001478', N'ENR00276', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 20.0),
    (N'SCR001479', N'ENR00276', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001480', N'ENR00279', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.4),
    (N'SCR001481', N'ENR00279', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.3),
    (N'SCR001482', N'ENR00283', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.2),
    (N'SCR001483', N'ENR00283', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.3),
    (N'SCR001484', N'ENR00284', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.1),
    (N'SCR001485', N'ENR00284', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.7),
    (N'SCR001486', N'ENR00285', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.4),
    (N'SCR001487', N'ENR00285', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.9),
    (N'SCR001488', N'ENR00285', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001489', N'ENR00286', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.7),
    (N'SCR001490', N'ENR00286', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.5),
    (N'SCR001491', N'ENR00286', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.8),
    (N'SCR001492', N'ENR00287', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.3),
    (N'SCR001493', N'ENR00287', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001494', N'ENR00288', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.0),
    (N'SCR001495', N'ENR00288', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.0),
    (N'SCR001496', N'ENR00288', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.5),
    (N'SCR001497', N'ENR00290', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.4),
    (N'SCR001498', N'ENR00290', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR001499', N'ENR00290', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.9),
    (N'SCR001500', N'ENR00293', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.3),
    (N'SCR001501', N'ENR00293', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001502', N'ENR00294', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.7),
    (N'SCR001503', N'ENR00294', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.9),
    (N'SCR001504', N'ENR00295', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.7),
    (N'SCR001505', N'ENR00295', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.3),
    (N'SCR001506', N'ENR00295', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.7),
    (N'SCR001507', N'ENR00296', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.8),
    (N'SCR001508', N'ENR00296', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001509', N'ENR00298', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.2),
    (N'SCR001510', N'ENR00298', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.3),
    (N'SCR001511', N'ENR00298', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.2),
    (N'SCR001512', N'ENR00300', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.1),
    (N'SCR001513', N'ENR00300', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.9),
    (N'SCR001514', N'ENR00300', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.4),
    (N'SCR001515', N'ENR00301', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.2),
    (N'SCR001516', N'ENR00301', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.1),
    (N'SCR001517', N'ENR00302', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.7),
    (N'SCR001518', N'ENR00302', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.7),
    (N'SCR001519', N'ENR00305', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.5),
    (N'SCR001520', N'ENR00305', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.1),
    (N'SCR001521', N'ENR00306', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.7),
    (N'SCR001522', N'ENR00306', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR001523', N'ENR00307', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.3),
    (N'SCR001524', N'ENR00307', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.1),
    (N'SCR001525', N'ENR00308', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.3),
    (N'SCR001526', N'ENR00308', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.2),
    (N'SCR001527', N'ENR00308', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR001528', N'ENR00309', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.6),
    (N'SCR001529', N'ENR00309', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.0),
    (N'SCR001530', N'ENR00314', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.2),
    (N'SCR001531', N'ENR00314', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001532', N'ENR00314', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.9),
    (N'SCR001533', N'ENR00316', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 8.7),
    (N'SCR001534', N'ENR00316', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.7),
    (N'SCR001535', N'ENR00316', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.1),
    (N'SCR001536', N'ENR00318', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.4),
    (N'SCR001537', N'ENR00318', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 4.6),
    (N'SCR001538', N'ENR00318', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.7),
    (N'SCR001539', N'ENR00322', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.0),
    (N'SCR001540', N'ENR00322', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.9),
    (N'SCR001541', N'ENR00322', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.4),
    (N'SCR001542', N'ENR00323', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.0),
    (N'SCR001543', N'ENR00323', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001544', N'ENR00323', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.3),
    (N'SCR001545', N'ENR00325', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.9),
    (N'SCR001546', N'ENR00325', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.6),
    (N'SCR001547', N'ENR00325', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.8),
    (N'SCR001548', N'ENR00330', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.3),
    (N'SCR001549', N'ENR00330', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.8),
    (N'SCR001550', N'ENR00330', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.6),
    (N'SCR001551', N'ENR00331', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.2),
    (N'SCR001552', N'ENR00331', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.5),
    (N'SCR001553', N'ENR00333', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.8),
    (N'SCR001554', N'ENR00333', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.4),
    (N'SCR001555', N'ENR00333', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.4),
    (N'SCR001556', N'ENR00334', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.9),
    (N'SCR001557', N'ENR00334', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.9),
    (N'SCR001558', N'ENR00336', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.9),
    (N'SCR001559', N'ENR00336', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001560', N'ENR00338', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.6),
    (N'SCR001561', N'ENR00338', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.1),
    (N'SCR001562', N'ENR00339', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.6),
    (N'SCR001563', N'ENR00339', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.2),
    (N'SCR001564', N'ENR00339', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.6),
    (N'SCR001565', N'ENR00340', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 20.0),
    (N'SCR001566', N'ENR00340', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0);
GO

INSERT INTO dbo.student_assessment_scores (score_id, enrollment_id, component_id, score) VALUES
    (N'SCR001567', N'ENR00340', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001568', N'ENR00344', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.5),
    (N'SCR001569', N'ENR00344', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.0),
    (N'SCR001570', N'ENR00345', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.4),
    (N'SCR001571', N'ENR00345', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.4),
    (N'SCR001572', N'ENR00345', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.7),
    (N'SCR001573', N'ENR00347', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.7),
    (N'SCR001574', N'ENR00347', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001575', N'ENR00349', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.4),
    (N'SCR001576', N'ENR00349', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.6),
    (N'SCR001577', N'ENR00349', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.7),
    (N'SCR001578', N'ENR00352', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 9.7),
    (N'SCR001579', N'ENR00352', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.2),
    (N'SCR001580', N'ENR00353', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.2),
    (N'SCR001581', N'ENR00353', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.3),
    (N'SCR001582', N'ENR00353', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 4.2),
    (N'SCR001583', N'ENR00355', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.3),
    (N'SCR001584', N'ENR00355', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.4),
    (N'SCR001585', N'ENR00356', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.1),
    (N'SCR001586', N'ENR00356', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR001587', N'ENR00357', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.2),
    (N'SCR001588', N'ENR00357', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR001589', N'ENR00358', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.1),
    (N'SCR001590', N'ENR00358', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR001591', N'ENR00359', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.0),
    (N'SCR001592', N'ENR00359', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.6),
    (N'SCR001593', N'ENR00361', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.2),
    (N'SCR001594', N'ENR00361', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.0),
    (N'SCR001595', N'ENR00361', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.5),
    (N'SCR001596', N'ENR00362', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.9),
    (N'SCR001597', N'ENR00362', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR001598', N'ENR00362', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.2),
    (N'SCR001599', N'ENR00364', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.7),
    (N'SCR001600', N'ENR00364', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.4),
    (N'SCR001601', N'ENR00364', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.4),
    (N'SCR001602', N'ENR00365', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.9),
    (N'SCR001603', N'ENR00365', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.7),
    (N'SCR001604', N'ENR00366', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.5),
    (N'SCR001605', N'ENR00366', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR001606', N'ENR00367', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 8.3),
    (N'SCR001607', N'ENR00367', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 4.8),
    (N'SCR001608', N'ENR00368', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.1),
    (N'SCR001609', N'ENR00368', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.8),
    (N'SCR001610', N'ENR00370', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.8),
    (N'SCR001611', N'ENR00370', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.7),
    (N'SCR001612', N'ENR00372', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.8),
    (N'SCR001613', N'ENR00372', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.3),
    (N'SCR001614', N'ENR00372', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.8),
    (N'SCR001615', N'ENR00373', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.7),
    (N'SCR001616', N'ENR00373', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.7),
    (N'SCR001617', N'ENR00374', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.1),
    (N'SCR001618', N'ENR00374', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR001619', N'ENR00374', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.8),
    (N'SCR001620', N'ENR00376', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.4),
    (N'SCR001621', N'ENR00376', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR001622', N'ENR00377', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.9),
    (N'SCR001623', N'ENR00377', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.7),
    (N'SCR001624', N'ENR00378', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.9),
    (N'SCR001625', N'ENR00378', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.3),
    (N'SCR001626', N'ENR00379', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.3),
    (N'SCR001627', N'ENR00379', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.1),
    (N'SCR001628', N'ENR00379', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.9),
    (N'SCR001629', N'ENR00382', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.8),
    (N'SCR001630', N'ENR00382', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.7),
    (N'SCR001631', N'ENR00382', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.1),
    (N'SCR001632', N'ENR00384', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.1),
    (N'SCR001633', N'ENR00384', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.1),
    (N'SCR001634', N'ENR00384', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.1),
    (N'SCR001635', N'ENR00386', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 8.7),
    (N'SCR001636', N'ENR00386', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.7),
    (N'SCR001637', N'ENR00390', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 20.0),
    (N'SCR001638', N'ENR00390', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.9),
    (N'SCR001639', N'ENR00390', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001640', N'ENR00391', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.7),
    (N'SCR001641', N'ENR00391', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.7),
    (N'SCR001642', N'ENR00392', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.2),
    (N'SCR001643', N'ENR00392', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.6),
    (N'SCR001644', N'ENR00392', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001645', N'ENR00394', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.7),
    (N'SCR001646', N'ENR00394', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.3),
    (N'SCR001647', N'ENR00395', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.1),
    (N'SCR001648', N'ENR00395', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR001649', N'ENR00397', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.7),
    (N'SCR001650', N'ENR00397', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.6),
    (N'SCR001651', N'ENR00397', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.0),
    (N'SCR001652', N'ENR00398', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.3),
    (N'SCR001653', N'ENR00398', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.4),
    (N'SCR001654', N'ENR00398', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.6),
    (N'SCR001655', N'ENR00400', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.0),
    (N'SCR001656', N'ENR00400', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR001657', N'ENR00400', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.9),
    (N'SCR001658', N'ENR00401', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.5),
    (N'SCR001659', N'ENR00401', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR001660', N'ENR00401', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.9),
    (N'SCR001661', N'ENR00402', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.1),
    (N'SCR001662', N'ENR00402', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.8),
    (N'SCR001663', N'ENR00402', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.0),
    (N'SCR001664', N'ENR00403', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.5),
    (N'SCR001665', N'ENR00403', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.5),
    (N'SCR001666', N'ENR00405', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.2),
    (N'SCR001667', N'ENR00405', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.9),
    (N'SCR001668', N'ENR00407', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.5),
    (N'SCR001669', N'ENR00407', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.8),
    (N'SCR001670', N'ENR00413', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.2),
    (N'SCR001671', N'ENR00413', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.1),
    (N'SCR001672', N'ENR00414', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.2),
    (N'SCR001673', N'ENR00414', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.0),
    (N'SCR001674', N'ENR00417', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.1),
    (N'SCR001675', N'ENR00417', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.1),
    (N'SCR001676', N'ENR00417', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.7),
    (N'SCR001677', N'ENR00422', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.8),
    (N'SCR001678', N'ENR00422', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.1),
    (N'SCR001679', N'ENR00422', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.5),
    (N'SCR001680', N'ENR00423', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.3),
    (N'SCR001681', N'ENR00423', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR001682', N'ENR00423', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.2),
    (N'SCR001683', N'ENR00424', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.0),
    (N'SCR001684', N'ENR00424', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR001685', N'ENR00425', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.8),
    (N'SCR001686', N'ENR00425', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.1),
    (N'SCR001687', N'ENR00425', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.1),
    (N'SCR001688', N'ENR00428', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.9),
    (N'SCR001689', N'ENR00428', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.8),
    (N'SCR001690', N'ENR00428', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.2),
    (N'SCR001691', N'ENR00429', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.3),
    (N'SCR001692', N'ENR00429', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 4.9),
    (N'SCR001693', N'ENR00430', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.1),
    (N'SCR001694', N'ENR00430', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.9),
    (N'SCR001695', N'ENR00434', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.8),
    (N'SCR001696', N'ENR00434', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.9),
    (N'SCR001697', N'ENR00434', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.4),
    (N'SCR001698', N'ENR00435', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.9),
    (N'SCR001699', N'ENR00435', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.6),
    (N'SCR001700', N'ENR00435', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.3),
    (N'SCR001701', N'ENR00436', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.7),
    (N'SCR001702', N'ENR00436', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.7),
    (N'SCR001703', N'ENR00436', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.9),
    (N'SCR001704', N'ENR00439', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.3),
    (N'SCR001705', N'ENR00439', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.5),
    (N'SCR001706', N'ENR00439', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.9),
    (N'SCR001707', N'ENR00440', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.6),
    (N'SCR001708', N'ENR00440', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.4),
    (N'SCR001709', N'ENR00440', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.4),
    (N'SCR001710', N'ENR00442', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.8),
    (N'SCR001711', N'ENR00442', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001712', N'ENR00442', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001713', N'ENR00443', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 11.0),
    (N'SCR001714', N'ENR00443', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.1),
    (N'SCR001715', N'ENR00443', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.1),
    (N'SCR001716', N'ENR00444', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.1),
    (N'SCR001717', N'ENR00444', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 4.1),
    (N'SCR001718', N'ENR00445', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 10.9),
    (N'SCR001719', N'ENR00445', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.1),
    (N'SCR001720', N'ENR00445', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.0),
    (N'SCR001721', N'ENR00446', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.1),
    (N'SCR001722', N'ENR00446', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 5.7),
    (N'SCR001723', N'ENR00446', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 5.7),
    (N'SCR001724', N'ENR00448', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.9),
    (N'SCR001725', N'ENR00448', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001726', N'ENR00448', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001727', N'ENR00449', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.9),
    (N'SCR001728', N'ENR00449', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.9),
    (N'SCR001729', N'ENR00450', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.0),
    (N'SCR001730', N'ENR00450', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.9),
    (N'SCR001731', N'ENR00450', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.7),
    (N'SCR001732', N'ENR00454', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.9),
    (N'SCR001733', N'ENR00454', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001734', N'ENR00454', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001735', N'ENR00456', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 19.7),
    (N'SCR001736', N'ENR00456', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 10.0),
    (N'SCR001737', N'ENR00456', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.9),
    (N'SCR001738', N'ENR00457', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.8),
    (N'SCR001739', N'ENR00457', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.4),
    (N'SCR001740', N'ENR00457', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.9),
    (N'SCR001741', N'ENR00458', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.9),
    (N'SCR001742', N'ENR00458', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.1),
    (N'SCR001743', N'ENR00458', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.9),
    (N'SCR001744', N'ENR00460', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.1),
    (N'SCR001745', N'ENR00460', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.9),
    (N'SCR001746', N'ENR00460', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.1),
    (N'SCR001747', N'ENR00461', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.0),
    (N'SCR001748', N'ENR00461', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.1),
    (N'SCR001749', N'ENR00463', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 12.3),
    (N'SCR001750', N'ENR00463', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.1),
    (N'SCR001751', N'ENR00463', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.8),
    (N'SCR001752', N'ENR00466', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.0),
    (N'SCR001753', N'ENR00466', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.2),
    (N'SCR001754', N'ENR00466', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.3),
    (N'SCR001755', N'ENR00467', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.8),
    (N'SCR001756', N'ENR00467', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001757', N'ENR00469', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.2),
    (N'SCR001758', N'ENR00469', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.2),
    (N'SCR001759', N'ENR00469', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.7),
    (N'SCR001760', N'ENR00478', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.4),
    (N'SCR001761', N'ENR00478', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR001762', N'ENR00478', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.1),
    (N'SCR001763', N'ENR00479', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 13.1),
    (N'SCR001764', N'ENR00479', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.6),
    (N'SCR001765', N'ENR00480', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.8),
    (N'SCR001766', N'ENR00480', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.2),
    (N'SCR001767', N'ENR00480', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR001768', N'ENR00485', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.5),
    (N'SCR001769', N'ENR00485', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.0),
    (N'SCR001770', N'ENR00485', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 9.3),
    (N'SCR001771', N'ENR00486', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.8),
    (N'SCR001772', N'ENR00486', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.0),
    (N'SCR001773', N'ENR00493', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.1),
    (N'SCR001774', N'ENR00493', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR001775', N'ENR00495', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.0),
    (N'SCR001776', N'ENR00495', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.6),
    (N'SCR001777', N'ENR00496', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.3),
    (N'SCR001778', N'ENR00496', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.0),
    (N'SCR001779', N'ENR00497', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 18.8),
    (N'SCR001780', N'ENR00497', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 9.3),
    (N'SCR001781', N'ENR00497', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 10.0),
    (N'SCR001782', N'ENR00500', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.3),
    (N'SCR001783', N'ENR00500', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.8),
    (N'SCR001784', N'ENR00501', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 16.1),
    (N'SCR001785', N'ENR00501', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.3),
    (N'SCR001786', N'ENR00502', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.7),
    (N'SCR001787', N'ENR00502', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.1),
    (N'SCR001788', N'ENR00503', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.1),
    (N'SCR001789', N'ENR00503', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.1),
    (N'SCR001790', N'ENR00504', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.1),
    (N'SCR001791', N'ENR00504', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.2),
    (N'SCR001792', N'ENR00504', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 6.6),
    (N'SCR001793', N'ENR00508', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 15.0),
    (N'SCR001794', N'ENR00508', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 6.9),
    (N'SCR001795', N'ENR00508', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 8.4),
    (N'SCR001796', N'ENR00511', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 14.7),
    (N'SCR001797', N'ENR00511', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 7.7),
    (N'SCR001798', N'ENR00511', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'CW'), 7.2),
    (N'SCR001799', N'ENR00513', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 17.4),
    (N'SCR001800', N'ENR00513', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.4),
    (N'SCR001801', N'ENR00514', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_LEC'), 20.0),
    (N'SCR001802', N'ENR00514', (SELECT component_id FROM dbo.assessment_components WHERE component_code = N'W7_SEC'), 8.5);
GO


-- ============================================================
-- 9. FINAL VERIFICATION
-- ============================================================

SELECT 'departments' AS item, COUNT(*) AS count_value FROM dbo.departments
UNION ALL SELECT 'majors', COUNT(*) FROM dbo.majors
UNION ALL SELECT 'students', COUNT(*) FROM dbo.students
UNION ALL SELECT 'instructors', COUNT(*) FROM dbo.instructors
UNION ALL SELECT 'admins', COUNT(*) FROM dbo.admins
UNION ALL SELECT 'courses', COUNT(*) FROM dbo.courses
UNION ALL SELECT 'course_offerings', COUNT(*) FROM dbo.course_offerings
UNION ALL SELECT 'room_schedule', COUNT(*) FROM dbo.room_schedule
UNION ALL SELECT 'enrollments', COUNT(*) FROM dbo.enrollments
UNION ALL SELECT 'assessment_scores', COUNT(*) FROM dbo.student_assessment_scores;
GO

-- Room type rule must return 0 rows.
SELECT
    'INVALID_ROOM_MEETING_TYPE' AS issue,
    rs.schedule_id,
    rs.offering_id,
    rs.meeting_type,
    rs.room_id,
    r.room_type
FROM dbo.room_schedule rs
JOIN dbo.rooms r
    ON rs.room_id = r.room_id
WHERE
    (rs.meeting_type IN ('LECTURE', 'SECTION') AND r.room_type <> 'LECTURE')
    OR
    (rs.meeting_type = 'LAB' AND r.room_type <> 'LAB');
GO

-- Room conflicts must return 0 rows.
SELECT
    'ROOM_CONFLICT' AS issue,
    room_id,
    day_of_week,
    slot_id,
    COUNT(*) AS conflict_count
FROM dbo.room_schedule
GROUP BY room_id, day_of_week, slot_id
HAVING COUNT(*) > 1;
GO

-- Instructor conflicts must return 0 rows.
SELECT
    'INSTRUCTOR_CONFLICT' AS issue,
    instructor_id,
    day_of_week,
    slot_id,
    COUNT(*) AS conflict_count
FROM dbo.room_schedule
WHERE instructor_id IS NOT NULL
GROUP BY instructor_id, day_of_week, slot_id
HAVING COUNT(*) > 1;
GO

-- Student active schedule conflicts must return 0 rows.
SELECT
    'STUDENT_SCHEDULE_CONFLICT' AS issue,
    e.student_id,
    rs.day_of_week,
    rs.slot_id,
    COUNT(*) AS conflict_count
FROM dbo.enrollments e
JOIN dbo.room_schedule rs
    ON e.offering_id = rs.offering_id
WHERE e.status = 'ENROLLED'
GROUP BY e.student_id, rs.day_of_week, rs.slot_id
HAVING COUNT(*) > 1;
GO

-- Sample logins
SELECT 'Student sample' AS account_type, 'student001@university.edu' AS email, 'stu123' AS password
UNION ALL SELECT 'Instructor sample', 'instructor001@university.edu', 'ins123'
UNION ALL SELECT 'Admin sample', 'super.admin@university.edu', 'admin123';
GO

SELECT TOP 20 *
FROM dbo.vw_course_full
ORDER BY course_id, section_code;
GO

SELECT TOP 20 *
FROM dbo.vw_student_full
ORDER BY id;
GO

SELECT TOP 20 *
FROM dbo.vw_instructor_full
ORDER BY id;
GO

/* ========== PART 3: COURSE ACADEMIC PLAN TABLE + DATA ========== */

USE [UniversityDB];
GO

/* ============================================================
   STEP SQL-01
   Add course_academic_plan table for Option B:
   Course catalog stays general.
   Course offerings can filter courses by Major + Year + Term.
   ============================================================ */

/* 
   Fixed version:
   Your majors.major_id column has a different length than NVARCHAR(20),
   so the first script failed when creating the FK.

   This version reads the exact data type + length from:
   - dbo.courses.course_id
   - dbo.majors.major_id

   Then it creates course_academic_plan with matching column definitions.
*/

IF OBJECT_ID('dbo.course_academic_plan', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.course_academic_plan;
END;
GO

DECLARE @courseIdType NVARCHAR(300);
DECLARE @majorIdType NVARCHAR(300);
DECLARE @createSql NVARCHAR(MAX);

SELECT @courseIdType =
    CASE TYPE_NAME(c.user_type_id)
        WHEN 'nvarchar' THEN N'NVARCHAR(' + CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length / 2 AS NVARCHAR(20)) END + N')'
        WHEN 'nchar'    THEN N'NCHAR('    + CAST(c.max_length / 2 AS NVARCHAR(20)) + N')'
        WHEN 'varchar'  THEN N'VARCHAR('  + CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length AS NVARCHAR(20)) END + N')'
        WHEN 'char'     THEN N'CHAR('     + CAST(c.max_length AS NVARCHAR(20)) + N')'
        ELSE UPPER(TYPE_NAME(c.user_type_id))
    END +
    CASE
        WHEN c.collation_name IS NOT NULL THEN N' COLLATE ' + c.collation_name
        ELSE N''
    END
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('dbo.courses')
  AND c.name = 'course_id';

SELECT @majorIdType =
    CASE TYPE_NAME(c.user_type_id)
        WHEN 'nvarchar' THEN N'NVARCHAR(' + CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length / 2 AS NVARCHAR(20)) END + N')'
        WHEN 'nchar'    THEN N'NCHAR('    + CAST(c.max_length / 2 AS NVARCHAR(20)) + N')'
        WHEN 'varchar'  THEN N'VARCHAR('  + CASE WHEN c.max_length = -1 THEN N'MAX' ELSE CAST(c.max_length AS NVARCHAR(20)) END + N')'
        WHEN 'char'     THEN N'CHAR('     + CAST(c.max_length AS NVARCHAR(20)) + N')'
        ELSE UPPER(TYPE_NAME(c.user_type_id))
    END +
    CASE
        WHEN c.collation_name IS NOT NULL THEN N' COLLATE ' + c.collation_name
        ELSE N''
    END
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('dbo.majors')
  AND c.name = 'major_id';

IF @courseIdType IS NULL
BEGIN
    THROW 52001, 'Could not read dbo.courses.course_id data type.', 1;
END;

IF @majorIdType IS NULL
BEGIN
    THROW 52002, 'Could not read dbo.majors.major_id data type.', 1;
END;

SET @createSql = N'
CREATE TABLE dbo.course_academic_plan (
    plan_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    course_id ' + @courseIdType + N' NOT NULL,
    major_id ' + @majorIdType + N' NOT NULL,
    student_year INT NOT NULL,
    recommended_term NVARCHAR(20) NOT NULL,
    is_required BIT NOT NULL CONSTRAINT DF_course_academic_plan_required DEFAULT 1,
    is_active BIT NOT NULL CONSTRAINT DF_course_academic_plan_active DEFAULT 1,
    notes NVARCHAR(500) NULL,

    CONSTRAINT FK_course_academic_plan_course
        FOREIGN KEY (course_id) REFERENCES dbo.courses(course_id),

    CONSTRAINT FK_course_academic_plan_major
        FOREIGN KEY (major_id) REFERENCES dbo.majors(major_id),

    CONSTRAINT CK_course_academic_plan_year
        CHECK (student_year BETWEEN 1 AND 7),

    CONSTRAINT CK_course_academic_plan_term
        CHECK (recommended_term IN (N''TERM1'', N''TERM2'', N''SUMMER'')),

    CONSTRAINT UQ_course_academic_plan
        UNIQUE (course_id, major_id, student_year, recommended_term)
);';

EXEC sp_executesql @createSql;
GO

/* Make this script safe to rerun. */
DELETE FROM dbo.course_academic_plan;
GO

/* ============================================================
   Realistic academic-plan mappings.
   This is not the real offering table.
   It only says which course is normally recommended for:
   Major + Student Year + Term.
   ============================================================ */

INSERT INTO dbo.course_academic_plan
(course_id, major_id, student_year, recommended_term, is_required, is_active, notes)
SELECT v.course_id, v.major_id, v.student_year, v.recommended_term, v.is_required, 1, v.notes
FROM (VALUES
    /* Computer Science & Informatics majors */
    (N'CS101', N'MCS', 1, N'TERM1', 1, N'Programming foundation'),
    (N'CS102', N'MCS', 1, N'TERM2', 1, N'Object-oriented programming'),
    (N'CS201', N'MCS', 2, N'TERM1', 1, N'Data structures'),
    (N'CS202', N'MCS', 2, N'TERM2', 1, N'Database systems'),
    (N'CS301', N'MCS', 3, N'TERM1', 1, N'Operating systems'),
    (N'CS302', N'MCS', 3, N'TERM2', 1, N'Computer networks'),
    (N'CS401', N'MCS', 4, N'TERM1', 0, N'AI elective/core'),
    (N'CS405', N'MCS', 4, N'TERM2', 0, N'Security elective'),

    (N'CS101', N'MSE', 1, N'TERM1', 1, N'Programming foundation'),
    (N'CS102', N'MSE', 1, N'TERM2', 1, N'OOP for software engineering'),
    (N'CS201', N'MSE', 2, N'TERM1', 1, N'Data structures'),
    (N'CS202', N'MSE', 2, N'TERM2', 1, N'Databases for applications'),
    (N'CS301', N'MSE', 3, N'TERM1', 1, N'OS concepts'),
    (N'CS302', N'MSE', 3, N'TERM2', 1, N'Networks'),
    (N'CS401', N'MSE', 4, N'TERM1', 0, N'AI elective'),

    (N'CS101', N'MAI', 1, N'TERM1', 1, N'Programming foundation'),
    (N'CS102', N'MAI', 1, N'TERM2', 1, N'OOP'),
    (N'CS201', N'MAI', 2, N'TERM1', 1, N'Data structures'),
    (N'CS202', N'MAI', 2, N'TERM2', 1, N'Databases'),
    (N'CS401', N'MAI', 3, N'TERM1', 1, N'Artificial intelligence'),
    (N'CS302', N'MAI', 3, N'TERM2', 0, N'Networks'),
    (N'CS405', N'MAI', 4, N'TERM2', 0, N'Security'),

    (N'CS101', N'MCY', 1, N'TERM1', 1, N'Programming foundation'),
    (N'CS102', N'MCY', 1, N'TERM2', 1, N'OOP'),
    (N'CS201', N'MCY', 2, N'TERM1', 1, N'Data structures'),
    (N'CS302', N'MCY', 2, N'TERM2', 1, N'Computer networks'),
    (N'CS405', N'MCY', 3, N'TERM1', 1, N'Cybersecurity fundamentals'),
    (N'CS301', N'MCY', 3, N'TERM2', 1, N'Operating systems'),

    (N'CS101', N'MDS', 1, N'TERM1', 1, N'Programming foundation'),
    (N'CS102', N'MDS', 1, N'TERM2', 1, N'OOP'),
    (N'CS201', N'MDS', 2, N'TERM1', 1, N'Data structures'),
    (N'CS202', N'MDS', 2, N'TERM2', 1, N'Database systems'),
    (N'CS401', N'MDS', 3, N'TERM1', 0, N'AI elective'),

    /* Engineering majors */
    (N'ENG101', N'MEMT', 1, N'TERM1', 1, N'Engineering mathematics'),
    (N'ENG102', N'MEMT', 1, N'TERM2', 1, N'Engineering physics'),
    (N'ENG201', N'MEMT', 2, N'TERM1', 1, N'Thermodynamics'),
    (N'ENG202', N'MEMT', 2, N'TERM2', 1, N'Circuit analysis'),
    (N'ENG305', N'MEMT', 3, N'TERM1', 1, N'Control systems'),

    (N'ENG101', N'MELC', 1, N'TERM1', 1, N'Engineering mathematics'),
    (N'ENG102', N'MELC', 1, N'TERM2', 1, N'Engineering physics'),
    (N'ENG202', N'MELC', 2, N'TERM1', 1, N'Circuit analysis'),
    (N'ENG305', N'MELC', 3, N'TERM1', 1, N'Control systems'),

    (N'ENG101', N'MMEC', 1, N'TERM1', 1, N'Engineering mathematics'),
    (N'ENG102', N'MMEC', 1, N'TERM2', 1, N'Engineering physics'),
    (N'ENG201', N'MMEC', 2, N'TERM1', 1, N'Thermodynamics'),
    (N'ENG305', N'MMEC', 3, N'TERM1', 1, N'Control systems'),

    (N'ENG101', N'MCIV', 1, N'TERM1', 1, N'Engineering mathematics'),
    (N'ENG102', N'MCIV', 1, N'TERM2', 1, N'Engineering physics'),
    (N'ENG301', N'MCIV', 3, N'TERM1', 1, N'Structural engineering'),

    /* Pharmacy */
    (N'PH101', N'MPHD', 1, N'TERM1', 1, N'Human anatomy'),
    (N'PH102', N'MPHD', 1, N'TERM2', 1, N'Organic chemistry'),
    (N'PH201', N'MPHD', 2, N'TERM1', 1, N'Pharmacology'),
    (N'PH301', N'MPHD', 3, N'TERM1', 1, N'Clinical pharmacy'),
    (N'PH401', N'MPHD', 4, N'TERM2', 1, N'Quality control'),

    (N'PH101', N'MCPH', 1, N'TERM1', 1, N'Human anatomy'),
    (N'PH102', N'MCPH', 1, N'TERM2', 1, N'Organic chemistry'),
    (N'PH201', N'MCPH', 2, N'TERM1', 1, N'Pharmacology'),
    (N'PH301', N'MCPH', 3, N'TERM1', 1, N'Clinical pharmacy'),

    (N'PH101', N'MPSC', 1, N'TERM1', 1, N'Human anatomy'),
    (N'PH102', N'MPSC', 1, N'TERM2', 1, N'Organic chemistry'),
    (N'PH201', N'MPSC', 2, N'TERM1', 1, N'Pharmacology'),
    (N'PH401', N'MPSC', 4, N'TERM2', 1, N'Quality control'),

    /* Medicine and health sciences */
    (N'MED101', N'MMBS', 1, N'TERM1', 1, N'Medical biology'),
    (N'MED102', N'MMBS', 1, N'TERM2', 1, N'Human physiology'),
    (N'MED201', N'MMBS', 2, N'TERM1', 1, N'Pathology'),
    (N'MED301', N'MMBS', 3, N'TERM1', 1, N'Clinical skills'),
    (N'MED401', N'MMBS', 4, N'TERM2', 1, N'Community medicine'),

    (N'MED101', N'MNUR', 1, N'TERM1', 1, N'Medical biology'),
    (N'MED102', N'MNUR', 1, N'TERM2', 1, N'Physiology'),
    (N'MED201', N'MNUR', 2, N'TERM1', 1, N'Pathology basics'),
    (N'MED401', N'MNUR', 3, N'TERM2', 1, N'Community medicine'),

    (N'MED101', N'MMLS', 1, N'TERM1', 1, N'Medical biology'),
    (N'MED102', N'MMLS', 1, N'TERM2', 1, N'Human physiology'),
    (N'MED201', N'MMLS', 2, N'TERM1', 1, N'Pathology basics'),

    (N'MED101', N'MRAD', 1, N'TERM1', 1, N'Medical biology'),
    (N'MED102', N'MRAD', 1, N'TERM2', 1, N'Physiology'),
    (N'MED401', N'MRAD', 3, N'TERM2', 1, N'Community medicine'),

    /* Business majors */
    (N'BUS101', N'MACC', 1, N'TERM1', 1, N'Business foundation'),
    (N'ACC201', N'MACC', 2, N'TERM1', 1, N'Accounting core'),
    (N'FIN201', N'MACC', 2, N'TERM2', 1, N'Finance support'),
    (N'BIS301', N'MACC', 3, N'TERM1', 0, N'Business systems'),

    (N'BUS101', N'MFIN', 1, N'TERM1', 1, N'Business foundation'),
    (N'FIN201', N'MFIN', 2, N'TERM1', 1, N'Corporate finance'),
    (N'ACC201', N'MFIN', 2, N'TERM2', 1, N'Accounting support'),

    (N'BUS101', N'MMKT', 1, N'TERM1', 1, N'Business foundation'),
    (N'MKT201', N'MMKT', 2, N'TERM1', 1, N'Marketing core'),
    (N'BIS301', N'MMKT', 3, N'TERM1', 0, N'Business systems'),

    (N'BUS101', N'MBIS', 1, N'TERM1', 1, N'Business foundation'),
    (N'BIS301', N'MBIS', 2, N'TERM1', 1, N'Business information systems'),
    (N'ACC201', N'MBIS', 2, N'TERM2', 1, N'Accounting support'),

    /* Dentistry */
    (N'DEN101', N'MODM', 1, N'TERM1', 1, N'Dental anatomy'),
    (N'DEN201', N'MODM', 2, N'TERM1', 1, N'Oral histology'),
    (N'DEN301', N'MODM', 3, N'TERM1', 1, N'Operative dentistry'),
    (N'DEN401', N'MODM', 4, N'TERM2', 1, N'Oral surgery'),

    (N'DEN101', N'MDSG', 1, N'TERM1', 1, N'Dental anatomy'),
    (N'DEN201', N'MDSG', 2, N'TERM1', 1, N'Oral histology'),
    (N'DEN301', N'MDSG', 3, N'TERM1', 1, N'Operative dentistry'),
    (N'DEN401', N'MDSG', 4, N'TERM2', 1, N'Oral surgery'),

    /* Arts */
    (N'ART101', N'MGRA', 1, N'TERM1', 1, N'Design fundamentals'),
    (N'DES201', N'MGRA', 2, N'TERM1', 1, N'Digital illustration'),
    (N'ANI301', N'MGRA', 3, N'TERM1', 0, N'Animation elective'),

    (N'ART101', N'MINT', 1, N'TERM1', 1, N'Design fundamentals'),
    (N'DES201', N'MINT', 2, N'TERM1', 1, N'Digital illustration'),

    (N'ART101', N'MDM', 1, N'TERM1', 1, N'Design fundamentals'),
    (N'DGM201', N'MDM', 2, N'TERM1', 1, N'Digital media production'),
    (N'ANI301', N'MDM', 3, N'TERM1', 1, N'Animation principles'),

    /* Media */
    (N'MCM101', N'MJRN', 1, N'TERM1', 1, N'Mass communication foundation'),
    (N'JRN201', N'MJRN', 2, N'TERM1', 1, N'News writing'),
    (N'PR301', N'MJRN', 3, N'TERM2', 0, N'PR campaigns'),

    (N'MCM101', N'MPR', 1, N'TERM1', 1, N'Mass communication foundation'),
    (N'PR301', N'MPR', 3, N'TERM1', 1, N'PR campaigns'),
    (N'JRN201', N'MPR', 2, N'TERM2', 0, N'News writing support'),

    (N'MCM101', N'MRTV', 1, N'TERM1', 1, N'Mass communication foundation'),
    (N'DGM201', N'MRTV', 2, N'TERM1', 0, N'Digital media production'),
    (N'MCM101', N'MRTV', 1, N'SUMMER', 0, N'Summer repeat/high-demand option')
) AS v(course_id, major_id, student_year, recommended_term, is_required, notes)
WHERE EXISTS (SELECT 1 FROM dbo.courses c WHERE c.course_id = v.course_id)
  AND EXISTS (SELECT 1 FROM dbo.majors m WHERE m.major_id = v.major_id);
GO

CREATE INDEX IX_course_academic_plan_lookup
ON dbo.course_academic_plan (major_id, student_year, recommended_term, is_active)
INCLUDE (course_id, is_required);
GO

/* Verification */
SELECT 'course_academic_plan rows' AS item, COUNT(*) AS count_value
FROM dbo.course_academic_plan;

SELECT TOP 30
    m.major_name,
    cap.student_year,
    cap.recommended_term,
    cap.course_id,
    c.course_name,
    cap.is_required
FROM dbo.course_academic_plan cap
JOIN dbo.majors m ON cap.major_id = m.major_id
JOIN dbo.courses c ON cap.course_id = c.course_id
ORDER BY m.major_name, cap.student_year, cap.recommended_term, cap.course_id;
GO


/* ========== PART 4: NORMALIZE OFFERING STATUS OPEN/CLOSED ========== */

USE [UniversityDB];
GO

/* ============================================================
   Normalize course offering status for the admin UI rule:
   Course offerings should be OPEN only for the active selected term,
   and CLOSED otherwise.

   Default active term here: TERM1 2026.
   Change @ActiveTerm / @AcademicYear before running if needed.
   ============================================================ */

DECLARE @ActiveTerm NVARCHAR(20) = N'TERM1';
DECLARE @AcademicYear INT = 2026;

UPDATE dbo.course_offerings
SET status =
    CASE
        WHEN term = @ActiveTerm AND academic_year = @AcademicYear THEN N'OPEN'
        ELSE N'CLOSED'
    END;

SELECT
    term,
    academic_year,
    status,
    COUNT(*) AS offering_count
FROM dbo.course_offerings
GROUP BY term, academic_year, status
ORDER BY academic_year DESC, term, status;
GO


/* ===================== PART 5: JAVA SQL LOGIN ===================== */


USE [master];
GO

/* ============================================================
   JAVA APP SQL LOGIN
   This matches DatabaseManager.java defaults:
   server   = localhost
   database = UniversityDB
   user     = university_user
   password = UniPass123!
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM sys.sql_logins
    WHERE name = N'university_user'
)
BEGIN
    CREATE LOGIN [university_user]
    WITH PASSWORD = N'UniPass123!',
         CHECK_POLICY = OFF,
         CHECK_EXPIRATION = OFF;
END;
GO

USE [UniversityDB];
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'university_user'
)
BEGIN
    CREATE USER [university_user] FOR LOGIN [university_user];
END;
GO

IF IS_ROLEMEMBER('db_owner', 'university_user') = 0
BEGIN
    ALTER ROLE [db_owner] ADD MEMBER [university_user];
END;
GO


/* ===================== PART 6: FINAL CHECK ===================== */


USE [UniversityDB];
GO

/* ============================================================
   FINAL VERIFICATION
   ============================================================ */

SELECT 'departments' AS table_name, COUNT(*) AS count_value FROM dbo.departments
UNION ALL SELECT 'majors', COUNT(*) FROM dbo.majors
UNION ALL SELECT 'students', COUNT(*) FROM dbo.students
UNION ALL SELECT 'instructors', COUNT(*) FROM dbo.instructors
UNION ALL SELECT 'admins', COUNT(*) FROM dbo.admins
UNION ALL SELECT 'courses', COUNT(*) FROM dbo.courses
UNION ALL SELECT 'course_academic_plan', COUNT(*) FROM dbo.course_academic_plan
UNION ALL SELECT 'course_offerings', COUNT(*) FROM dbo.course_offerings
UNION ALL SELECT 'room_schedule', COUNT(*) FROM dbo.room_schedule
UNION ALL SELECT 'enrollments', COUNT(*) FROM dbo.enrollments
UNION ALL SELECT 'student_assessment_scores', COUNT(*) FROM dbo.student_assessment_scores;
GO

SELECT 'Admin sample' AS account_type, 'super.admin@university.edu' AS email, 'admin123' AS password
UNION ALL SELECT 'Student sample', 'student001@university.edu', 'stu123'
UNION ALL SELECT 'Instructor sample', 'instructor001@university.edu', 'ins123';
GO
