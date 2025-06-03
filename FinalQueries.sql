use Examination_System

CREATE TABLE student_exam (
    Std_ID INT,
	StudentName varchar(30),
    ex_ID INT,
    st_Grade INT,
    exam_percentage FLOAT,
    St_status VARCHAR(10),
	AssignedDate DATETIME DEFAULT GETDATE(),
	Duration INT,
    PRIMARY KEY (Std_ID, ex_ID),
    FOREIGN KEY (Std_ID) REFERENCES Student(StudentID),
    FOREIGN KEY (ex_ID) REFERENCES Exam(ExamID)
);
ALTER TABLE student_exam 
ADD AssignedDate DATETIME CONSTRAINT c14 DEFAULT GETDATE();
ALTER TABLE student_exam 
ADD StudentName varchar(30) ;
drop table student_exam 

-- Student
CREATE PROCEDURE AddStudent
    @StudentID INT,
    @StudentName NVARCHAR(100),
    @StudentAge INT,
    @StudentAddress VARCHAR(50),
    @StudentPhone CHAR(11)
AS
BEGIN
    INSERT INTO Student (StudentID, StudentName, StudentAge, StudentAddress, StudentPhone)
    VALUES (@StudentID, @StudentName, @StudentAge, @StudentAddress, @StudentPhone);
END
EXEC AddStudent @StudentID=2 ,@StudentName='ahmed',@StudentAge=22,@StudentAddress='Alex', @StudentPhone='01134567895'
select * from Student

--Instractor
CREATE PROCEDURE AddInstructor
    @InstructorID INT,
    @InstructorName VARCHAR(50),
    @Age INT,
    @Address VARCHAR(50)
AS
BEGIN
    INSERT INTO Instructor (InstructorID, InstructorName, Age, Address)
    VALUES (@InstructorID, @InstructorName, @Age, @Address);
END


EXEC AddInstructor @InstructorID=1, @InstructorName='mohsen', @Age=40, @Address='Alex'
select * from Instructor

-- Create Exam
CREATE PROCEDURE CreateExam
    @ExamID INT,
    @Duration INT,
    @StartTime TIME,
    @ExamDate DATE,
    @MinDegree INT,
    @MaxDegree INT,
    @CourseID INT,
    @InstructorID INT
AS
BEGIN
    INSERT INTO Exam (ExamID, Duration, StartTime, ExamDate, MinDegree, MaxDegree, CourseID, InstructorID)
    VALUES (@ExamID, @Duration, @StartTime, @ExamDate, @MinDegree, @MaxDegree, @CourseID, @InstructorID);
END

EXEC CreateExam
    @ExamID = 1,
    @Duration = 90,
    @StartTime = '11:00:00',
    @ExamDate = '2025-05-20',
    @MinDegree = 5,
    @MaxDegree = 10,
    @CourseID = 1,
    @InstructorID = 1;
	select * from Exam

--Exam with Que
CREATE PROCEDURE Add_Question_To_Exam
    @QuestionID INT,
    @Type VARCHAR(50),
    @QuestionText VARCHAR(500),
    @CorrectAnswer CHAR(1),
    @CourseID INT,
    @ExamID INT
AS
BEGIN
    INSERT INTO Question (QuestionID, Type, Questiontext, CorrectAnswer, CourseID, ExamID)
    VALUES (@QuestionID, @Type, @QuestionText, @CorrectAnswer, @CourseID, @ExamID)
END
EXEC Add_Question_To_Exam
    @QuestionID = 2,
    @Type = 'True/False',
    @QuestionText = 'SQL is a programming language.',
    @CorrectAnswer = 'F',
    @CourseID = 1,
    @ExamID = 1;
select * from Question

--Ques MCQ
CREATE PROCEDURE Add_Choices_To_Question
    @ChoiceID INT,
    @ChoiceText VARCHAR(50),
    @QuestionID INT
AS
BEGIN
    INSERT INTO Choice (ChoiceID, choiceText, QuestionID)
    VALUES (@ChoiceID, @ChoiceText, @QuestionID)
END
EXEC Add_Question_To_Exam
    @QuestionID = 3,
    @Type = 'MCQ',
    @QuestionText = 'What is the capital of France?',
    @CorrectAnswer = 'B',
    @CourseID = 1,
    @ExamID = 1;

EXEC Add_Choices_To_Question @ChoiceID = 5, @ChoiceText = 'Berlin', @QuestionID = 3;
EXEC Add_Choices_To_Question @ChoiceID = 2, @ChoiceText = 'Paris', @QuestionID = 3;
EXEC Add_Choices_To_Question @ChoiceID = 3, @ChoiceText = 'Rome', @QuestionID = 3;
EXEC Add_Choices_To_Question @ChoiceID = 4, @ChoiceText = 'Madrid', @QuestionID = 3;

-- Course
CREATE PROCEDURE AddCourse
    @CourseID INT,
    @Name NVARCHAR(30),
    @Description NVARCHAR(50)
AS
BEGIN
    INSERT INTO Course (CourseID, Name, Description)
    VALUES (@CourseID, @Name, @Description);
END;

EXEC AddCourse 
    @CourseID = 1, 
    @Name = N'Networks', 
    @Description = N'Introduction to network concepts';

-- Exam Correction
ALTER PROCEDURE Exam_Correction
    @StudentID INT,
    @ExamID INT
AS
BEGIN
    DECLARE @TotalQuestions INT;
    DECLARE @CorrectAnswers INT;
    DECLARE @Grade INT;
    DECLARE @Percentage FLOAT;
    DECLARE @MinDegree INT;
	DECLARE @Duration INT;
    DECLARE @assigndate DATETIME;
	DECLARE @Studentname VARCHAR(30);

    SELECT @TotalQuestions = COUNT(*)
    FROM Question
    WHERE ExamID = @ExamID  
    IF @TotalQuestions = 0
    BEGIN
        RAISERROR('No questions found for this exam.', 16, 1);
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM student_exam WHERE Std_ID = @StudentID AND ex_ID = @ExamID
    )
    BEGIN
        RAISERROR('Result for this student and exam already exists.', 16, 1);
        RETURN;
    END

    SELECT @CorrectAnswers = COUNT(*)
    FROM Answers A
    INNER JOIN Question Q ON A.QuestionID = Q.QuestionID
    WHERE A.StudentID = @StudentID AND A.ExamID = @ExamID
          AND A.St_Answer = Q.CorrectAnswer;
    SET @Grade = @CorrectAnswers;

    SET @Percentage = (CAST(@CorrectAnswers AS FLOAT) / @TotalQuestions) * 100;


    SELECT @MinDegree = MinDegree ,
	 @Duration = duration,
	 @assigndate = CAST(CONCAT(CONVERT(VARCHAR(10), ExamDate, 120), ' ', CONVERT(VARCHAR(8), StartTime, 108)) AS DATETIME)
	FROM Exam WHERE ExamID = @ExamID;

	SELECT @Studentname =StudentName
	from Student
	WHERE StudentID=@StudentID

    INSERT INTO student_exam (Std_ID,StudentName, ex_ID, st_Grade, exam_percentage, St_status,AssignedDate,Duration)
    VALUES (
        @StudentID,
		@Studentname,
        @ExamID,
        @Grade,
        @Percentage,
        CASE WHEN @Grade >= @MinDegree THEN 'Passed' ELSE 'Failed' END,
		@assigndate,
		@Duration
		
    );
END;
EXEC Exam_Correction @StudentID = 1, @ExamID = 1;
EXEC Exam_Correction @StudentID = 2, @ExamID = 1;

SELECT * FROM student_exam WHERE Std_ID = 1 AND ex_ID = 1;

-- Student Answers
CREATE PROCEDURE Add_Student_Answer
    @ExamID INT,
    @QuestionID INT,
    @StudentID INT,
    @St_Answer CHAR(1)
AS
BEGIN
    INSERT INTO Answers (ExamID, QuestionID, StudentID, St_Answer)
    VALUES (@ExamID, @QuestionID, @StudentID, @St_Answer);
END;

--Questions
EXEC Add_Question_To_Exam @QuestionID = 1, @Type = 'MCQ', @QuestionText = 'What is the capital of USA?', @CorrectAnswer = 'B', @CourseID = 1, @ExamID = 1;
EXEC Add_Choices_To_Question @ChoiceID = 1, @ChoiceText = 'Washington DC', @QuestionID = 1;
EXEC Add_Choices_To_Question @ChoiceID = 2, @ChoiceText = 'New York', @QuestionID = 1;
EXEC Add_Choices_To_Question @ChoiceID = 3, @ChoiceText = 'Los Angeles', @QuestionID = 1;
EXEC Add_Choices_To_Question @ChoiceID = 4, @ChoiceText = 'Chicago', @QuestionID = 1;

EXEC Add_Question_To_Exam @QuestionID = 2, @Type = 'True/False', @QuestionText = 'The Earth is flat.', @CorrectAnswer = 'F', @CourseID = 1, @ExamID = 1;

EXEC Add_Question_To_Exam @QuestionID = 3, @Type = 'MCQ', @QuestionText = 'Which planet is known as the Red Planet?', @CorrectAnswer = 'A', @CourseID = 1, @ExamID = 1;
EXEC Add_Choices_To_Question @ChoiceID = 5, @ChoiceText = 'Mars', @QuestionID = 3;
EXEC Add_Choices_To_Question @ChoiceID = 6, @ChoiceText = 'Venus', @QuestionID = 3;
EXEC Add_Choices_To_Question @ChoiceID = 7, @ChoiceText = 'Earth', @QuestionID = 3;
EXEC Add_Choices_To_Question @ChoiceID = 8, @ChoiceText = 'Jupiter', @QuestionID = 3;

EXEC Add_Question_To_Exam @QuestionID = 4, @Type = 'True/False', @QuestionText = 'Water boils at 100°C.', @CorrectAnswer = 'T', @CourseID = 1, @ExamID = 1;


EXEC Add_Question_To_Exam @QuestionID = 5, @Type = 'MCQ', @QuestionText = 'Which country is the largest by land area?', @CorrectAnswer = 'C', @CourseID = 1, @ExamID = 1;

EXEC Add_Choices_To_Question @ChoiceID = 9, @ChoiceText = 'Canada', @QuestionID = 5;
EXEC Add_Choices_To_Question @ChoiceID = 10, @ChoiceText = 'Russia', @QuestionID = 5;
EXEC Add_Choices_To_Question @ChoiceID = 11, @ChoiceText = 'USA', @QuestionID = 5;

EXEC Add_Question_To_Exam @QuestionID = 6, @Type = 'True/False', @QuestionText = 'The moon is a star.', @CorrectAnswer = 'F', @CourseID = 1, @ExamID = 1;

EXEC Add_Question_To_Exam @QuestionID = 7, @Type = 'MCQ', @QuestionText = 'Who developed the theory of relativity?', @CorrectAnswer = 'B', @CourseID = 1, @ExamID = 1;
EXEC Add_Choices_To_Question @ChoiceID = 12, @ChoiceText = 'Isaac Newton', @QuestionID = 7;
EXEC Add_Choices_To_Question @ChoiceID = 13, @ChoiceText = 'Albert Einstein', @QuestionID = 7;
EXEC Add_Choices_To_Question @ChoiceID = 14, @ChoiceText = 'Galileo Galilei', @QuestionID = 7;
EXEC Add_Choices_To_Question @ChoiceID = 15, @ChoiceText = 'Nikola Tesla', @QuestionID = 7;

EXEC Add_Question_To_Exam @QuestionID = 8, @Type = 'True/False', @QuestionText = 'An octopus has 8 legs.', @CorrectAnswer = 'T', @CourseID = 1, @ExamID = 1;

EXEC Add_Question_To_Exam @QuestionID = 9, @Type = 'MCQ', @QuestionText = 'Which of these is the largest mammal?', @CorrectAnswer = 'D', @CourseID = 1, @ExamID = 1;
EXEC Add_Choices_To_Question @ChoiceID = 16, @ChoiceText = 'Elephant', @QuestionID = 9;
EXEC Add_Choices_To_Question @ChoiceID = 17, @ChoiceText = 'Blue Whale', @QuestionID = 9;
EXEC Add_Choices_To_Question @ChoiceID = 18, @ChoiceText = 'Giraffe', @QuestionID = 9;
EXEC Add_Choices_To_Question @ChoiceID = 19, @ChoiceText = 'Shark', @QuestionID = 9;

EXEC Add_Question_To_Exam 
    @QuestionID = 10, 
    @Type = 'MCQ', 
    @QuestionText = 'What does RAM stand for?', 
    @CorrectAnswer = 'A', 
    @CourseID = 1, 
    @ExamID = 1;

EXEC Add_Choices_To_Question @ChoiceID = 20, @ChoiceText = 'Random Access Memory', @QuestionID = 10;
EXEC Add_Choices_To_Question @ChoiceID = 21, @ChoiceText = 'Readily Available Memory', @QuestionID = 10;
EXEC Add_Choices_To_Question @ChoiceID = 22, @ChoiceText = 'Run Access Mode', @QuestionID = 10;
EXEC Add_Choices_To_Question @ChoiceID = 23, @ChoiceText = 'Remote Access Memory', @QuestionID = 10;

EXEC Add_Question_To_Exam 
    @QuestionID = 11, 
    @Type = 'True/False', 
    @QuestionText = 'SQL is used to manage databases.', 
    @CorrectAnswer = 'T', 
    @CourseID = 1, 
    @ExamID = 1;

EXEC Add_Question_To_Exam 
    @QuestionID = 12, 
    @Type = 'MCQ', 
    @QuestionText = 'What is the primary function of a firewall?', 
    @CorrectAnswer = 'B', 
    @CourseID = 1, 
    @ExamID = 1;

EXEC Add_Choices_To_Question @ChoiceID = 24, @ChoiceText = 'Increase internet speed', @QuestionID = 12;
EXEC Add_Choices_To_Question @ChoiceID = 25, @ChoiceText = 'Block unauthorized access', @QuestionID = 12;
EXEC Add_Choices_To_Question @ChoiceID = 26, @ChoiceText = 'Store data securely', @QuestionID = 12;
EXEC Add_Choices_To_Question @ChoiceID = 27, @ChoiceText = 'Manage user passwords', @QuestionID = 12;

EXEC Add_Question_To_Exam 
    @QuestionID = 13, 
    @Type = 'True/False', 
    @QuestionText = 'Water boils at 100 degrees Celsius at sea level.', 
    @CorrectAnswer = 'T', 
    @CourseID = 1, 
    @ExamID = 1;


EXEC Add_Question_To_Exam 
    @QuestionID = 14, 
    @Type = 'MCQ', 
    @QuestionText = 'Which language is used to style web pages?', 
    @CorrectAnswer = 'C', 
    @CourseID = 1, 
    @ExamID = 1;

EXEC Add_Choices_To_Question @ChoiceID = 28, @ChoiceText = 'HTML', @QuestionID = 14;
EXEC Add_Choices_To_Question @ChoiceID = 29, @ChoiceText = 'Python', @QuestionID = 14;
EXEC Add_Choices_To_Question @ChoiceID = 30, @ChoiceText = 'CSS', @QuestionID = 14;
EXEC Add_Choices_To_Question @ChoiceID = 31, @ChoiceText = 'SQL', @QuestionID = 14;

-- Delete All Students
CREATE PROCEDURE DeleteAllStudentExams
AS
BEGIN
    DELETE FROM student_exam;
END;
EXEC DeleteAllStudentExams;

--Add Studenst
EXEC AddStudent 
    @StudentID = 16,
    @StudentName = 'Ahmed Saber',
    @StudentAge = 23,
    @StudentAddress = 'Aswan',
    @StudentPhone = '01277889900';

--Assign Student and his Answers To Exam
--FullMarkAnswers
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 1, @StudentID = 8, @St_Answer = 'B';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 2, @StudentID = 8, @St_Answer = 'F';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 3, @StudentID = 8, @St_Answer = 'A';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 4, @StudentID = 8, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 5, @StudentID = 8, @St_Answer = 'C';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 6, @StudentID = 8, @St_Answer = 'F';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 7, @StudentID = 8, @St_Answer = 'B';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 8, @StudentID = 8, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 9, @StudentID = 8, @St_Answer = 'D';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 10, @StudentID = 8, @St_Answer = 'A';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 11, @StudentID = 8, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 12, @StudentID = 8, @St_Answer = 'B';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 13, @StudentID = 8, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 14, @StudentID = 8, @St_Answer = 'C';
-- 2 Wrongs
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 1, @StudentID = 7, @St_Answer = 'B';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 2, @StudentID = 7, @St_Answer = 'F';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 3, @StudentID = 7, @St_Answer = 'A';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 4, @StudentID = 7, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 5, @StudentID = 7, @St_Answer = 'C';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 6, @StudentID = 7, @St_Answer = 'F';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 7, @StudentID = 7, @St_Answer = 'B';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 8, @StudentID = 7, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 9, @StudentID = 7, @St_Answer = 'C';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 10, @StudentID = 7, @St_Answer = 'A';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 11, @StudentID = 7, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 12, @StudentID = 7, @St_Answer = 'B';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 13, @StudentID = 7, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 14, @StudentID = 7, @St_Answer = 'B';
-- Random
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 1, @StudentID = 12, @St_Answer = 'B';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 2, @StudentID = 12, @St_Answer = 'F';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 3, @StudentID = 12, @St_Answer = 'A';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 4, @StudentID = 12, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 5, @StudentID = 12, @St_Answer = 'C';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 6, @StudentID = 12, @St_Answer = 'F';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 7, @StudentID = 12, @St_Answer = 'B';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 8, @StudentID = 12, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 9, @StudentID = 12, @St_Answer = 'A';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 10, @StudentID = 12, @St_Answer = 'B';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 11, @StudentID = 12, @St_Answer = 'T';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 12, @StudentID = 12, @St_Answer = 'C';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 13, @StudentID = 12, @St_Answer = 'F';
EXEC Add_Student_Answer @ExamID = 1, @QuestionID = 14, @StudentID = 12, @St_Answer = 'B';


EXEC Exam_Correction @StudentID = 12, @ExamID = 1;
SELECT * FROM student_exam

--Top 3 based on Grade
SELECT
  Std_ID,
  StudentName,
  st_Grade,
  rk
FROM (
  SELECT
    Std_ID,
    StudentName,
    st_Grade,
    RANK() OVER (ORDER BY st_Grade DESC) AS rk
  FROM student_exam
) t
WHERE rk <= 3
ORDER BY rk, StudentName;
