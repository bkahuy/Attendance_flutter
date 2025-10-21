CREATE TABLE faculties (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE departments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE majors (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  faculty_id BIGINT UNSIGNED NOT NULL,
  department_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (faculty_id) REFERENCES faculties (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (department_id) REFERENCES departments (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  UNIQUE KEY uq_major_name_faculty (name, faculty_id)
) ENGINE = InnoDB;

CREATE TABLE classes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  major_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (major_id) REFERENCES majors (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  UNIQUE KEY uq_class_name_major (name, major_id)
) ENGINE = InnoDB;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role ENUM('admin', 'teacher', 'student') NOT NULL,
  phone VARCHAR(30) NULL,
  status ENUM('active', 'inactive', 'blocked') NOT NULL DEFAULT 'active',
  last_login_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_role (role),
  INDEX idx_users_status (status)
) ENGINE = InnoDB;

CREATE TABLE students (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL UNIQUE,
  student_code VARCHAR(50) NOT NULL UNIQUE,
  class_id BIGINT UNSIGNED NOT NULL,
  birthday DATE NULL,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE teachers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL UNIQUE,
  teacher_code VARCHAR(50) NOT NULL UNIQUE,
  department_id BIGINT UNSIGNED NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (department_id) REFERENCES departments (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE courses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  credits TINYINT UNSIGNED NOT NULL DEFAULT 3,
  department_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (department_id) REFERENCES departments (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE class_sections (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id BIGINT UNSIGNED NOT NULL,
  teacher_id BIGINT UNSIGNED NOT NULL,
  major_id BIGINT UNSIGNED NOT NULL,
  term VARCHAR(50) NOT NULL,
  room VARCHAR(50) NULL,
  capacity INT UNSIGNED NULL,
  start_date DATE NULL,
  end_date DATE NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (teacher_id) REFERENCES teachers (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (major_id) REFERENCES majors (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_class_term (term),
  INDEX idx_class_teacher (teacher_id)
) ENGINE = InnoDB;

CREATE TABLE class_section_classes (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  class_section_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_section_class (class_section_id, class_id),
  FOREIGN KEY (class_section_id) REFERENCES class_sections (id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (class_id) REFERENCES classes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE class_section_students (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  class_section_id BIGINT UNSIGNED NOT NULL,
  student_id BIGINT UNSIGNED NOT NULL,
  enrolled_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_cls_student (class_section_id, student_id),
  FOREIGN KEY (class_section_id) REFERENCES class_sections (id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_cls_student (student_id)
) ENGINE = InnoDB;

-- Note: WEEKDAY() in MySQL returns 0=Monday .. 6=Sunday
CREATE TABLE schedules (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  class_section_id BIGINT UNSIGNED NOT NULL,
  date DATE NULL,
  weekday TINYINT UNSIGNED NULL, -- 0=Monday .. 6=Sunday (matches WEEKDAY())
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  recurring_flag TINYINT (1) NOT NULL DEFAULT 0,
  location_lat DECIMAL(10, 7) NULL,
  location_lng DECIMAL(10, 7) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (class_section_id) REFERENCES class_sections (id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_schedules_cls (class_section_id),
  INDEX idx_schedules_date (date),
  INDEX idx_schedules_weekday (weekday, start_time)
) ENGINE = InnoDB;

CREATE TABLE attendance_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  class_section_id BIGINT UNSIGNED NOT NULL,
  schedule_id BIGINT UNSIGNED NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  mode_flags JSON NOT NULL,
  password_hash VARCHAR(255) NULL,
  status ENUM('open', 'closed', 'cancelled') NOT NULL DEFAULT 'open',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (class_section_id) REFERENCES class_sections (id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (schedule_id) REFERENCES schedules (id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_att_sess_cls (class_section_id),
  INDEX idx_att_sess_time (start_at, end_at),
  INDEX idx_att_sess_status (status)
) ENGINE = InnoDB;

CREATE TABLE qr_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  attendance_session_id BIGINT UNSIGNED NOT NULL,
  token CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (attendance_session_id) REFERENCES attendance_sessions (id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_qr_exp (expires_at)
) ENGINE = InnoDB;

CREATE TABLE attendance_records (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  attendance_session_id BIGINT UNSIGNED NOT NULL,
  student_id BIGINT UNSIGNED NOT NULL,
  status ENUM('present', 'late', 'absent') NOT NULL,
  photo_path VARCHAR(255) NULL,
  gps_lat DECIMAL(10, 7) NULL,
  gps_lng DECIMAL(10, 7) NULL,
  note VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_session_student (attendance_session_id, student_id),
  FOREIGN KEY (attendance_session_id) REFERENCES attendance_sessions (id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_att_rec_student (student_id),
  INDEX idx_att_rec_status (status)
) ENGINE = InnoDB;

CREATE TABLE api_tokens (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX idx_token_exp (expires_at)
) ENGINE = InnoDB;

-- ========================================
-- VIEWS
-- ========================================
CREATE OR REPLACE VIEW vw_class_attendance_rate AS
SELECT
  cs.id AS class_section_id,
  c.code AS course_code,
  c.name AS course_name,
  cs.term,
  COUNT(DISTINCT ar.attendance_session_id) AS total_sessions_with_records,
  SUM(ar.status = 'present') AS total_present,
  SUM(ar.status = 'late') AS total_late,
  SUM(ar.status = 'absent') AS total_absent,
  (
    SUM(ar.status = 'present') + SUM(ar.status = 'late')
  ) / NULLIF(
    SUM(ar.status IN ('present', 'late', 'absent')),
    0
  ) AS attendance_rate
FROM
  class_sections cs
  JOIN courses c ON c.id = cs.course_id
  LEFT JOIN attendance_sessions s ON s.class_section_id = cs.id
  LEFT JOIN attendance_records ar ON ar.attendance_session_id = s.id
GROUP BY
  cs.id;

CREATE OR REPLACE VIEW vw_session_detail AS
SELECT
  s.id AS session_id,
  cs.id AS class_section_id,
  c.code AS course_code,
  c.name AS course_name,
  s.start_at,
  s.end_at,
  s.status,
  st.id AS student_id,
  u.name AS student_name,
  ar.status AS attendance_status,
  ar.photo_path,
  ar.gps_lat,
  ar.gps_lng,
  ar.created_at AS checked_at
FROM
  attendance_sessions s
  JOIN class_sections cs ON cs.id = s.class_section_id
  JOIN courses c ON c.id = cs.course_id
  LEFT JOIN attendance_records ar ON ar.attendance_session_id = s.id
  LEFT JOIN students st ON st.id = ar.student_id
  LEFT JOIN users u ON u.id = st.user_id;

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
    JOIN teachers t ON t.id = sc.teacher_id
    JOIN users tu ON tu.id = t.user_id
    JOIN courses c ON c.id = sc.course_id
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


-- Insert into faculties (2 khoa)
INSERT INTO faculties (name) VALUES
('Khoa Công nghệ Thông tin'),
('Khoa Kinh tế');

-- Insert into departments (2 bộ môn mỗi khoa, tổng 4 bộ môn)
INSERT INTO departments (name) VALUES
('Bộ môn Công nghệ Phần mềm'),
('Bộ môn Hệ thống Thông tin'),
('Bộ môn Kế toán'),
('Bộ môn Quản trị Kinh doanh');

-- Insert into majors (2 ngành mỗi bộ môn, tổng 8 ngành)
INSERT INTO majors (name, faculty_id, department_id) VALUES
-- Khoa CNTT, Bộ môn Công nghệ Phần mềm
('Công nghệ Thông tin', 1, 1),
('Kỹ thuật Phần mềm', 1, 1),
-- Khoa CNTT, Bộ môn Hệ thống Thông tin
('Hệ thống Thông tin', 1, 2),
('An ninh Mạng', 1, 2),
-- Khoa Kinh tế, Bộ môn Kế toán
('Kế toán', 2, 3),
('Kiểm toán', 2, 3),
-- Khoa Kinh tế, Bộ môn Quản trị Kinh doanh
('Quản trị Kinh doanh', 2, 4),
('Marketing', 2, 4);

-- Insert into classes (3 lớp chính khóa mỗi ngành, tổng 24 lớp)
INSERT INTO classes (name, major_id) VALUES
-- Ngành Công nghệ Thông tin
('CNTT-K62A', 1), ('CNTT-K62B', 1), ('CNTT-K62C', 1),
-- Ngành Kỹ thuật Phần mềm
('KTPM-K62A', 2), ('KTPM-K62B', 2), ('KTPM-K62C', 2),
-- Ngành Hệ thống Thông tin
('HTTT-K62A', 3), ('HTTT-K62B', 3), ('HTTT-K62C', 3),
-- Ngành An ninh Mạng
('ANM-K62A', 4), ('ANM-K62B', 4), ('ANM-K62C', 4),
-- Ngành Kế toán
('KT-K62A', 5), ('KT-K62B', 5), ('KT-K62C', 5),
-- Ngành Kiểm toán
('KTO-K62A', 6), ('KTO-K62B', 6), ('KTO-K62C', 6),
-- Ngành Quản trị Kinh doanh
('QTKD-K62A', 7), ('QTKD-K62B', 7), ('QTKD-K62C', 7),
-- Ngành Marketing
('MKT-K62A', 8), ('MKT-K62B', 8), ('MKT-K62C', 8);

-- Insert into users (129 tài khoản: 120 sinh viên, 8 giảng viên, 1 admin)
INSERT INTO users (name, email, password, role, phone, status) VALUES
-- Admin
('Admin', 'admin@gmail.com', '1', 'admin', '0123456789', 'active'),
-- Giảng viên (4 giảng viên mỗi khoa, tổng 8)
('Nguyễn Văn A', 'gv1@gmail.com', '1', 'teacher', '0123456001', 'active'),
('Trần Thị B', 'gv2@gmail.com', '1', 'teacher', '0123456002', 'active'),
('Lê Văn C', 'gv3@gmail.com', '1', 'teacher', '0123456003', 'active'),
('Phạm Thị D', 'gv4@gmail.com', '1', 'teacher', '0123456004', 'active'),
('Hoàng Văn E', 'gv5@gmail.com', '1', 'teacher', '0123456005', 'active'),
('Ngô Thị F', 'gv6@gmail.com', '1', 'teacher', '0123456006', 'active'),
('Đỗ Văn G', 'gv7@gmail.com', '1', 'teacher', '0123456007', 'active'),
('Vũ Thị H', 'gv8@gmail.com', '1', 'teacher', '0123456008', 'active'),
-- Sinh viên (5 sinh viên mỗi lớp, tổng 120)
('SV001', 'sv001@gmail.com', '1', 'student', '0901000001', 'active'),
('SV002', 'sv002@gmail.com', '1', 'student', '0901000002', 'active'),
('SV003', 'sv003@gmail.com', '1', 'student', '0901000003', 'active'),
('SV004', 'sv004@gmail.com', '1', 'student', '0901000004', 'active'),
('SV005', 'sv005@gmail.com', '1', 'student', '0901000005', 'active'),
('SV006', 'sv006@gmail.com', '1', 'student', '0901000006', 'active'),
('SV007', 'sv007@gmail.com', '1', 'student', '0901000007', 'active'),
('SV008', 'sv008@gmail.com', '1', 'student', '0901000008', 'active'),
('SV009', 'sv009@gmail.com', '1', 'student', '0901000009', 'active'),
('SV010', 'sv010@gmail.com', '1', 'student', '0901000010', 'active'),
('SV011', 'sv011@gmail.com', '1', 'student', '0901000011', 'active'),
('SV012', 'sv012@gmail.com', '1', 'student', '0901000012', 'active'),
('SV013', 'sv013@gmail.com', '1', 'student', '0901000013', 'active'),
('SV014', 'sv014@gmail.com', '1', 'student', '0901000014', 'active'),
('SV015', 'sv015@gmail.com', '1', 'student', '0901000015', 'active'),
('SV016', 'sv016@gmail.com', '1', 'student', '0901000016', 'active'),
('SV017', 'sv017@gmail.com', '1', 'student', '0901000017', 'active'),
('SV018', 'sv018@gmail.com', '1', 'student', '0901000018', 'active'),
('SV019', 'sv019@gmail.com', '1', 'student', '0901000019', 'active'),
('SV020', 'sv020@gmail.com', '1', 'student', '0901000020', 'active'),
('SV021', 'sv021@gmail.com', '1', 'student', '0901000021', 'active'),
('SV022', 'sv022@gmail.com', '1', 'student', '0901000022', 'active'),
('SV023', 'sv023@gmail.com', '1', 'student', '0901000023', 'active'),
('SV024', 'sv024@gmail.com', '1', 'student', '0901000024', 'active'),
('SV025', 'sv025@gmail.com', '1', 'student', '0901000025', 'active'),
('SV026', 'sv026@gmail.com', '1', 'student', '0901000026', 'active'),
('SV027', 'sv027@gmail.com', '1', 'student', '0901000027', 'active'),
('SV028', 'sv028@gmail.com', '1', 'student', '0901000028', 'active'),
('SV029', 'sv029@gmail.com', '1', 'student', '0901000029', 'active'),
('SV030', 'sv030@gmail.com', '1', 'student', '0901000030', 'active'),
('SV031', 'sv031@gmail.com', '1', 'student', '0901000031', 'active'),
('SV032', 'sv032@gmail.com', '1', 'student', '0901000032', 'active'),
('SV033', 'sv033@gmail.com', '1', 'student', '0901000033', 'active'),
('SV034', 'sv034@gmail.com', '1', 'student', '0901000034', 'active'),
('SV035', 'sv035@gmail.com', '1', 'student', '0901000035', 'active'),
('SV036', 'sv036@gmail.com', '1', 'student', '0901000036', 'active'),
('SV037', 'sv037@gmail.com', '1', 'student', '0901000037', 'active'),
('SV038', 'sv038@gmail.com', '1', 'student', '0901000038', 'active'),
('SV039', 'sv039@gmail.com', '1', 'student', '0901000039', 'active'),
('SV040', 'sv040@gmail.com', '1', 'student', '0901000040', 'active'),
('SV041', 'sv041@gmail.com', '1', 'student', '0901000041', 'active'),
('SV042', 'sv042@gmail.com', '1', 'student', '0901000042', 'active'),
('SV043', 'sv043@gmail.com', '1', 'student', '0901000043', 'active'),
('SV044', 'sv044@gmail.com', '1', 'student', '0901000044', 'active'),
('SV045', 'sv045@gmail.com', '1', 'student', '0901000045', 'active'),
('SV046', 'sv046@gmail.com', '1', 'student', '0901000046', 'active'),
('SV047', 'sv047@gmail.com', '1', 'student', '0901000047', 'active'),
('SV048', 'sv048@gmail.com', '1', 'student', '0901000048', 'active'),
('SV049', 'sv049@gmail.com', '1', 'student', '0901000049', 'active'),
('SV050', 'sv050@gmail.com', '1', 'student', '0901000050', 'active'),
('SV051', 'sv051@gmail.com', '1', 'student', '0901000051', 'active'),
('SV052', 'sv052@gmail.com', '1', 'student', '0901000052', 'active'),
('SV053', 'sv053@gmail.com', '1', 'student', '0901000053', 'active'),
('SV054', 'sv054@gmail.com', '1', 'student', '0901000054', 'active'),
('SV055', 'sv055@gmail.com', '1', 'student', '0901000055', 'active'),
('SV056', 'sv056@gmail.com', '1', 'student', '0901000056', 'active'),
('SV057', 'sv057@gmail.com', '1', 'student', '0901000057', 'active'),
('SV058', 'sv058@gmail.com', '1', 'student', '0901000058', 'active'),
('SV059', 'sv059@gmail.com', '1', 'student', '0901000059', 'active'),
('SV060', 'sv060@gmail.com', '1', 'student', '0901000060', 'active'),
('SV061', 'sv061@gmail.com', '1', 'student', '0901000061', 'active'),
('SV062', 'sv062@gmail.com', '1', 'student', '0901000062', 'active'),
('SV063', 'sv063@gmail.com', '1', 'student', '0901000063', 'active'),
('SV064', 'sv064@gmail.com', '1', 'student', '0901000064', 'active'),
('SV065', 'sv065@gmail.com', '1', 'student', '0901000065', 'active'),
('SV066', 'sv066@gmail.com', '1', 'student', '0901000066', 'active'),
('SV067', 'sv067@gmail.com', '1', 'student', '0901000067', 'active'),
('SV068', 'sv068@gmail.com', '1', 'student', '0901000068', 'active'),
('SV069', 'sv069@gmail.com', '1', 'student', '0901000069', 'active'),
('SV070', 'sv070@gmail.com', '1', 'student', '0901000070', 'active'),
('SV071', 'sv071@gmail.com', '1', 'student', '0901000071', 'active'),
('SV072', 'sv072@gmail.com', '1', 'student', '0901000072', 'active'),
('SV073', 'sv073@gmail.com', '1', 'student', '0901000073', 'active'),
('SV074', 'sv074@gmail.com', '1', 'student', '0901000074', 'active'),
('SV075', 'sv075@gmail.com', '1', 'student', '0901000075', 'active'),
('SV076', 'sv076@gmail.com', '1', 'student', '0901000076', 'active'),
('SV077', 'sv077@gmail.com', '1', 'student', '0901000077', 'active'),
('SV078', 'sv078@gmail.com', '1', 'student', '0901000078', 'active'),
('SV079', 'sv079@gmail.com', '1', 'student', '0901000079', 'active'),
('SV080', 'sv080@gmail.com', '1', 'student', '0901000080', 'active'),
('SV081', 'sv081@gmail.com', '1', 'student', '0901000081', 'active'),
('SV082', 'sv082@gmail.com', '1', 'student', '0901000082', 'active'),
('SV083', 'sv083@gmail.com', '1', 'student', '0901000083', 'active'),
('SV084', 'sv084@gmail.com', '1', 'student', '0901000084', 'active'),
('SV085', 'sv085@gmail.com', '1', 'student', '0901000085', 'active'),
('SV086', 'sv086@gmail.com', '1', 'student', '0901000086', 'active'),
('SV087', 'sv087@gmail.com', '1', 'student', '0901000087', 'active'),
('SV088', 'sv088@gmail.com', '1', 'student', '0901000088', 'active'),
('SV089', 'sv089@gmail.com', '1', 'student', '0901000089', 'active'),
('SV090', 'sv090@gmail.com', '1', 'student', '0901000090', 'active'),
('SV091', 'sv091@gmail.com', '1', 'student', '0901000091', 'active'),
('SV092', 'sv092@gmail.com', '1', 'student', '0901000092', 'active'),
('SV093', 'sv093@gmail.com', '1', 'student', '0901000093', 'active'),
('SV094', 'sv094@gmail.com', '1', 'student', '0901000094', 'active'),
('SV095', 'sv095@gmail.com', '1', 'student', '0901000095', 'active'),
('SV096', 'sv096@gmail.com', '1', 'student', '0901000096', 'active'),
('SV097', 'sv097@gmail.com', '1', 'student', '0901000097', 'active'),
('SV098', 'sv098@gmail.com', '1', 'student', '0901000098', 'active'),
('SV099', 'sv099@gmail.com', '1', 'student', '0901000099', 'active'),
('SV100', 'sv100@gmail.com', '1', 'student', '0901000100', 'active'),
('SV101', 'sv101@gmail.com', '1', 'student', '0901000101', 'active'),
('SV102', 'sv102@gmail.com', '1', 'student', '0901000102', 'active'),
('SV103', 'sv103@gmail.com', '1', 'student', '0901000103', 'active'),
('SV104', 'sv104@gmail.com', '1', 'student', '0901000104', 'active'),
('SV105', 'sv105@gmail.com', '1', 'student', '0901000105', 'active'),
('SV106', 'sv106@gmail.com', '1', 'student', '0901000106', 'active'),
('SV107', 'sv107@gmail.com', '1', 'student', '0901000107', 'active'),
('SV108', 'sv108@gmail.com', '1', 'student', '0901000108', 'active'),
('SV109', 'sv109@gmail.com', '1', 'student', '0901000109', 'active'),
('SV110', 'sv110@gmail.com', '1', 'student', '0901000110', 'active'),
('SV111', 'sv111@gmail.com', '1', 'student', '0901000111', 'active'),
('SV112', 'sv112@gmail.com', '1', 'student', '0901000112', 'active'),
('SV113', 'sv113@gmail.com', '1', 'student', '0901000113', 'active'),
('SV114', 'sv114@gmail.com', '1', 'student', '0901000114', 'active'),
('SV115', 'sv115@gmail.com', '1', 'student', '0901000115', 'active'),
('SV116', 'sv116@gmail.com', '1', 'student', '0901000116', 'active'),
('SV117', 'sv117@gmail.com', '1', 'student', '0901000117', 'active'),
('SV118', 'sv118@gmail.com', '1', 'student', '0901000118', 'active'),
('SV119', 'sv119@gmail.com', '1', 'student', '0901000119', 'active'),
('SV120', 'sv120@gmail.com', '1', 'student', '0901000120', 'active');

-- Insert into teachers (8 giảng viên, mỗi khoa 4, phân bổ đều cho bộ môn)
INSERT INTO teachers (user_id, teacher_code, department_id) VALUES
-- Khoa CNTT: Bộ môn Công nghệ Phần mềm (2 giảng viên)
(2, 'GV001', 1),
(3, 'GV002', 1),
-- Khoa CNTT: Bộ môn Hệ thống Thông tin (2 giảng viên)
(4, 'GV003', 2),
(5, 'GV004', 2),
-- Khoa Kinh tế: Bộ môn Kế toán (2 giảng viên)
(6, 'GV005', 3),
(7, 'GV006', 3),
-- Khoa Kinh tế: Bộ môn Quản trị Kinh doanh (2 giảng viên)
(8, 'GV007', 4),
(9, 'GV008', 4);

-- Insert into students (120 sinh viên, 5 sinh viên mỗi lớp, birthday thay cho extra_info)
INSERT INTO students (user_id, student_code, class_id, birthday) VALUES
-- Lớp CNTT-K62A
(10, 'SV001', 1, '2002-01-01'),
(11, 'SV002', 1, '2002-02-01'),
(12, 'SV003', 1, '2002-03-01'),
(13, 'SV004', 1, '2002-04-01'),
(14, 'SV005', 1, '2002-05-01'),
-- Lớp CNTT-K62B
(15, 'SV006', 2, '2002-06-01'),
(16, 'SV007', 2, '2002-07-01'),
(17, 'SV008', 2, '2002-08-01'),
(18, 'SV009', 2, '2002-09-01'),
(19, 'SV010', 2, '2002-10-01'),
-- Lớp CNTT-K62C
(20, 'SV011', 3, '2002-11-01'),
(21, 'SV012', 3, '2002-12-01'),
(22, 'SV013', 3, '2003-01-01'),
(23, 'SV014', 3, '2003-02-01'),
(24, 'SV015', 3, '2003-03-01'),
-- Lớp KTPM-K62A
(25, 'SV016', 4, '2003-04-01'),
(26, 'SV017', 4, '2003-05-01'),
(27, 'SV018', 4, '2003-06-01'),
(28, 'SV019', 4, '2003-07-01'),
(29, 'SV020', 4, '2003-08-01'),
-- Lớp KTPM-K62B
(30, 'SV021', 5, '2003-09-01'),
(31, 'SV022', 5, '2003-10-01'),
(32, 'SV023', 5, '2003-11-01'),
(33, 'SV024', 5, '2003-12-01'),
(34, 'SV025', 5, '2004-01-01'),
-- Lớp KTPM-K62C
(35, 'SV026', 6, '2004-02-01'),
(36, 'SV027', 6, '2004-03-01'),
(37, 'SV028', 6, '2004-04-01'),
(38, 'SV029', 6, '2004-05-01'),
(39, 'SV030', 6, '2004-06-01'),
-- Lớp HTTT-K62A
(40, 'SV031', 7, '2004-07-01'),
(41, 'SV032', 7, '2004-08-01'),
(42, 'SV033', 7, '2004-09-01'),
(43, 'SV034', 7, '2004-10-01'),
(44, 'SV035', 7, '2004-11-01'),
-- Lớp HTTT-K62B
(45, 'SV036', 8, '2004-12-01'),
(46, 'SV037', 8, '2002-01-01'),
(47, 'SV038', 8, '2002-02-01'),
(48, 'SV039', 8, '2002-03-01'),
(49, 'SV040', 8, '2002-04-01'),
-- Lớp HTTT-K62C
(50, 'SV041', 9, '2002-05-01'),
(51, 'SV042', 9, '2002-06-01'),
(52, 'SV043', 9, '2002-07-01'),
(53, 'SV044', 9, '2002-08-01'),
(54, 'SV045', 9, '2002-09-01'),
-- Lớp ANM-K62A
(55, 'SV046', 10, '2002-10-01'),
(56, 'SV047', 10, '2002-11-01'),
(57, 'SV048', 10, '2002-12-01'),
(58, 'SV049', 10, '2003-01-01'),
(59, 'SV050', 10, '2003-02-01'),
-- Lớp ANM-K62B
(60, 'SV051', 11, '2003-03-01'),
(61, 'SV052', 11, '2003-04-01'),
(62, 'SV053', 11, '2003-05-01'),
(63, 'SV054', 11, '2003-06-01'),
(64, 'SV055', 11, '2003-07-01'),
-- Lớp ANM-K62C
(65, 'SV056', 12, '2003-08-01'),
(66, 'SV057', 12, '2003-09-01'),
(67, 'SV058', 12, '2003-10-01'),
(68, 'SV059', 12, '2003-11-01'),
(69, 'SV060', 12, '2003-12-01'),
-- Lớp KT-K62A
(70, 'SV061', 13, '2004-01-01'),
(71, 'SV062', 13, '2004-02-01'),
(72, 'SV063', 13, '2004-03-01'),
(73, 'SV064', 13, '2004-04-01'),
(74, 'SV065', 13, '2004-05-01'),
-- Lớp KT-K62B
(75, 'SV066', 14, '2004-06-01'),
(76, 'SV067', 14, '2004-07-01'),
(77, 'SV068', 14, '2004-08-01'),
(78, 'SV069', 14, '2004-09-01'),
(79, 'SV070', 14, '2004-10-01'),
-- Lớp KT-K62C
(80, 'SV071', 15, '2004-11-01'),
(81, 'SV072', 15, '2004-12-01'),
(82, 'SV073', 15, '2002-01-01'),
(83, 'SV074', 15, '2002-02-01'),
(84, 'SV075', 15, '2002-03-01'),
-- Lớp KTO-K62A
(85, 'SV076', 16, '2002-04-01'),
(86, 'SV077', 16, '2002-05-01'),
(87, 'SV078', 16, '2002-06-01'),
(88, 'SV079', 16, '2002-07-01'),
(89, 'SV080', 16, '2002-08-01'),
-- Lớp KTO-K62B
(90, 'SV081', 17, '2002-09-01'),
(91, 'SV082', 17, '2002-10-01'),
(92, 'SV083', 17, '2002-11-01'),
(93, 'SV084', 17, '2002-12-01'),
(94, 'SV085', 17, '2003-01-01'),
-- Lớp KTO-K62C
(95, 'SV086', 18, '2003-02-01'),
(96, 'SV087', 18, '2003-03-01'),
(97, 'SV088', 18, '2003-04-01'),
(98, 'SV089', 18, '2003-05-01'),
(99, 'SV090', 18, '2003-06-01'),
-- Lớp QTKD-K62A
(100, 'SV091', 19, '2003-07-01'),
(101, 'SV092', 19, '2003-08-01'),
(102, 'SV093', 19, '2003-09-01'),
(103, 'SV094', 19, '2003-10-01'),
(104, 'SV095', 19, '2003-11-01'),
-- Lớp QTKD-K62B
(105, 'SV096', 20, '2003-12-01'),
(106, 'SV097', 20, '2004-01-01'),
(107, 'SV098', 20, '2004-02-01'),
(108, 'SV099', 20, '2004-03-01'),
(109, 'SV100', 20, '2004-04-01'),
-- Lớp QTKD-K62C
(110, 'SV101', 21, '2004-05-01'),
(111, 'SV102', 21, '2004-06-01'),
(112, 'SV103', 21, '2004-07-01'),
(113, 'SV104', 21, '2004-08-01'),
(114, 'SV105', 21, '2004-09-01'),
-- Lớp MKT-K62A
(115, 'SV106', 22, '2004-10-01'),
(116, 'SV107', 22, '2004-11-01'),
(117, 'SV108', 22, '2004-12-01'),
(118, 'SV109', 22, '2002-01-01'),
(119, 'SV110', 22, '2002-02-01'),
-- Lớp MKT-K62B
(120, 'SV111', 23, '2002-03-01'),
(121, 'SV112', 23, '2002-04-01'),
(122, 'SV113', 23, '2002-05-01'),
(123, 'SV114', 23, '2002-06-01'),
(124, 'SV115', 23, '2002-07-01'),
-- Lớp MKT-K62C
(125, 'SV116', 24, '2002-08-01'),
(126, 'SV117', 24, '2002-09-01'),
(127, 'SV118', 24, '2002-10-01'),
(128, 'SV119', 24, '2002-11-01'),
(129, 'SV120', 24, '2002-12-01');

-- Insert into courses (6 môn học, phân bổ cho 4 bộ môn)
INSERT INTO courses (code, name, credits, department_id) VALUES
('CS101', 'Lập trình Java', 3, 1),
('CS102', 'Cơ sở dữ liệu', 3, 1),
('IS101', 'Hệ thống Thông tin Quản lý', 3, 2),
('AC101', 'Kế toán tài chính', 3, 3),
('AC102', 'Kiểm toán nội bộ', 3, 3),
('BM101', 'Quản trị Marketing', 3, 4);

-- Insert into class_sections (2 lớp học phần mỗi lớp chính khóa, tổng 48 lớp học phần)
INSERT INTO class_sections (course_id, teacher_id, major_id, term, room, capacity, start_date, end_date) VALUES
-- Lớp CNTT-K62A: 2 lớp học phần
(1, 1, 1, 'HK1-2025', 'A101', 30, '2025-09-01', '2025-12-31'),
(2, 2, 1, 'HK1-2025', 'A102', 30, '2025-09-01', '2025-12-31'),
-- Lớp CNTT-K62B: 2 lớp học phần
(1, 1, 1, 'HK1-2025', 'A103', 30, '2025-09-01', '2025-12-31'),
(2, 2, 1, 'HK1-2025', 'A104', 30, '2025-09-01', '2025-12-31'),
-- Lớp CNTT-K62C: 2 lớp học phần
(1, 1, 1, 'HK1-2025', 'A105', 30, '2025-09-01', '2025-12-31'),
(2, 2, 1, 'HK1-2025', 'A106', 30, '2025-09-01', '2025-12-31'),
-- Lớp KTPM-K62A: 2 lớp học phần
(1, 1, 2, 'HK1-2025', 'A107', 30, '2025-09-01', '2025-12-31'),
(2, 2, 2, 'HK1-2025', 'A108', 30, '2025-09-01', '2025-12-31'),
-- Lớp KTPM-K62B: 2 lớp học phần
(1, 1, 2, 'HK1-2025', 'A109', 30, '2025-09-01', '2025-12-31'),
(2, 2, 2, 'HK1-2025', 'A110', 30, '2025-09-01', '2025-12-31'),
-- Lớp KTPM-K62C: 2 lớp học phần
(1, 1, 2, 'HK1-2025', 'A111', 30, '2025-09-01', '2025-12-31'),
(2, 2, 2, 'HK1-2025', 'A112', 30, '2025-09-01', '2025-12-31'),
-- Lớp HTTT-K62A: 2 lớp học phần
(3, 3, 3, 'HK1-2025', 'A113', 30, '2025-09-01', '2025-12-31'),
(3, 4, 3, 'HK1-2025', 'A114', 30, '2025-09-01', '2025-12-31'),
-- Lớp HTTT-K62B: 2 lớp học phần
(3, 3, 3, 'HK1-2025', 'A115', 30, '2025-09-01', '2025-12-31'),
(3, 4, 3, 'HK1-2025', 'A116', 30, '2025-09-01', '2025-12-31'),
-- Lớp HTTT-K62C: 2 lớp học phần
(3, 3, 3, 'HK1-2025', 'A117', 30, '2025-09-01', '2025-12-31'),
(3, 4, 3, 'HK1-2025', 'A118', 30, '2025-09-01', '2025-12-31'),
-- Lớp ANM-K62A: 2 lớp học phần
(3, 3, 4, 'HK1-2025', 'A119', 30, '2025-09-01', '2025-12-31'),
(3, 4, 4, 'HK1-2025', 'A120', 30, '2025-09-01', '2025-12-31'),
-- Lớp ANM-K62B: 2 lớp học phần
(3, 3, 4, 'HK1-2025', 'A121', 30, '2025-09-01', '2025-12-31'),
(3, 4, 4, 'HK1-2025', 'A122', 30, '2025-09-01', '2025-12-31'),
-- Lớp ANM-K62C: 2 lớp học phần
(3, 3, 4, 'HK1-2025', 'A123', 30, '2025-09-01', '2025-12-31'),
(3, 4, 4, 'HK1-2025', 'A124', 30, '2025-09-01', '2025-12-31'),
-- Lớp KT-K62A: 2 lớp học phần
(4, 5, 5, 'HK1-2025', 'B101', 30, '2025-09-01', '2025-12-31'),
(5, 6, 5, 'HK1-2025', 'B102', 30, '2025-09-01', '2025-12-31'),
-- Lớp KT-K62B: 2 lớp học phần
(4, 5, 5, 'HK1-2025', 'B103', 30, '2025-09-01', '2025-12-31'),
(5, 6, 5, 'HK1-2025', 'B104', 30, '2025-09-01', '2025-12-31'),
-- Lớp KT-K62C: 2 lớp học phần
(4, 5, 5, 'HK1-2025', 'B105', 30, '2025-09-01', '2025-12-31'),
(5, 6, 5, 'HK1-2025', 'B106', 30, '2025-09-01', '2025-12-31'),
-- Lớp KTO-K62A: 2 lớp học phần
(4, 5, 6, 'HK1-2025', 'B107', 30, '2025-09-01', '2025-12-31'),
(5, 6, 6, 'HK1-2025', 'B108', 30, '2025-09-01', '2025-12-31'),
-- Lớp KTO-K62B: 2 lớp học phần
(4, 5, 6, 'HK1-2025', 'B109', 30, '2025-09-01', '2025-12-31'),
(5, 6, 6, 'HK1-2025', 'B110', 30, '2025-09-01', '2025-12-31'),
-- Lớp KTO-K62C: 2 lớp học phần
(4, 5, 6, 'HK1-2025', 'B111', 30, '2025-09-01', '2025-12-31'),
(5, 6, 6, 'HK1-2025', 'B112', 30, '2025-09-01', '2025-12-31'),
-- Lớp QTKD-K62A: 2 lớp học phần
(6, 7, 7, 'HK1-2025', 'B113', 30, '2025-09-01', '2025-12-31'),
(6, 8, 7, 'HK1-2025', 'B114', 30, '2025-09-01', '2025-12-31'),
-- Lớp QTKD-K62B: 2 lớp học phần
(6, 7, 7, 'HK1-2025', 'B115', 30, '2025-09-01', '2025-12-31'),
(6, 8, 7, 'HK1-2025', 'B116', 30, '2025-09-01', '2025-12-31'),
-- Lớp QTKD-K62C: 2 lớp học phần
(6, 7, 7, 'HK1-2025', 'B117', 30, '2025-09-01', '2025-12-31'),
(6, 8, 7, 'HK1-2025', 'B118', 30, '2025-09-01', '2025-12-31'),
-- Lớp MKT-K62A: 2 lớp học phần
(6, 7, 8, 'HK1-2025', 'B119', 30, '2025-09-01', '2025-12-31'),
(6, 8, 8, 'HK1-2025', 'B120', 30, '2025-09-01', '2025-12-31'),
-- Lớp MKT-K62B: 2 lớp học phần
(6, 7, 8, 'HK1-2025', 'B121', 30, '2025-09-01', '2025-12-31'),
(6, 8, 8, 'HK1-2025', 'B122', 30, '2025-09-01', '2025-12-31'),
-- Lớp MKT-K62C: 2 lớp học phần
(6, 7, 8, 'HK1-2025', 'B123', 30, '2025-09-01', '2025-12-31'),
(6, 8, 8, 'HK1-2025', 'B124', 30, '2025-09-01', '2025-12-31');

-- Insert into class_section_classes (Gán lớp chính khóa vào lớp học phần)
INSERT INTO class_section_classes (class_section_id, class_id) VALUES
-- Gán lớp CNTT-K62A vào 2 lớp học phần
(1, 1), (2, 1),
-- Gán lớp CNTT-K62B vào 2 lớp học phần
(3, 2), (4, 2),
-- Gán lớp CNTT-K62C vào 2 lớp học phần
(5, 3), (6, 3),
-- Gán lớp KTPM-K62A vào 2 lớp học phần
(7, 4), (8, 4),
-- Gán lớp KTPM-K62B vào 2 lớp học phần
(9, 5), (10, 5),
-- Gán lớp KTPM-K62C vào 2 lớp học phần
(11, 6), (12, 6),
-- Gán lớp HTTT-K62A vào 2 lớp học phần
(13, 7), (14, 7),
-- Gán lớp HTTT-K62B vào 2 lớp học phần
(15, 8), (16, 8),
-- Gán lớp HTTT-K62C vào 2 lớp học phần
(17, 9), (18, 9),
-- Gán lớp ANM-K62A vào 2 lớp học phần
(19, 10), (20, 10),
-- Gán lớp ANM-K62B vào 2 lớp học phần
(21, 11), (22, 11),
-- Gán lớp ANM-K62C vào 2 lớp học phần
(23, 12), (24, 12),
-- Gán lớp KT-K62A vào 2 lớp học phần
(25, 13), (26, 13),
-- Gán lớp KT-K62B vào 2 lớp học phần
(27, 14), (28, 14),
-- Gán lớp KT-K62C vào 2 lớp học phần
(29, 15), (30, 15),
-- Gán lớp KTO-K62A vào 2 lớp học phần
(31, 16), (32, 16),
-- Gán lớp KTO-K62B vào 2 lớp học phần
(33, 17), (34, 17),
-- Gán lớp KTO-K62C vào 2 lớp học phần
(35, 18), (36, 18),
-- Gán lớp QTKD-K62A vào 2 lớp học phần
(37, 19), (38, 19),
-- Gán lớp QTKD-K62B vào 2 lớp học phần
(39, 20), (40, 20),
-- Gán lớp QTKD-K62C vào 2 lớp học phần
(41, 21), (42, 21),
-- Gán lớp MKT-K62A vào 2 lớp học phần
(43, 22), (44, 22),
-- Gán lớp MKT-K62B vào 2 lớp học phần
(45, 23), (46, 23),
-- Gán lớp MKT-K62C vào 2 lớp học phần
(47, 24), (48, 24);

-- Insert into class_section_students (Gán sinh viên vào lớp học phần theo lớp chính khóa)
INSERT INTO class_section_students (class_section_id, student_id) VALUES
-- Lớp CNTT-K62A (SV001-SV005) vào 2 lớp học phần
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
(2, 1), (2, 2), (2, 3), (2, 4), (2, 5),
-- Lớp CNTT-K62B (SV006-SV010) vào 2 lớp học phần
(3, 6), (3, 7), (3, 8), (3, 9), (3, 10),
(4, 6), (4, 7), (4, 8), (4, 9), (4, 10),
-- Lớp CNTT-K62C (SV011-SV015) vào 2 lớp học phần
(5, 11), (5, 12), (5, 13), (5, 14), (5, 15),
(6, 11), (6, 12), (6, 13), (6, 14), (6, 15),
-- Lớp KTPM-K62A (SV016-SV020) vào 2 lớp học phần
(7, 16), (7, 17), (7, 18), (7, 19), (7, 20),
(8, 16), (8, 17), (8, 18), (8, 19), (8, 20),
-- Lớp KTPM-K62B (SV021-SV025) vào 2 lớp học phần
(9, 21), (9, 22), (9, 23), (9, 24), (9, 25),
(10, 21), (10, 22), (10, 23), (10, 24), (10, 25),
-- Lớp KTPM-K62C (SV026-SV030) vào 2 lớp học phần
(11, 26), (11, 27), (11, 28), (11, 29), (11, 30),
(12, 26), (12, 27), (12, 28), (12, 29), (12, 30),
-- Lớp HTTT-K62A (SV031-SV035) vào 2 lớp học phần
(13, 31), (13, 32), (13, 33), (13, 34), (13, 35),
(14, 31), (14, 32), (14, 33), (14, 34), (14, 35),
-- Lớp HTTT-K62B (SV036-SV040) vào 2 lớp học phần
(15, 36), (15, 37), (15, 38), (15, 39), (15, 40),
(16, 36), (16, 37), (16, 38), (16, 39), (16, 40),
-- Lớp HTTT-K62C (SV041-SV045) vào 2 lớp học phần
(17, 41), (17, 42), (17, 43), (17, 44), (17, 45),
(18, 41), (18, 42), (18, 43), (18, 44), (18, 45),
-- Lớp ANM-K62A (SV046-SV050) vào 2 lớp học phần
(19, 46), (19, 47), (19, 48), (19, 49), (19, 50),
(20, 46), (20, 47), (20, 48), (20, 49), (20, 50),
-- Lớp ANM-K62B (SV051-SV055) vào 2 lớp học phần
(21, 51), (21, 52), (21, 53), (21, 54), (21, 55),
(22, 51), (22, 52), (22, 53), (22, 54), (22, 55),
-- Lớp ANM-K62C (SV056-SV060) vào 2 lớp học phần
(23, 56), (23, 57), (23, 58), (23, 59), (23, 60),
(24, 56), (24, 57), (24, 58), (24, 59), (24, 60),
-- Lớp KT-K62A (SV061-SV065) vào 2 lớp học phần
(25, 61), (25, 62), (25, 63), (25, 64), (25, 65),
(26, 61), (26, 62), (26, 63), (26, 64), (26, 65),
-- Lớp KT-K62B (SV066-SV070) vào 2 lớp học phần
(27, 66), (27, 67), (27, 68), (27, 69), (27, 70),
(28, 66), (28, 67), (28, 68), (28, 69), (28, 70),
-- Lớp KT-K62C (SV071-SV075) vào 2 lớp học phần
(29, 71), (29, 72), (29, 73), (29, 74), (29, 75),
(30, 71), (30, 72), (30, 73), (30, 74), (30, 75),
-- Lớp KTO-K62A (SV076-SV080) vào 2 lớp học phần
(31, 76), (31, 77), (31, 78), (31, 79), (31, 80),
(32, 76), (32, 77), (32, 78), (32, 79), (32, 80),
-- Lớp KTO-K62B (SV081-SV085) vào 2 lớp học phần
(33, 81), (33, 82), (33, 83), (33, 84), (33, 85),
(34, 81), (34, 82), (34, 83), (34, 84), (34, 85),
-- Lớp KTO-K62C (SV086-SV090) vào 2 lớp học phần
(35, 86), (35, 87), (35, 88), (35, 89), (35, 90),
(36, 86), (36, 87), (36, 88), (36, 89), (36, 90),
-- Lớp QTKD-K62A (SV091-SV095) vào 2 lớp học phần
(37, 91), (37, 92), (37, 93), (37, 94), (37, 95),
(38, 91), (38, 92), (38, 93), (38, 94), (38, 95),
-- Lớp QTKD-K62B (SV096-SV100) vào 2 lớp học phần
(39, 96), (39, 97), (39, 98), (39, 99), (39, 100),
(40, 96), (40, 97), (40, 98), (40, 99), (40, 100),
-- Lớp QTKD-K62C (SV101-SV105) vào 2 lớp học phần
(41, 101), (41, 102), (41, 103), (41, 104), (41, 105),
(42, 101), (42, 102), (42, 103), (42, 104), (42, 105),
-- Lớp MKT-K62A (SV106-SV110) vào 2 lớp học phần
(43, 106), (43, 107), (43, 108), (43, 109), (43, 110),
(44, 106), (44, 107), (44, 108), (44, 109), (44, 110),
-- Lớp MKT-K62B (SV111-SV115) vào 2 lớp học phần
(45, 111), (45, 112), (45, 113), (45, 114), (45, 115),
(46, 111), (46, 112), (46, 113), (46, 114), (46, 115),
-- Lớp MKT-K62C (SV116-SV120) vào 2 lớp học phần
(47, 116), (47, 117), (47, 118), (47, 119), (47, 120),
(48, 116), (48, 117), (48, 118), (48, 119), (48, 120);

-- Insert into schedules (96 bản ghi: 48 lớp học phần, mỗi lớp 2 buổi/tuần)
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag, location_lat, location_lng) VALUES
-- Lớp học phần 1 (Lớp CNTT-K62A, Lập trình Java): Thứ Hai, Thứ Tư
(1, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(1, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 2 (Lớp CNTT-K62A, Cơ sở dữ liệu): Thứ Ba, Thứ Năm
(2, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(2, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 3 (Lớp CNTT-K62B, Lập trình Java): Thứ Hai, Thứ Tư
(3, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(3, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 4 (Lớp CNTT-K62B, Cơ sở dữ liệu): Thứ Ba, Thứ Năm
(4, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(4, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 5 (Lớp CNTT-K62C, Lập trình Java): Thứ Hai, Thứ Tư
(5, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(5, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 6 (Lớp CNTT-K62C, Cơ sở dữ liệu): Thứ Ba, Thứ Năm
(6, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(6, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 7 (Lớp KTPM-K62A, Lập trình Java): Thứ Hai, Thứ Tư
(7, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(7, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 8 (Lớp KTPM-K62A, Cơ sở dữ liệu): Thứ Ba, Thứ Năm
(8, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(8, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 9 (Lớp KTPM-K62B, Lập trình Java): Thứ Hai, Thứ Tư
(9, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(9, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 10 (Lớp KTPM-K62B, Cơ sở dữ liệu): Thứ Ba, Thứ Năm
(10, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(10, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 11 (Lớp KTPM-K62C, Lập trình Java): Thứ Hai, Thứ Tư
(11, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(11, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 12 (Lớp KTPM-K62C, Cơ sở dữ liệu): Thứ Ba, Thứ Năm
(12, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(12, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 13 (Lớp HTTT-K62A, Hệ thống Thông tin Quản lý): Thứ Hai, Thứ Tư
(13, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(13, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 14 (Lớp HTTT-K62A, Hệ thống Thông tin Quản lý): Thứ Ba, Thứ Năm
(14, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(14, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 15 (Lớp HTTT-K62B, Hệ thống Thông tin Quản lý): Thứ Hai, Thứ Tư
(15, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(15, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 16 (Lớp HTTT-K62B, Hệ thống Thông tin Quản lý): Thứ Ba, Thứ Năm
(16, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(16, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 17 (Lớp HTTT-K62C, Hệ thống Thông tin Quản lý): Thứ Hai, Thứ Tư
(17, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(17, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 18 (Lớp HTTT-K62C, Hệ thống Thông tin Quản lý): Thứ Ba, Thứ Năm
(18, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(18, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 19 (Lớp ANM-K62A, Hệ thống Thông tin Quản lý): Thứ Hai, Thứ Tư
(19, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(19, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 20 (Lớp ANM-K62A, Hệ thống Thông tin Quản lý): Thứ Ba, Thứ Năm
(20, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(20, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 21 (Lớp ANM-K62B, Hệ thống Thông tin Quản lý): Thứ Hai, Thứ Tư
(21, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(21, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 22 (Lớp ANM-K62B, Hệ thống Thông tin Quản lý): Thứ Ba, Thứ Năm
(22, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(22, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 23 (Lớp ANM-K62C, Hệ thống Thông tin Quản lý): Thứ Hai, Thứ Tư
(23, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(23, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 24 (Lớp ANM-K62C, Hệ thống Thông tin Quản lý): Thứ Ba, Thứ Năm
(24, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(24, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 25 (Lớp KT-K62A, Kế toán tài chính): Thứ Hai, Thứ Tư
(25, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(25, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 26 (Lớp KT-K62A, Kiểm toán nội bộ): Thứ Ba, Thứ Năm
(26, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(26, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 27 (Lớp KT-K62B, Kế toán tài chính): Thứ Hai, Thứ Tư
(27, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(27, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 28 (Lớp KT-K62B, Kiểm toán nội bộ): Thứ Ba, Thứ Năm
(28, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(28, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 29 (Lớp KT-K62C, Kế toán tài chính): Thứ Hai, Thứ Tư
(29, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(29, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 30 (Lớp KT-K62C, Kiểm toán nội bộ): Thứ Ba, Thứ Năm
(30, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(30, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 31 (Lớp KTO-K62A, Kế toán tài chính): Thứ Hai, Thứ Tư
(31, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(31, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 32 (Lớp KTO-K62A, Kiểm toán nội bộ): Thứ Ba, Thứ Năm
(32, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(32, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 33 (Lớp KTO-K62B, Kế toán tài chính): Thứ Hai, Thứ Tư
(33, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(33, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 34 (Lớp KTO-K62B, Kiểm toán nội bộ): Thứ Ba, Thứ Năm
(34, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(34, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 35 (Lớp KTO-K62C, Kế toán tài chính): Thứ Hai, Thứ Tư
(35, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(35, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 36 (Lớp KTO-K62C, Kiểm toán nội bộ): Thứ Ba, Thứ Năm
(36, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(36, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 37 (Lớp QTKD-K62A, Quản trị Marketing): Thứ Hai, Thứ Tư
(37, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(37, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 38 (Lớp QTKD-K62A, Quản trị Marketing): Thứ Ba, Thứ Năm
(38, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(38, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 39 (Lớp QTKD-K62B, Quản trị Marketing): Thứ Hai, Thứ Tư
(39, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(39, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 40 (Lớp QTKD-K62B, Quản trị Marketing): Thứ Ba, Thứ Năm
(40, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(40, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 41 (Lớp QTKD-K62C, Quản trị Marketing): Thứ Hai, Thứ Tư
(41, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(41, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 42 (Lớp QTKD-K62C, Quản trị Marketing): Thứ Ba, Thứ Năm
(42, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(42, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 43 (Lớp MKT-K62A, Quản trị Marketing): Thứ Hai, Thứ Tư
(43, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(43, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 44 (Lớp MKT-K62A, Quản trị Marketing): Thứ Ba, Thứ Năm
(44, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(44, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 45 (Lớp MKT-K62B, Quản trị Marketing): Thứ Hai, Thứ Tư
(45, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(45, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 46 (Lớp MKT-K62B, Quản trị Marketing): Thứ Ba, Thứ Năm
(46, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(46, 3, '14:00:00', '16:00:00', 1, NULL, NULL),
-- Lớp học phần 47 (Lớp MKT-K62C, Quản trị Marketing): Thứ Hai, Thứ Tư
(47, 0, '08:00:00', '10:00:00', 1, NULL, NULL),
(47, 2, '08:00:00', '10:00:00', 1, NULL, NULL),
-- Lớp học phần 48 (Lớp MKT-K62C, Quản trị Marketing): Thứ Ba, Thứ Năm
(48, 1, '14:00:00', '16:00:00', 1, NULL, NULL),
(48, 3, '14:00:00', '16:00:00', 1, NULL, NULL);
