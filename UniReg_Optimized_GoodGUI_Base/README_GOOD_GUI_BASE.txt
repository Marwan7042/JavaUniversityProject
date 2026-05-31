UniReg Optimized Good GUI Base

This package keeps the uploaded optimized/small GUI style:
- BaseDashboardScreen
- ChromeTab / ChromeTabPane
- compact StudentDashboardScreen
- compact InstructorScreen
- compact AdminDashboardScreen
- uploaded UIHelper / GlassTable / CSS resources

It keeps the optimized backend/facade structure from the final package:
- DAO split
- ScheduleDAO
- ScheduleEntry model
- no Lombok-generated log problem
- TERM1 / TERM2 / SUMMER compatible backend

Important:
This version is the GOOD GUI base. It intentionally restores the smaller GUI style from the files you sent.
Some extra old features can be re-added next as small tabs/components without replacing the GUI style.

Run:
mvn clean compile
mvn javafx:run
