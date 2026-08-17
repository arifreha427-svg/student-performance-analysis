-- =====================================================================
-- STUDENT PERFORMANCE ANALYSIS
-- Author: Reha Arif
-- =====================================================================
-- Dataset assumption: one row per (student, subject) combination.
-- A student appears in multiple rows -- one per subject they are graded in.
-- =====================================================================


-- =====================================================================
-- SECTION 1: TABLE CREATION
-- =====================================================================

-- Drop the table first if it already exists
DROP TABLE IF EXISTS student_performance;

-- Create the main table with appropriate data types and constraints
CREATE TABLE student_performance (
    record_id               SERIAL PRIMARY KEY,               -- surrogate key per row (student+subject)
    student_id               INT             NOT NULL,          -- unique student identifier
    name                      VARCHAR(100)    NOT NULL,          -- student full name
    gender                    VARCHAR(10)     CHECK (gender IN ('Male', 'Female', 'Other')),
    class                     VARCHAR(10)     NOT NULL,          -- grade + section, e.g. '10-A'
    subject                   VARCHAR(50)     NOT NULL,          -- subject name
    marks                     DECIMAL(5,2)    CHECK (marks BETWEEN 0 AND 100),   -- marks scored (0-100)
    attendance_percentage    DECIMAL(5,2)    CHECK (attendance_percentage BETWEEN 0 AND 100),
    study_hours               DECIMAL(4,2)    CHECK (study_hours >= 0),          -- avg daily self-study hours

    -- A student should not have more than one mark entry per subject
    CONSTRAINT uq_student_subject UNIQUE (student_id, subject)
);

-- Helpful indexes for the analytical queries below
CREATE INDEX idx_sp_student_id ON student_performance (student_id);
CREATE INDEX idx_sp_subject    ON student_performance (subject);
CREATE INDEX idx_sp_class      ON student_performance (class);


-- =====================================================================
-- SECTION 2: DATA CLEANING QUERIES
-- =====================================================================

-- 2.1 Find rows with NULL values in key columns
SELECT *
FROM student_performance
WHERE marks IS NULL
   OR attendance_percentage IS NULL
   OR study_hours IS NULL
   OR name IS NULL;

-- 2.2 Fill NULL marks with the subject-wise average marks
UPDATE student_performance sp
SET marks = (
    SELECT ROUND(AVG(sp2.marks), 2)
    FROM student_performance sp2
    WHERE sp2.subject = sp.subject
      AND sp2.marks IS NOT NULL
)
WHERE sp.marks IS NULL;

-- 2.3 Fill NULL attendance_percentage and study_hours with the overall average
UPDATE student_performance
SET attendance_percentage = (
    SELECT ROUND(AVG(attendance_percentage), 2)
    FROM student_performance
    WHERE attendance_percentage IS NOT NULL
)
WHERE attendance_percentage IS NULL;

UPDATE student_performance
SET study_hours = (
    SELECT ROUND(AVG(study_hours), 2)
    FROM student_performance
    WHERE study_hours IS NOT NULL
)
WHERE study_hours IS NULL;

-- 2.4 Identify duplicate rows (same student + subject appearing more than once)
SELECT student_id, subject, COUNT(*) AS duplicate_count
FROM student_performance
GROUP BY student_id, subject
HAVING COUNT(*) > 1;

-- 2.5 Remove duplicate rows, keeping only the lowest record_id per (student_id, subject)
DELETE FROM student_performance
WHERE record_id NOT IN (
    SELECT MIN(record_id)
    FROM student_performance
    GROUP BY student_id, subject
);

-- 2.6 Identify invalid/out-of-range values (data entry errors)
SELECT *
FROM student_performance
WHERE marks < 0 OR marks > 100
   OR attendance_percentage < 0 OR attendance_percentage > 100
   OR study_hours < 0;

-- 2.7 Correct invalid marks/attendance by capping to the valid range (0-100)
UPDATE student_performance
SET marks = CASE
                WHEN marks > 100 THEN 100
                WHEN marks < 0 THEN 0
                ELSE marks
            END
WHERE marks > 100 OR marks < 0;

UPDATE student_performance
SET attendance_percentage = CASE
                                WHEN attendance_percentage > 100 THEN 100
                                WHEN attendance_percentage < 0 THEN 0
                                ELSE attendance_percentage
                             END
WHERE attendance_percentage > 100 OR attendance_percentage < 0;

-- 2.8 Standardize text fields (trim whitespace, consistent casing)
UPDATE student_performance
SET gender = INITCAP(TRIM(gender));  


-- =====================================================================
-- SECTION 3: SUBJECT-WISE AVERAGE, MINIMUM, AND MAXIMUM MARKS
-- =====================================================================

-- Average, minimum, and maximum marks per subject, sorted by average descending
SELECT
    subject,
    ROUND(AVG(marks), 2)  AS avg_marks,
    MIN(marks)            AS min_marks,
    MAX(marks)            AS max_marks,
    COUNT(*)               AS student_count
FROM student_performance
GROUP BY subject
ORDER BY avg_marks DESC;


-- =====================================================================
-- SECTION 4: OVERALL STUDENT PERFORMANCE RANKING
-- =====================================================================

-- Rank students by their overall average marks across all subjects.
-- RANK() leaves gaps after ties; DENSE_RANK() does not -- both shown for reference.
SELECT
    student_id,
    name,
    class,
    ROUND(AVG(marks), 2)                                   AS avg_marks,
    RANK()       OVER (ORDER BY AVG(marks) DESC)           AS rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY AVG(marks) DESC)           AS dense_rank
FROM student_performance
GROUP BY student_id, name, class
ORDER BY avg_marks DESC;


-- =====================================================================
-- SECTION 5: ATTENDANCE VS PERFORMANCE CORRELATION (GROUPED ANALYSIS)
-- =====================================================================

-- Bucket students into attendance bands and compare average marks per band.
-- (A true correlation coefficient isn't standard-SQL portable; this grouped
--  approach gives an equivalent, more interpretable view of the relationship.)
SELECT
    CASE
        WHEN attendance_percentage < 60           THEN 'Below 60%'
        WHEN attendance_percentage BETWEEN 60 AND 74.99 THEN '60% - 75%'
        WHEN attendance_percentage BETWEEN 75 AND 89.99 THEN '75% - 90%'
        ELSE '90% - 100%'
    END AS attendance_band,
    ROUND(AVG(marks), 2)   AS avg_marks,
    COUNT(DISTINCT student_id) AS num_students
FROM student_performance
GROUP BY attendance_band
ORDER BY avg_marks DESC;


-- =====================================================================
-- SECTION 6: CLASS/GROUP-WISE PERFORMANCE COMPARISON
-- =====================================================================

-- Average marks per class, ranked from highest to lowest performing class
SELECT
    class,
    ROUND(AVG(marks), 2)       AS avg_marks,
    COUNT(DISTINCT student_id) AS num_students
FROM student_performance
GROUP BY class
ORDER BY avg_marks DESC;


-- =====================================================================
-- SECTION 7: TOP 5 AND BOTTOM 5 PERFORMING STUDENTS
-- =====================================================================

-- 7.1 Top 5 performing students (by overall average marks)
SELECT
    student_id,
    name,
    class,
    ROUND(AVG(marks), 2) AS avg_marks
FROM student_performance
GROUP BY student_id, name, class
ORDER BY avg_marks DESC
LIMIT 5;

-- 7.2 Bottom 5 performing students (by overall average marks)
SELECT
    student_id,
    name,
    class,
    ROUND(AVG(marks), 2) AS avg_marks
FROM student_performance
GROUP BY student_id, name, class
ORDER BY avg_marks ASC
LIMIT 5;


-- =====================================================================
-- SECTION 8: PASS/FAIL COUNT PER SUBJECT AND PER CLASS
-- =====================================================================
-- Assumption: passing mark threshold is 40.

-- 8.1 Pass/Fail count per subject
SELECT
    subject,
    SUM(CASE WHEN marks >= 40 THEN 1 ELSE 0 END) AS pass_count,
    SUM(CASE WHEN marks < 40  THEN 1 ELSE 0 END) AS fail_count,
    COUNT(*)                                     AS total_students
FROM student_performance
GROUP BY subject
ORDER BY subject;

-- 8.2 Pass/Fail count per class
SELECT
    class,
    SUM(CASE WHEN marks >= 40 THEN 1 ELSE 0 END) AS pass_count,
    SUM(CASE WHEN marks < 40  THEN 1 ELSE 0 END) AS fail_count,
    COUNT(*)                                     AS total_students
FROM student_performance
GROUP BY class
ORDER BY class;


-- =====================================================================
-- SECTION 9: AT-RISK STUDENTS (LOW ATTENDANCE + LOW MARKS)
-- =====================================================================

-- Students with BOTH low attendance (< 65%) AND low marks (< 40) in any subject
-- -- a strong early-warning combination for academic risk.
SELECT DISTINCT
    student_id,
    name,
    class,
    subject,
    marks,
    attendance_percentage,
    study_hours
FROM student_performance
WHERE attendance_percentage < 65
  AND marks < 40
ORDER BY attendance_percentage ASC, marks ASC;

-- Alternative: student-level view -- students whose OVERALL average attendance
-- and OVERALL average marks are both below threshold (broader risk profile)
SELECT
    student_id,
    name,
    class,
    ROUND(AVG(marks), 2)                  AS avg_marks,
    ROUND(AVG(attendance_percentage), 2)  AS avg_attendance,
    ROUND(AVG(study_hours), 2)            AS avg_study_hours
FROM student_performance
GROUP BY student_id, name, class
HAVING AVG(marks) < 40
   AND AVG(attendance_percentage) < 65
ORDER BY avg_marks ASC;


-- =====================================================================
-- SECTION 10: SUMMARY / KPI QUERY
-- =====================================================================

-- Single summary row combining total students, average score, and pass %.
SELECT
    COUNT(DISTINCT student_id)                                        AS total_students,
    ROUND(AVG(marks), 2)                                              AS avg_score,
    ROUND(AVG(attendance_percentage), 2)                              AS avg_attendance,
    ROUND(AVG(study_hours), 2)                                        AS avg_study_hours,
    ROUND(
        100.0 * SUM(CASE WHEN marks >= 40 THEN 1 ELSE 0 END) / COUNT(*),
        2
    )                                                                  AS pass_percentage
FROM student_performance;

-- =====================================================================
-- END OF FILE
-- =====================================================================
