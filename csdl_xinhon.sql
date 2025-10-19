-- ========================================
-- TABLES
-- ========================================
create table users (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  name VARCHAR(150) not null,
  email VARCHAR(150) not null unique,
  password VARCHAR(255) not null,
  role ENUM('admin', 'teacher', 'student') not null,
  phone VARCHAR(30) null,
  status ENUM('active', 'inactive', 'blocked') not null default 'active',
  last_login_at DATETIME null,
  created_at DATETIME not null default CURRENT_TIMESTAMP,
  updated_at DATETIME not null default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  INDEX idx_users_role (role),
  INDEX idx_users_status (status)
) ENGINE = InnoDB;

create table students (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  user_id BIGINT UNSIGNED not null unique,
  student_code VARCHAR(50) not null unique,
  faculty VARCHAR(150) null,
  class_name VARCHAR(150) null,
  extra_info JSON null,
  foreign KEY (user_id) references users (id) on delete CASCADE on update CASCADE
) ENGINE = InnoDB;

create table teachers (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  user_id BIGINT UNSIGNED not null unique,
  teacher_code VARCHAR(50) not null unique,
  dept VARCHAR(150) null,
  foreign KEY (user_id) references users (id) on delete CASCADE on update CASCADE
) ENGINE = InnoDB;

create table courses (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  code VARCHAR(50) not null unique,
  name VARCHAR(200) not null,
  credits TINYINT UNSIGNED not null default 3,
  created_at DATETIME not null default CURRENT_TIMESTAMP,
  updated_at DATETIME not null default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP
) ENGINE = InnoDB;

create table class_sections (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  course_id BIGINT UNSIGNED not null,
  teacher_id BIGINT UNSIGNED not null,
  term VARCHAR(50) not null,
  room VARCHAR(50) null,
  capacity INT UNSIGNED null,
  start_date DATE null,
  end_date DATE null,
  created_at DATETIME not null default CURRENT_TIMESTAMP,
  updated_at DATETIME not null default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  unique KEY uq_course_term_teacher (course_id, term, teacher_id),
  foreign KEY (course_id) references courses (id) on delete RESTRICT on update CASCADE,
  foreign KEY (teacher_id) references teachers (id) on delete RESTRICT on update CASCADE,
  INDEX idx_class_term (term),
  INDEX idx_class_teacher (teacher_id)
) ENGINE = InnoDB;

create table class_section_students (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  class_section_id BIGINT UNSIGNED not null,
  student_id BIGINT UNSIGNED not null,
  enrolled_at DATETIME not null default CURRENT_TIMESTAMP,
  unique KEY uq_cls_student (class_section_id, student_id),
  foreign KEY (class_section_id) references class_sections (id) on delete CASCADE on update CASCADE,
  foreign KEY (student_id) references students (id) on delete CASCADE on update CASCADE,
  INDEX idx_cls_student (student_id)
) ENGINE = InnoDB;

-- Note: WEEKDAY() in MySQL returns 0=Monday .. 6=Sunday
create table schedules (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  class_section_id BIGINT UNSIGNED not null,
  date DATE null,
  weekday TINYINT UNSIGNED null, -- 0=Monday .. 6=Sunday (matches WEEKDAY())
  start_time TIME not null,
  end_time TIME not null,
  recurring_flag TINYINT (1) not null default 0,
  location_lat DECIMAL(10, 7) null,
  location_lng DECIMAL(10, 7) null,
  created_at DATETIME not null default CURRENT_TIMESTAMP,
  updated_at DATETIME not null default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  foreign KEY (class_section_id) references class_sections (id) on delete CASCADE on update CASCADE,
  INDEX idx_schedules_cls (class_section_id),
  INDEX idx_schedules_date (date),
  INDEX idx_schedules_weekday (weekday, start_time)
) ENGINE = InnoDB;

create table attendance_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  class_section_id BIGINT UNSIGNED not null,
  schedule_id BIGINT UNSIGNED null,
  created_by BIGINT UNSIGNED not null,
  start_at DATETIME not null,
  end_at DATETIME not null,
  mode_flags JSON not null,
  password_hash VARCHAR(255) null,
  status ENUM('open', 'closed', 'cancelled') not null default 'open',
  created_at DATETIME not null default CURRENT_TIMESTAMP,
  updated_at DATETIME not null default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  foreign KEY (class_section_id) references class_sections (id) on delete CASCADE on update CASCADE,
  foreign KEY (schedule_id) references schedules (id) on delete set null on update CASCADE,
  foreign KEY (created_by) references users (id) on delete RESTRICT on update CASCADE,
  INDEX idx_att_sess_cls (class_section_id),
  INDEX idx_att_sess_time (start_at, end_at),
  INDEX idx_att_sess_status (status)
) ENGINE = InnoDB;

create table qr_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  attendance_session_id BIGINT UNSIGNED not null,
  token CHAR(64) not null unique,
  expires_at DATETIME not null,
  created_at DATETIME not null default CURRENT_TIMESTAMP,
  foreign KEY (attendance_session_id) references attendance_sessions (id) on delete CASCADE on update CASCADE,
  INDEX idx_qr_exp (expires_at)
) ENGINE = InnoDB;

create table attendance_records (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  attendance_session_id BIGINT UNSIGNED not null,
  student_id BIGINT UNSIGNED not null,
  status ENUM('present', 'late', 'absent') not null,
  photo_path VARCHAR(255) null,
  gps_lat DECIMAL(10, 7) null,
  gps_lng DECIMAL(10, 7) null,
  note VARCHAR(255) null,
  created_at DATETIME not null default CURRENT_TIMESTAMP,
  unique KEY uq_session_student (attendance_session_id, student_id),
  foreign KEY (attendance_session_id) references attendance_sessions (id) on delete CASCADE on update CASCADE,
  foreign KEY (student_id) references students (id) on delete CASCADE on update CASCADE,
  INDEX idx_att_rec_student (student_id),
  INDEX idx_att_rec_status (status)
) ENGINE = InnoDB;

create table api_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT primary key,
  user_id BIGINT UNSIGNED not null,
  token CHAR(64) not null unique,
  expires_at DATETIME not null,
  created_at DATETIME not null default CURRENT_TIMESTAMP,
  foreign KEY (user_id) references users (id) on delete CASCADE on update CASCADE,
  INDEX idx_token_exp (expires_at)
) ENGINE = InnoDB;

-- ========================================
-- VIEWS
-- ========================================
create or replace view vw_class_attendance_rate as
select
  cs.id as class_section_id,
  c.code as course_code,
  c.name as course_name,
  cs.term,
  COUNT(distinct ar.attendance_session_id) as total_sessions_with_records,
  SUM(ar.status = 'present') as total_present,
  SUM(ar.status = 'late') as total_late,
  SUM(ar.status = 'absent') as total_absent,
  (
    SUM(ar.status = 'present') + SUM(ar.status = 'late')
  ) / NULLIF(
    SUM(ar.status in ('present', 'late', 'absent')),
    0
  ) as attendance_rate
from
  class_sections cs
  join courses c on c.id = cs.course_id
  left join attendance_sessions s on s.class_section_id = cs.id
  left join attendance_records ar on ar.attendance_session_id = s.id
group by
  cs.id;

create or replace view vw_session_detail as
select
  s.id as session_id,
  cs.id as class_section_id,
  c.code as course_code,
  c.name as course_name,
  s.start_at,
  s.end_at,
  s.status,
  st.id as student_id,
  u.name as student_name,
  ar.status as attendance_status,
  ar.photo_path,
  ar.gps_lat,
  ar.gps_lng,
  ar.created_at as checked_at
from
  attendance_sessions s
  join class_sections cs on cs.id = s.class_section_id
  join courses c on c.id = cs.course_id
  left join attendance_records ar on ar.attendance_session_id = s.id
  left join students st on st.id = ar.student_id
  left join users u on u.id = st.user_id;

-- ========================================
-- STORED PROCEDURE
-- ========================================
DELIMITER $$

CREATE PROCEDURE sp_teacher_daily_schedule(
    IN p_teacher_user_id BIGINT,
    IN p_date DATE
)
BEGIN
    SELECT sc.id AS class_section_id,
           c.code,
           c.name,
           sc.term,
           sch.start_time,
           sch.end_time,
           sc.room
    FROM class_sections sc
    JOIN teachers t    ON t.id = sc.teacher_id
    JOIN users tu      ON tu.id = t.user_id
    JOIN courses c     ON c.id = sc.course_id
    JOIN schedules sch ON sch.class_section_id = sc.id
    WHERE tu.id = p_teacher_user_id
      AND (
        (sch.recurring_flag = 0 AND sch.date = p_date)
        OR
        (sch.recurring_flag = 1 AND sch.weekday = WEEKDAY(p_date))
      )
    ORDER BY sch.start_time;
END$$

DELIMITER ;

DROP PROCEDURE sp_teacher_daily_schedule;



-- ========================================
-- SAMPLE DATA (fixed)
-- ========================================
insert into users (name, email, password, role) values
  ('Admin', 'admin@example.com', 'admin', 'admin'),
  ('GV A', 'teacher.a@example.com', 'teacher', 'teacher'),
  ('GV B', 'teacher.b@example.com', 'teacher', 'teacher'),
  ('GV C', 'teacher.c@example.com', 'teacher', 'teacher'),
  ('SV A', 'student.a@example.com', 'student', 'student'),
  ('SV B', 'student.b@example.com', 'student', 'student'),
  ('SV C', 'student.c@example.com', 'student', 'student');

-- teachers via INSERT ... SELECT using UNION ALL
insert into teachers (user_id, teacher_code, dept)
select id, 'T001', 'CNTT' from users where email = 'teacher.a@example.com'
UNION ALL
select id, 'T002', 'KT'   from users where email = 'teacher.b@example.com'
UNION ALL
select id, 'T003', 'H'    from users where email = 'teacher.c@example.com';

-- students via INSERT ... SELECT using UNION ALL
insert into students (user_id, student_code, faculty, class_name)
select id, 'S001', 'CNTT', 'K66-CNTT1' from users where email = 'student.a@example.com'
UNION ALL
select id, 'S002', 'CNTT', 'K66-KTPM3' from users where email = 'student.b@example.com'
UNION ALL
select id, 'S003', 'KT',   'K66-TCNH1' from users where email = 'student.c@example.com';

-- courses
insert into courses (code, name, credits) values
  ('CSE100', 'Nhập môn lập trình', 3),
  ('CSE200', 'Xác suất thống kê', 3),
  ('CSE300', 'Lịch sử Đảng cộng sản Việt Nam', 2);

-- class_sections (fix end_date for the third section)
insert into class_sections (
  course_id,
  teacher_id,
  term,
  room,
  capacity,
  start_date,
  end_date
)
select
  c.id,
  t.id,
  'Kì 1 - 2025',
  'B5-207',
  60,
  '2025-09-01',
  '2025-12-20'
from
  courses c,
  teachers t
where
  c.code = 'CSE100'
  and t.teacher_code = 'T001';

insert into class_sections (
  course_id,
  teacher_id,
  term,
  room,
  capacity,
  start_date,
  end_date
)
select
  c.id,
  t.id,
  'Kì 1 - 2025',
  'A4-304',
  60,
  '2025-09-01',
  '2025-12-20'
from
  courses c,
  teachers t
where
  c.code = 'CSE200'
  and t.teacher_code = 'T002';

insert into class_sections (
  course_id,
  teacher_id,
  term,
  room,
  capacity,
  start_date,
  end_date
)
select
  c.id,
  t.id,
  'Kì 2 - 2025',
  'B2-313',
  60,
  '2026-01-10',
  '2026-04-02'
from
  courses c,
  teachers t
where
  c.code = 'CSE300'
  and t.teacher_code = 'T003';

-- schedules: join class_sections to courses to filter by course code
insert into schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
select
  cs.id,
  2,
  '07:00:00',
  '09:35:00',
  1
from
  class_sections cs
  join courses c on cs.course_id = c.id
where
  c.code = 'CSE100';

insert into schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
select
  cs.id,
  2,
  '09:40:00',
  '12:25:00',
  1
from
  class_sections cs
  join courses c on cs.course_id = c.id
where
  c.code = 'CSE200';

insert into schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
select
  cs.id,
  5,
  '12:55:00',
  '15:35:00',
  1
from
  class_sections cs
  join courses c on cs.course_id = c.id
where
  c.code = 'CSE300';

-- class_section_students: structured, explicit joins + UNION ALL
insert into class_section_students (class_section_id, student_id)
select cs.id, s.id
from class_sections cs
join courses c on cs.course_id = c.id
join students s on 1=1
where c.code = 'CSE100' and s.student_code in ('S001')
UNION ALL
select cs.id, s.id
from class_sections cs
join courses c on cs.course_id = c.id
join students s on 1=1
where c.code = 'CSE200' and s.student_code in ('S001', 'S002', 'S003')
UNION ALL
select cs.id, s.id
from class_sections cs
join courses c on cs.course_id = c.id
join students s on 1=1
where c.code = 'CSE300' and s.student_code in ('S002', 'S003');

-- final message
select '✅ Database attendance đã được khởi tạo thành công!' as Result;

SELECT * from students;
SELECT * FROM users;

-- =======================================================================================================================================================

ALTER TABLE class_sections
MODIFY COLUMN start_date DATE NOT NULL DEFAULT (CURDATE()),
MODIFY COLUMN end_date DATE NOT NULL DEFAULT (DATE_ADD(CURDATE(), INTERVAL 9 WEEK));




-- View lịch dạy của giảng viên
CREATE OR REPLACE VIEW vw_teacher_schedule AS
SELECT 
  t.id AS teacher_id,
  u.name AS teacher_name,
  c.code AS course_code,
  c.name AS course_name,
  cs.term,
  cs.room,
  sch.weekday,
  sch.start_time,
  sch.end_time,
  cs.start_date,
  cs.end_date
FROM teachers t
JOIN users u ON u.id = t.user_id
JOIN class_sections cs ON cs.teacher_id = t.id
JOIN courses c ON c.id = cs.course_id
JOIN schedules sch ON sch.class_section_id = cs.id;

-- View lịch học của sinh viên
CREATE OR REPLACE VIEW vw_student_schedule AS
SELECT 
  s.id AS student_id,
  u.name AS student_name,
  c.code AS course_code,
  c.name AS course_name,
  cs.term,
  cs.room,
  sch.weekday,
  sch.start_time,
  sch.end_time,
  cs.start_date,
  cs.end_date
FROM students s
JOIN users u ON u.id = s.user_id
JOIN class_section_students css ON css.student_id = s.id
JOIN class_sections cs ON cs.id = css.class_section_id
JOIN courses c ON c.id = cs.course_id
JOIN schedules sch ON sch.class_section_id = cs.id;





-- test 
SET @uid := (SELECT u.id FROM users u JOIN teachers t ON t.user_id=u.id WHERE t.teacher_code='T001' LIMIT 1);
SELECT sc.id class_section_id, c.code, c.name, sch.weekday, sch.start_time, sch.end_time
FROM class_sections sc
JOIN teachers t ON t.id=sc.teacher_id
JOIN users    u ON u.id=t.user_id
JOIN courses  c ON c.id=sc.course_id
JOIN schedules sch ON sch.class_section_id=sc.id
WHERE u.id=@uid
  AND 
    (sch.recurring_flag=1 AND sch.weekday=WEEKDAY(CURDATE())
  )
ORDER BY sch.start_time;

SELECT CURDATE() AS today, WEEKDAY(CURDATE()) AS weekday_today; 


-- ===============================================================================================================================
-- T001 dạy:
--   • CSE100 — Thứ 2 & Thứ 6: 07:55–09:40
--   • CSE400 — Thứ 2 & Thứ 5: 09:45–11:30
-- ==========================================================

-- CSE100 - Thứ 2
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 0, '07:55:00', '09:40:00', 1
FROM class_sections cs
JOIN courses c ON c.id = cs.course_id
JOIN teachers t ON t.id = cs.teacher_id
WHERE c.code = 'CSE100' AND t.teacher_code = 'T001'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id = cs.id AND s.weekday = 0 AND s.start_time = '07:55:00'
);

-- CSE100 - Thứ 6
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 4, '07:55:00', '09:40:00', 1
FROM class_sections cs
JOIN courses c ON c.id = cs.course_id
JOIN teachers t ON t.id = cs.teacher_id
WHERE c.code = 'CSE100' AND t.teacher_code = 'T001'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id = cs.id AND s.weekday = 4 AND s.start_time = '07:55:00'
);

-- CSE400 - Thứ 2
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 0, '09:45:00', '11:30:00', 1
FROM class_sections cs
JOIN courses c ON c.id = cs.course_id
JOIN teachers t ON t.id = cs.teacher_id
WHERE c.code = 'CSE400' AND t.teacher_code = 'T001'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id = cs.id AND s.weekday = 0 AND s.start_time = '09:45:00'
);

-- CSE400 - Thứ 5
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 3, '09:45:00', '11:30:00', 1
FROM class_sections cs
JOIN courses c ON c.id = cs.course_id
JOIN teachers t ON t.id = cs.teacher_id
WHERE c.code = 'CSE400' AND t.teacher_code = 'T001'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id = cs.id AND s.weekday = 3 AND s.start_time = '09:45:00'
);

-- ==========================================================
-- T002 dạy:
--   • CSE200 — Thứ 3 & Thứ 5: 07:55–09:40
--   • CSE500 — Thứ 4: 13:30–15:15
-- ==========================================================

-- CSE200 - Thứ 3
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 1, '07:55:00', '09:40:00', 1
FROM class_sections cs
JOIN courses c ON c.id = cs.course_id
JOIN teachers t ON t.id = cs.teacher_id
WHERE c.code = 'CSE200' AND t.teacher_code = 'T002'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id = cs.id AND s.weekday = 1 AND s.start_time = '07:55:00'
);

-- CSE200 - Thứ 5
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 3, '07:55:00', '09:40:00', 1
FROM class_sections cs
JOIN courses c ON c.id = cs.course_id
JOIN teachers t ON t.id = cs.teacher_id
WHERE c.code = 'CSE200' AND t.teacher_code = 'T002'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id = cs.id AND s.weekday = 3 AND s.start_time = '07:55:00'
);

-- CSE500 - Thứ 4
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 2, '13:30:00', '15:15:00', 1
FROM class_sections cs
JOIN courses c ON c.id = cs.course_id
JOIN teachers t ON t.id = cs.teacher_id
WHERE c.code = 'CSE500' AND t.teacher_code = 'T002'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id = cs.id AND s.weekday = 2 AND s.start_time = '13:30:00'
);

-- ==========================================================
-- T003 dạy:
--   • CSE300 — Thứ 4: 09:45–11:30
--   • CSE500 — Thứ 7: 12:55–15:30
-- ==========================================================

-- CSE300 - Thứ 4
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 2, '09:45:00', '11:30:00', 1
FROM class_sections cs
JOIN courses c ON c.id = cs.course_id
JOIN teachers t ON t.id = cs.teacher_id
WHERE c.code = 'CSE300' AND t.teacher_code = 'T003'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id = cs.id AND s.weekday = 2 AND s.start_time = '09:45:00'
);

-- CSE500 - Thứ 7
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 5, '12:55:00', '15:30:00', 1
FROM class_sections cs
JOIN courses c ON c.id = cs.course_id
JOIN teachers t ON t.id = cs.teacher_id
WHERE c.code = 'CSE500' AND t.teacher_code = 'T003'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id = cs.id AND s.weekday = 5 AND s.start_time = '12:55:00'
);

