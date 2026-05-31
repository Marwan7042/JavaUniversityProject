UniReg Optimized Final Project

1) Open this folder in IntelliJ as a Maven project.
2) Make sure SQL Server is running and the UniversityDB database exists.
3) Run the seed file if needed:
   database/01_Reset_And_Seed_OptionB_Dummy_Data_FIXED.sql
4) Database connection defaults:
   server: localhost
   database: UniversityDB
   user: university_user
   password: UniPass123

You can override them with environment variables:
   UNIVERSITY_DB_SERVER
   UNIVERSITY_DB_NAME
   UNIVERSITY_DB_USER
   UNIVERSITY_DB_PASSWORD

Run:
   mvn clean compile
   mvn javafx:run

Sample logins after seed:
   Student:    student001@university.edu / stu123
   Instructor: instructor001@university.edu / ins123
   Admin:      super.admin@university.edu / admin123
