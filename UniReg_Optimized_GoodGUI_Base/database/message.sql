USE [master]
GO
/****** Object:  Database [UniversityDB]    Script Date: 5/31/226 6:59:50 PM ******/
CREATE DATABASE [UniversityDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'UniversityDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\UniversityDB.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'UniversityDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\UniversityDB_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [UniversityDB] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [UniversityDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [UniversityDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [UniversityDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [UniversityDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [UniversityDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [UniversityDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [UniversityDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [UniversityDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [UniversityDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [UniversityDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [UniversityDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [UniversityDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [UniversityDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [UniversityDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [UniversityDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [UniversityDB] SET  ENABLE_BROKER 
GO
ALTER DATABASE [UniversityDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [UniversityDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [UniversityDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [UniversityDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [UniversityDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [UniversityDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [UniversityDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [UniversityDB] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [UniversityDB] SET  MULTI_USER 
GO
ALTER DATABASE [UniversityDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [UniversityDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [UniversityDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [UniversityDB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [UniversityDB] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [UniversityDB] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'UniversityDB', N'ON'
GO
ALTER DATABASE [UniversityDB] SET QUERY_STORE = OFF
GO
USE [UniversityDB]
GO
/****** Object:  User [university_user]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE USER [university_user] FOR LOGIN [university_user] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [university_user]
GO
/****** Object:  Table [dbo].[enrollments]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[enrollments](
	[enrollment_id] [nvarchar](50) NOT NULL,
	[student_id] [nvarchar](20) NOT NULL,
	[offering_id] [nvarchar](20) NOT NULL,
	[enrollment_date] [datetime2](7) NULL,
	[status] [nvarchar](20) NULL,
 CONSTRAINT [PK_enrollments] PRIMARY KEY CLUSTERED 
(
	[enrollment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_enrollment_student_offering] UNIQUE NONCLUSTERED 
(
	[student_id] ASC,
	[offering_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_course_enrollment]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  Table [dbo].[room_schedule]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[room_schedule](
	[schedule_id] [int] IDENTITY(1,1) NOT NULL,
	[offering_id] [nvarchar](20) NOT NULL,
	[room_id] [nvarchar](20) NOT NULL,
	[instructor_id] [nvarchar](20) NULL,
	[day_of_week] [nvarchar](20) NOT NULL,
	[slot_id] [int] NOT NULL,
	[meeting_type] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_room_schedule] PRIMARY KEY CLUSTERED 
(
	[schedule_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_offering_schedule] UNIQUE NONCLUSTERED 
(
	[offering_id] ASC,
	[day_of_week] ASC,
	[slot_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[departments]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[departments](
	[department_id] [nvarchar](10) NOT NULL,
	[department_name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](500) NULL,
	[created_at] [datetime2](7) NULL,
 CONSTRAINT [PK_departments] PRIMARY KEY CLUSTERED 
(
	[department_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[time_slots]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[time_slots](
	[slot_id] [int] NOT NULL,
	[start_time] [time](7) NOT NULL,
	[end_time] [time](7) NOT NULL,
 CONSTRAINT [PK_time_slots] PRIMARY KEY CLUSTERED 
(
	[slot_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[instructors]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[instructors](
	[id] [nvarchar](20) NOT NULL,
	[first_name] [nvarchar](50) NOT NULL,
	[last_name] [nvarchar](50) NOT NULL,
	[email] [nvarchar](100) NOT NULL,
	[password] [nvarchar](255) NOT NULL,
	[phone] [nvarchar](20) NULL,
	[department_id] [nvarchar](10) NULL,
	[title] [nvarchar](50) NULL,
	[status] [nvarchar](20) NULL,
	[created_at] [datetime2](7) NULL,
 CONSTRAINT [PK_instructors] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_instructors_email] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[courses]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[courses](
	[course_id] [nvarchar](20) NOT NULL,
	[course_name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[department_id] [nvarchar](10) NOT NULL,
	[credits] [int] NULL,
	[created_at] [datetime2](7) NULL,
 CONSTRAINT [PK_courses] PRIMARY KEY CLUSTERED 
(
	[course_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[course_offerings]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[course_offerings](
	[offering_id] [nvarchar](20) NOT NULL,
	[course_id] [nvarchar](20) NOT NULL,
	[term] [nvarchar](20) NOT NULL,
	[academic_year] [int] NOT NULL,
	[section_code] [nvarchar](20) NOT NULL,
	[capacity] [int] NOT NULL,
	[status] [nvarchar](20) NOT NULL,
	[created_at] [datetime2](7) NULL,
 CONSTRAINT [PK_course_offerings] PRIMARY KEY CLUSTERED 
(
	[offering_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_course_offering_section] UNIQUE NONCLUSTERED 
(
	[course_id] ASC,
	[term] ASC,
	[academic_year] ASC,
	[section_code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[course_instructors]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[course_instructors](
	[offering_id] [nvarchar](20) NOT NULL,
	[instructor_id] [nvarchar](20) NOT NULL,
	[role] [nvarchar](20) NULL,
 CONSTRAINT [PK_course_instructors] PRIMARY KEY CLUSTERED 
(
	[offering_id] ASC,
	[instructor_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_course_full]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  Table [dbo].[assessment_components]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[assessment_components](
	[component_id] [int] IDENTITY(1,1) NOT NULL,
	[component_code] [nvarchar](30) NOT NULL,
	[component_name] [nvarchar](100) NOT NULL,
	[week_no] [int] NULL,
	[category] [nvarchar](30) NOT NULL,
	[max_marks] [decimal](5, 2) NOT NULL,
	[display_order] [int] NOT NULL,
 CONSTRAINT [PK_assessment_components] PRIMARY KEY CLUSTERED 
(
	[component_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_assessment_components_code] UNIQUE NONCLUSTERED 
(
	[component_code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[student_assessment_scores]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[student_assessment_scores](
	[score_id] [nvarchar](50) NOT NULL,
	[enrollment_id] [nvarchar](50) NOT NULL,
	[component_id] [int] NOT NULL,
	[score] [decimal](5, 2) NULL,
	[graded_at] [datetime2](7) NULL,
 CONSTRAINT [PK_student_assessment_scores] PRIMARY KEY CLUSTERED 
(
	[score_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_student_assessment_component] UNIQUE NONCLUSTERED 
(
	[enrollment_id] ASC,
	[component_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[students]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[students](
	[id] [nvarchar](20) NOT NULL,
	[first_name] [nvarchar](50) NOT NULL,
	[last_name] [nvarchar](50) NOT NULL,
	[email] [nvarchar](100) NOT NULL,
	[personal_email] [nvarchar](100) NULL,
	[password] [nvarchar](255) NOT NULL,
	[phone] [nvarchar](20) NULL,
	[major_id] [nvarchar](10) NULL,
	[year] [int] NULL,
	[status] [nvarchar](20) NULL,
	[created_at] [datetime2](7) NULL,
 CONSTRAINT [PK_students] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_students_email] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_enrollment_gradebook]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  View [dbo].[vw_student_gpa]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  Table [dbo].[majors]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[majors](
	[major_id] [nvarchar](10) NOT NULL,
	[major_name] [nvarchar](100) NOT NULL,
	[department_id] [nvarchar](10) NOT NULL,
	[total_credits] [int] NULL,
	[created_at] [datetime2](7) NULL,
 CONSTRAINT [PK_majors] PRIMARY KEY CLUSTERED 
(
	[major_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_student_full]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  View [dbo].[vw_instructor_full]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  View [dbo].[vw_student_transcript]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  Table [dbo].[registration_periods]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[registration_periods](
	[period_id] [int] IDENTITY(1,1) NOT NULL,
	[term] [nvarchar](20) NOT NULL,
	[academic_year] [int] NOT NULL,
	[add_start_date] [date] NOT NULL,
	[add_end_date] [date] NOT NULL,
	[drop_end_date] [date] NOT NULL,
	[status] [nvarchar](20) NOT NULL,
	[created_at] [datetime2](7) NULL,
 CONSTRAINT [PK_registration_periods] PRIMARY KEY CLUSTERED 
(
	[period_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_registration_period_term_year] UNIQUE NONCLUSTERED 
(
	[term] ASC,
	[academic_year] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_available_offerings]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_available_offerings] AS
SELECT
    cf.offering_id,
    cf.course_id,
    cf.course_name,
    cf.description,
    cf.credits,
    cf.term,
    cf.academic_year,
    cf.section_code,
    cf.capacity,
    cf.enrolled,
    cf.available_seats,
    cf.status AS offering_status,
    cf.department_id,
    cf.department_name,
    cf.room_id,
    cf.schedule,
    cf.instructor_ids,
    cf.instructor_names,
    rp.add_start_date,
    rp.add_end_date,
    rp.drop_end_date,
    rp.status AS registration_status
FROM [dbo].[vw_course_full] cf
JOIN [dbo].[registration_periods] rp
    ON cf.term = rp.term
   AND cf.academic_year = rp.academic_year
WHERE cf.status = 'OPEN'
  AND cf.available_seats > 0
  AND rp.status = 'OPEN'
  AND CAST(GETDATE() AS date) BETWEEN rp.add_start_date AND rp.add_end_date;

GO
/****** Object:  View [dbo].[vw_active_registration_terms]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_active_registration_terms] AS
SELECT
    term,
    academic_year,
    add_start_date,
    add_end_date,
    drop_end_date,
    status,
    CASE
        WHEN CAST(GETDATE() AS date) BETWEEN add_start_date AND add_end_date
             AND status = 'OPEN'
        THEN 1 ELSE 0
    END AS is_add_open,
    CASE
        WHEN CAST(GETDATE() AS date) <= drop_end_date
             AND status = 'OPEN'
        THEN 1 ELSE 0
    END AS is_drop_open
FROM [dbo].[registration_periods];

GO
/****** Object:  Table [dbo].[rooms]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rooms](
	[room_id] [nvarchar](20) NOT NULL,
	[building] [nvarchar](50) NULL,
	[capacity] [int] NULL,
	[room_type] [nvarchar](20) NULL,
 CONSTRAINT [PK_rooms] PRIMARY KEY CLUSTERED 
(
	[room_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_student_schedule]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_student_schedule] AS
SELECT
    e.student_id,
    e.enrollment_id,
    e.offering_id,

    co.course_id,
    c.course_name,
    c.credits,

    co.term,
    co.academic_year,
    co.section_code,

    rs.day_of_week,
    rs.slot_id,
    rs.meeting_type,

    CONVERT(VARCHAR(5), ts.start_time, 108) AS start_time,
    CONVERT(VARCHAR(5), ts.end_time,   108) AS end_time,

    rs.room_id,
    r.room_type,

    inst.instructor_ids,
    inst.instructor_names,

    e.status AS enrollment_status
FROM dbo.enrollments e
JOIN dbo.course_offerings co
    ON e.offering_id = co.offering_id
JOIN dbo.courses c
    ON co.course_id = c.course_id
JOIN dbo.room_schedule rs
    ON co.offering_id = rs.offering_id
JOIN dbo.rooms r
    ON rs.room_id = r.room_id
JOIN dbo.time_slots ts
    ON rs.slot_id = ts.slot_id
OUTER APPLY (
    SELECT
        STRING_AGG(ci.instructor_id, ', ') AS instructor_ids,
        STRING_AGG(i.title + ' ' + i.first_name + ' ' + i.last_name, ', ') AS instructor_names
    FROM dbo.course_instructors ci
    JOIN dbo.instructors i
        ON ci.instructor_id = i.id
    WHERE ci.offering_id = co.offering_id
) inst
WHERE e.status = 'ENROLLED';

GO
/****** Object:  Table [dbo].[admins]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[admins](
	[id] [nvarchar](20) NOT NULL,
	[first_name] [nvarchar](50) NOT NULL,
	[last_name] [nvarchar](50) NOT NULL,
	[email] [nvarchar](100) NOT NULL,
	[password] [nvarchar](255) NOT NULL,
	[admin_level] [nvarchar](20) NULL,
	[created_at] [datetime2](7) NULL,
 CONSTRAINT [PK_admins] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_admins_email] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[course_prerequisites]    Script Date: 5/31/2026 6:59:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[course_prerequisites](
	[course_id] [nvarchar](20) NOT NULL,
	[prerequisite_id] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_course_prerequisites] PRIMARY KEY CLUSTERED 
(
	[course_id] ASC,
	[prerequisite_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_course_offerings_course_id]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_course_offerings_course_id] ON [dbo].[course_offerings]
(
	[course_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_course_offerings_term_year]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_course_offerings_term_year] ON [dbo].[course_offerings]
(
	[term] ASC,
	[academic_year] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_courses_department_id]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_courses_department_id] ON [dbo].[courses]
(
	[department_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_enrollments_offering_id]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_enrollments_offering_id] ON [dbo].[enrollments]
(
	[offering_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_enrollments_student_id]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_enrollments_student_id] ON [dbo].[enrollments]
(
	[student_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_instructors_department_id]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_instructors_department_id] ON [dbo].[instructors]
(
	[department_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_room_schedule_instructor_id]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_room_schedule_instructor_id] ON [dbo].[room_schedule]
(
	[instructor_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_room_schedule_offering_id]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_room_schedule_offering_id] ON [dbo].[room_schedule]
(
	[offering_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_room_schedule_instructor_time]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_room_schedule_instructor_time] ON [dbo].[room_schedule]
(
	[instructor_id] ASC,
	[day_of_week] ASC,
	[slot_id] ASC
)
WHERE ([instructor_id] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_room_schedule_room_time]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_room_schedule_room_time] ON [dbo].[room_schedule]
(
	[room_id] ASC,
	[day_of_week] ASC,
	[slot_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_student_assessment_scores_enrollment_id]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_student_assessment_scores_enrollment_id] ON [dbo].[student_assessment_scores]
(
	[enrollment_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_students_major_id]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE NONCLUSTERED INDEX [IX_students_major_id] ON [dbo].[students]
(
	[major_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_students_personal_email]    Script Date: 5/31/2026 6:59:51 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_students_personal_email] ON [dbo].[students]
(
	[personal_email] ASC
)
WHERE ([personal_email] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[admins] ADD  CONSTRAINT [DF_admins_admin_level]  DEFAULT ('STANDARD') FOR [admin_level]
GO
ALTER TABLE [dbo].[admins] ADD  CONSTRAINT [DF_admins_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[course_instructors] ADD  CONSTRAINT [DF_course_instructors_role]  DEFAULT ('LECTURE') FOR [role]
GO
ALTER TABLE [dbo].[course_offerings] ADD  CONSTRAINT [DF_course_offerings_section]  DEFAULT ('L01') FOR [section_code]
GO
ALTER TABLE [dbo].[course_offerings] ADD  CONSTRAINT [DF_course_offerings_capacity]  DEFAULT ((30)) FOR [capacity]
GO
ALTER TABLE [dbo].[course_offerings] ADD  CONSTRAINT [DF_course_offerings_status]  DEFAULT ('OPEN') FOR [status]
GO
ALTER TABLE [dbo].[course_offerings] ADD  CONSTRAINT [DF_course_offerings_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[courses] ADD  CONSTRAINT [DF_courses_credits]  DEFAULT ((3)) FOR [credits]
GO
ALTER TABLE [dbo].[courses] ADD  CONSTRAINT [DF_courses_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[departments] ADD  CONSTRAINT [DF_departments_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[enrollments] ADD  CONSTRAINT [DF_enrollments_id]  DEFAULT (CONVERT([nvarchar](50),newid())) FOR [enrollment_id]
GO
ALTER TABLE [dbo].[enrollments] ADD  CONSTRAINT [DF_enrollments_date]  DEFAULT (getdate()) FOR [enrollment_date]
GO
ALTER TABLE [dbo].[enrollments] ADD  CONSTRAINT [DF_enrollments_status]  DEFAULT ('ENROLLED') FOR [status]
GO
ALTER TABLE [dbo].[instructors] ADD  CONSTRAINT [DF_instructors_status]  DEFAULT ('ACTIVE') FOR [status]
GO
ALTER TABLE [dbo].[instructors] ADD  CONSTRAINT [DF_instructors_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[majors] ADD  CONSTRAINT [DF_majors_total_credits]  DEFAULT ((120)) FOR [total_credits]
GO
ALTER TABLE [dbo].[majors] ADD  CONSTRAINT [DF_majors_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[registration_periods] ADD  CONSTRAINT [DF_registration_periods_status]  DEFAULT ('OPEN') FOR [status]
GO
ALTER TABLE [dbo].[registration_periods] ADD  CONSTRAINT [DF_registration_periods_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[room_schedule] ADD  CONSTRAINT [DF_room_schedule_meeting_type]  DEFAULT ('LECTURE') FOR [meeting_type]
GO
ALTER TABLE [dbo].[rooms] ADD  CONSTRAINT [DF_rooms_room_type]  DEFAULT ('LECTURE') FOR [room_type]
GO
ALTER TABLE [dbo].[student_assessment_scores] ADD  CONSTRAINT [DF_student_assessment_scores_id]  DEFAULT (CONVERT([nvarchar](50),newid())) FOR [score_id]
GO
ALTER TABLE [dbo].[student_assessment_scores] ADD  CONSTRAINT [DF_student_assessment_scores_graded_at]  DEFAULT (getdate()) FOR [graded_at]
GO
ALTER TABLE [dbo].[students] ADD  CONSTRAINT [DF_students_year]  DEFAULT ((1)) FOR [year]
GO
ALTER TABLE [dbo].[students] ADD  CONSTRAINT [DF_students_status]  DEFAULT ('ACTIVE') FOR [status]
GO
ALTER TABLE [dbo].[students] ADD  CONSTRAINT [DF_students_created_at]  DEFAULT (getdate()) FOR [created_at]
GO
ALTER TABLE [dbo].[course_instructors]  WITH CHECK ADD  CONSTRAINT [FK_ci_instructor] FOREIGN KEY([instructor_id])
REFERENCES [dbo].[instructors] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[course_instructors] CHECK CONSTRAINT [FK_ci_instructor]
GO
ALTER TABLE [dbo].[course_instructors]  WITH CHECK ADD  CONSTRAINT [FK_ci_offering] FOREIGN KEY([offering_id])
REFERENCES [dbo].[course_offerings] ([offering_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[course_instructors] CHECK CONSTRAINT [FK_ci_offering]
GO
ALTER TABLE [dbo].[course_offerings]  WITH CHECK ADD  CONSTRAINT [FK_course_offerings_courses] FOREIGN KEY([course_id])
REFERENCES [dbo].[courses] ([course_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[course_offerings] CHECK CONSTRAINT [FK_course_offerings_courses]
GO
ALTER TABLE [dbo].[course_offerings]  WITH CHECK ADD  CONSTRAINT [FK_course_offerings_registration_period] FOREIGN KEY([term], [academic_year])
REFERENCES [dbo].[registration_periods] ([term], [academic_year])
GO
ALTER TABLE [dbo].[course_offerings] CHECK CONSTRAINT [FK_course_offerings_registration_period]
GO
ALTER TABLE [dbo].[course_prerequisites]  WITH CHECK ADD  CONSTRAINT [FK_cp_course] FOREIGN KEY([course_id])
REFERENCES [dbo].[courses] ([course_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[course_prerequisites] CHECK CONSTRAINT [FK_cp_course]
GO
ALTER TABLE [dbo].[course_prerequisites]  WITH CHECK ADD  CONSTRAINT [FK_cp_prereq] FOREIGN KEY([prerequisite_id])
REFERENCES [dbo].[courses] ([course_id])
GO
ALTER TABLE [dbo].[course_prerequisites] CHECK CONSTRAINT [FK_cp_prereq]
GO
ALTER TABLE [dbo].[courses]  WITH CHECK ADD  CONSTRAINT [FK_courses_departments] FOREIGN KEY([department_id])
REFERENCES [dbo].[departments] ([department_id])
GO
ALTER TABLE [dbo].[courses] CHECK CONSTRAINT [FK_courses_departments]
GO
ALTER TABLE [dbo].[enrollments]  WITH CHECK ADD  CONSTRAINT [FK_enr_offering] FOREIGN KEY([offering_id])
REFERENCES [dbo].[course_offerings] ([offering_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[enrollments] CHECK CONSTRAINT [FK_enr_offering]
GO
ALTER TABLE [dbo].[enrollments]  WITH CHECK ADD  CONSTRAINT [FK_enr_student] FOREIGN KEY([student_id])
REFERENCES [dbo].[students] ([id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[enrollments] CHECK CONSTRAINT [FK_enr_student]
GO
ALTER TABLE [dbo].[instructors]  WITH CHECK ADD  CONSTRAINT [FK_instructors_departments] FOREIGN KEY([department_id])
REFERENCES [dbo].[departments] ([department_id])
GO
ALTER TABLE [dbo].[instructors] CHECK CONSTRAINT [FK_instructors_departments]
GO
ALTER TABLE [dbo].[majors]  WITH CHECK ADD  CONSTRAINT [FK_majors_departments] FOREIGN KEY([department_id])
REFERENCES [dbo].[departments] ([department_id])
GO
ALTER TABLE [dbo].[majors] CHECK CONSTRAINT [FK_majors_departments]
GO
ALTER TABLE [dbo].[room_schedule]  WITH CHECK ADD  CONSTRAINT [FK_rs_instructor] FOREIGN KEY([instructor_id])
REFERENCES [dbo].[instructors] ([id])
GO
ALTER TABLE [dbo].[room_schedule] CHECK CONSTRAINT [FK_rs_instructor]
GO
ALTER TABLE [dbo].[room_schedule]  WITH CHECK ADD  CONSTRAINT [FK_rs_offering] FOREIGN KEY([offering_id])
REFERENCES [dbo].[course_offerings] ([offering_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[room_schedule] CHECK CONSTRAINT [FK_rs_offering]
GO
ALTER TABLE [dbo].[room_schedule]  WITH CHECK ADD  CONSTRAINT [FK_rs_room] FOREIGN KEY([room_id])
REFERENCES [dbo].[rooms] ([room_id])
GO
ALTER TABLE [dbo].[room_schedule] CHECK CONSTRAINT [FK_rs_room]
GO
ALTER TABLE [dbo].[room_schedule]  WITH CHECK ADD  CONSTRAINT [FK_rs_slot] FOREIGN KEY([slot_id])
REFERENCES [dbo].[time_slots] ([slot_id])
GO
ALTER TABLE [dbo].[room_schedule] CHECK CONSTRAINT [FK_rs_slot]
GO
ALTER TABLE [dbo].[student_assessment_scores]  WITH CHECK ADD  CONSTRAINT [FK_sas_component] FOREIGN KEY([component_id])
REFERENCES [dbo].[assessment_components] ([component_id])
GO
ALTER TABLE [dbo].[student_assessment_scores] CHECK CONSTRAINT [FK_sas_component]
GO
ALTER TABLE [dbo].[student_assessment_scores]  WITH CHECK ADD  CONSTRAINT [FK_sas_enrollment] FOREIGN KEY([enrollment_id])
REFERENCES [dbo].[enrollments] ([enrollment_id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[student_assessment_scores] CHECK CONSTRAINT [FK_sas_enrollment]
GO
ALTER TABLE [dbo].[students]  WITH CHECK ADD  CONSTRAINT [FK_students_majors] FOREIGN KEY([major_id])
REFERENCES [dbo].[majors] ([major_id])
GO
ALTER TABLE [dbo].[students] CHECK CONSTRAINT [FK_students_majors]
GO
ALTER TABLE [dbo].[admins]  WITH CHECK ADD  CONSTRAINT [CK_admins_level] CHECK  (([admin_level]='SUPER' OR [admin_level]='MODERATOR' OR [admin_level]='STANDARD'))
GO
ALTER TABLE [dbo].[admins] CHECK CONSTRAINT [CK_admins_level]
GO
ALTER TABLE [dbo].[assessment_components]  WITH CHECK ADD  CONSTRAINT [CK_assessment_components_category] CHECK  (([category]='FINAL' OR [category]='COURSEWORK' OR [category]='MIDTERM_2' OR [category]='MIDTERM_1'))
GO
ALTER TABLE [dbo].[assessment_components] CHECK CONSTRAINT [CK_assessment_components_category]
GO
ALTER TABLE [dbo].[assessment_components]  WITH CHECK ADD  CONSTRAINT [CK_assessment_components_max_marks] CHECK  (([max_marks]>(0)))
GO
ALTER TABLE [dbo].[assessment_components] CHECK CONSTRAINT [CK_assessment_components_max_marks]
GO
ALTER TABLE [dbo].[assessment_components]  WITH CHECK ADD  CONSTRAINT [CK_assessment_components_week] CHECK  (([week_no] IS NULL OR [week_no]>=(1) AND [week_no]<=(16)))
GO
ALTER TABLE [dbo].[assessment_components] CHECK CONSTRAINT [CK_assessment_components_week]
GO
ALTER TABLE [dbo].[course_instructors]  WITH CHECK ADD  CONSTRAINT [CK_ci_role] CHECK  (([role]='ASSISTANT' OR [role]='SEMINAR' OR [role]='LAB' OR [role]='LECTURE'))
GO
ALTER TABLE [dbo].[course_instructors] CHECK CONSTRAINT [CK_ci_role]
GO
ALTER TABLE [dbo].[course_offerings]  WITH CHECK ADD  CONSTRAINT [CK_course_offerings_capacity] CHECK  (([capacity]>=(1) AND [capacity]<=(500)))
GO
ALTER TABLE [dbo].[course_offerings] CHECK CONSTRAINT [CK_course_offerings_capacity]
GO
ALTER TABLE [dbo].[course_offerings]  WITH CHECK ADD  CONSTRAINT [CK_course_offerings_status] CHECK  (([status]='COMPLETED' OR [status]='CANCELLED' OR [status]='CLOSED' OR [status]='OPEN'))
GO
ALTER TABLE [dbo].[course_offerings] CHECK CONSTRAINT [CK_course_offerings_status]
GO
ALTER TABLE [dbo].[course_offerings]  WITH CHECK ADD  CONSTRAINT [CK_course_offerings_term] CHECK  (([term]='SUMMER' OR [term]='TERM2' OR [term]='TERM1'))
GO
ALTER TABLE [dbo].[course_offerings] CHECK CONSTRAINT [CK_course_offerings_term]
GO
ALTER TABLE [dbo].[course_offerings]  WITH CHECK ADD  CONSTRAINT [CK_course_offerings_year] CHECK  (([academic_year]>=(2000) AND [academic_year]<=(2100)))
GO
ALTER TABLE [dbo].[course_offerings] CHECK CONSTRAINT [CK_course_offerings_year]
GO
ALTER TABLE [dbo].[course_prerequisites]  WITH CHECK ADD  CONSTRAINT [CK_cp_no_self_reference] CHECK  (([course_id]<>[prerequisite_id]))
GO
ALTER TABLE [dbo].[course_prerequisites] CHECK CONSTRAINT [CK_cp_no_self_reference]
GO
ALTER TABLE [dbo].[courses]  WITH CHECK ADD  CONSTRAINT [CK_courses_credits] CHECK  (([credits]>=(1) AND [credits]<=(6)))
GO
ALTER TABLE [dbo].[courses] CHECK CONSTRAINT [CK_courses_credits]
GO
ALTER TABLE [dbo].[enrollments]  WITH CHECK ADD  CONSTRAINT [CK_enrollments_status] CHECK  (([status]='INCOMPLETE' OR [status]='WITHDRAWN' OR [status]='COMPLETED' OR [status]='ENROLLED'))
GO
ALTER TABLE [dbo].[enrollments] CHECK CONSTRAINT [CK_enrollments_status]
GO
ALTER TABLE [dbo].[instructors]  WITH CHECK ADD  CONSTRAINT [CK_instructors_status] CHECK  (([status]='ON_LEAVE' OR [status]='INACTIVE' OR [status]='ACTIVE'))
GO
ALTER TABLE [dbo].[instructors] CHECK CONSTRAINT [CK_instructors_status]
GO
ALTER TABLE [dbo].[instructors]  WITH CHECK ADD  CONSTRAINT [CK_instructors_title] CHECK  (([title]='Professor' OR [title]='Associate Professor' OR [title]='Assistant Professor' OR [title]='Lecturer' OR [title]='Teaching Assistant'))
GO
ALTER TABLE [dbo].[instructors] CHECK CONSTRAINT [CK_instructors_title]
GO
ALTER TABLE [dbo].[registration_periods]  WITH CHECK ADD  CONSTRAINT [CK_registration_period_dates] CHECK  (([add_start_date]<=[add_end_date] AND [add_end_date]<=[drop_end_date]))
GO
ALTER TABLE [dbo].[registration_periods] CHECK CONSTRAINT [CK_registration_period_dates]
GO
ALTER TABLE [dbo].[registration_periods]  WITH CHECK ADD  CONSTRAINT [CK_registration_period_status] CHECK  (([status]='CLOSED' OR [status]='OPEN'))
GO
ALTER TABLE [dbo].[registration_periods] CHECK CONSTRAINT [CK_registration_period_status]
GO
ALTER TABLE [dbo].[registration_periods]  WITH CHECK ADD  CONSTRAINT [CK_registration_period_term] CHECK  (([term]='SUMMER' OR [term]='TERM2' OR [term]='TERM1'))
GO
ALTER TABLE [dbo].[registration_periods] CHECK CONSTRAINT [CK_registration_period_term]
GO
ALTER TABLE [dbo].[registration_periods]  WITH CHECK ADD  CONSTRAINT [CK_registration_period_year] CHECK  (([academic_year]>=(2000) AND [academic_year]<=(2100)))
GO
ALTER TABLE [dbo].[registration_periods] CHECK CONSTRAINT [CK_registration_period_year]
GO
ALTER TABLE [dbo].[room_schedule]  WITH CHECK ADD  CONSTRAINT [CK_room_schedule_meeting_type] CHECK  (([meeting_type]='LAB' OR [meeting_type]='SECTION' OR [meeting_type]='LECTURE'))
GO
ALTER TABLE [dbo].[room_schedule] CHECK CONSTRAINT [CK_room_schedule_meeting_type]
GO
ALTER TABLE [dbo].[room_schedule]  WITH CHECK ADD  CONSTRAINT [CK_rs_day] CHECK  (([day_of_week]='Sunday' OR [day_of_week]='Saturday' OR [day_of_week]='Friday' OR [day_of_week]='Thursday' OR [day_of_week]='Wednesday' OR [day_of_week]='Tuesday' OR [day_of_week]='Monday'))
GO
ALTER TABLE [dbo].[room_schedule] CHECK CONSTRAINT [CK_rs_day]
GO
ALTER TABLE [dbo].[rooms]  WITH CHECK ADD  CONSTRAINT [CK_rooms_capacity] CHECK  (([capacity] IS NULL OR [capacity]>(0)))
GO
ALTER TABLE [dbo].[rooms] CHECK CONSTRAINT [CK_rooms_capacity]
GO
ALTER TABLE [dbo].[rooms]  WITH CHECK ADD  CONSTRAINT [CK_rooms_room_type] CHECK  (([room_type]='LAB' OR [room_type]='LECTURE'))
GO
ALTER TABLE [dbo].[rooms] CHECK CONSTRAINT [CK_rooms_room_type]
GO
ALTER TABLE [dbo].[student_assessment_scores]  WITH CHECK ADD  CONSTRAINT [CK_student_assessment_scores_score] CHECK  (([score] IS NULL OR [score]>=(0)))
GO
ALTER TABLE [dbo].[student_assessment_scores] CHECK CONSTRAINT [CK_student_assessment_scores_score]
GO
ALTER TABLE [dbo].[students]  WITH CHECK ADD  CONSTRAINT [CK_students_status] CHECK  (([status]='SUSPENDED' OR [status]='GRADUATED' OR [status]='INACTIVE' OR [status]='ACTIVE'))
GO
ALTER TABLE [dbo].[students] CHECK CONSTRAINT [CK_students_status]
GO
ALTER TABLE [dbo].[students]  WITH CHECK ADD  CONSTRAINT [CK_students_year] CHECK  (([year]>=(1) AND [year]<=(7)))
GO
ALTER TABLE [dbo].[students] CHECK CONSTRAINT [CK_students_year]
GO
ALTER TABLE [dbo].[time_slots]  WITH CHECK ADD  CONSTRAINT [CK_time_slots_time_order] CHECK  (([start_time]<[end_time]))
GO
ALTER TABLE [dbo].[time_slots] CHECK CONSTRAINT [CK_time_slots_time_order]
GO
USE [master]
GO
ALTER DATABASE [UniversityDB] SET  READ_WRITE 
GO
