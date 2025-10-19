-- GV mục tiêu
SET @T_LIST := 'T001,T002,T003';

DROP TEMPORARY TABLE IF EXISTS temp_teacher_cs;
CREATE TEMPORARY TABLE temp_teacher_cs (
  teacher_id BIGINT UNSIGNED,
  class_section_id BIGINT UNSIGNED,
  rn INT
);

-- reset biến
SET @rn := 0; 
SET @prev_t := 0;

-- ⚠️ Chỉ lấy 3 cột ra INSERT (đã bỏ cột dư)
INSERT INTO temp_teacher_cs (teacher_id, class_section_id, rn)
SELECT teacher_id, class_section_id, rn FROM (
  SELECT 
    t.id AS teacher_id,
    cs.id AS class_section_id,
    (@rn := IF(@prev_t = t.id, @rn + 1, 1)) AS rn,
    (@prev_t := t.id) AS _keep_internal
  FROM teachers t
  JOIN class_sections cs ON cs.teacher_id = t.id
  WHERE FIND_IN_SET(t.teacher_code, @T_LIST) > 0
  ORDER BY t.id, cs.id
) z;

-- chỉ giữ tối đa 3 slot/lớp/GV
DELETE FROM temp_teacher_cs WHERE rn > 3;

-- kiểm tra
SELECT * FROM temp_teacher_cs;

DROP TEMPORARY TABLE IF EXISTS tmp_weekdays;
CREATE TEMPORARY TABLE tmp_weekdays (wd TINYINT UNSIGNED);
INSERT INTO tmp_weekdays VALUES (0),(1),(2),(3),(4),(5); -- Thứ 2..Thứ 7

DROP TEMPORARY TABLE IF EXISTS tmp_slots;
CREATE TEMPORARY TABLE tmp_slots (slot_no TINYINT, st TIME, en TIME);
INSERT INTO tmp_slots VALUES
(1,'07:30:00','09:00:00'),
(2,'09:15:00','10:45:00'),
(3,'13:30:00','15:00:00');

INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT c.class_section_id, w.wd, s.st, s.en, 1
FROM temp_teacher_cs c
JOIN tmp_slots s  ON s.slot_no = c.rn
JOIN tmp_weekdays w
WHERE NOT EXISTS (
  SELECT 1 FROM schedules x
  WHERE x.class_section_id = c.class_section_id
    AND x.recurring_flag = 1
    AND x.weekday = w.wd
    AND x.start_time = s.st
    AND x.end_time   = s.en
);























-- T001 (CSE100) — Thứ 2 & Thứ 6: 07:55–09:40
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 0, '07:55:00', '09:40:00', 1
FROM class_sections cs
JOIN courses  c ON c.id=cs.course_id
JOIN teachers t ON t.id=cs.teacher_id
WHERE c.code='CSE100' AND t.teacher_code='T001'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id=cs.id AND s.recurring_flag=1
    AND s.weekday=0 AND s.start_time='07:55:00' AND s.end_time='09:40:00'
);

INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 0, '09:45:00', '11:30:00', 1
FROM class_sections cs
JOIN courses  c ON c.id=cs.course_id
JOIN teachers t ON t.id=cs.teacher_id
WHERE c.code='CSE400' AND t.teacher_code='T001'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id=cs.id AND s.recurring_flag=1
    AND s.weekday=0 AND s.start_time='09:45:00' AND s.end_time='11:30:00'
);

INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 4, '07:55:00', '09:40:00', 1
FROM class_sections cs
JOIN courses  c ON c.id=cs.course_id
JOIN teachers t ON t.id=cs.teacher_id
WHERE c.code='CSE100' AND t.teacher_code='T001'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id=cs.id AND s.recurring_flag=1
    AND s.weekday=4 AND s.start_time='07:55:00' AND s.end_time='09:40:00'
);

-- T002 (CSE200) — Thứ 3 & Thứ 5: 09:45–11:30
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 1, '09:45:00', '11:30:00', 1
FROM class_sections cs
JOIN courses  c ON c.id=cs.course_id
JOIN teachers t ON t.id=cs.teacher_id
WHERE c.code='CSE200' AND t.teacher_code='T002'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id=cs.id AND s.recurring_flag=1
    AND s.weekday=1 AND s.start_time='09:45:00' AND s.end_time='11:30:00'
);

INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 3, '09:45:00', '11:30:00', 1
FROM class_sections cs
JOIN courses  c ON c.id=cs.course_id
JOIN teachers t ON t.id=cs.teacher_id
WHERE c.code='CSE200' AND t.teacher_code='T002'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id=cs.id AND s.recurring_flag=1
    AND s.weekday=3 AND s.start_time='09:45:00' AND s.end_time='11:30:00'
);

-- T003 (CSE300) — Thứ 4: 13:30–15:30, Thứ 7: 12:55–15:30
INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 2, '13:30:00', '15:30:00', 1
FROM class_sections cs
JOIN courses  c ON c.id=cs.course_id
JOIN teachers t ON t.id=cs.teacher_id
WHERE c.code='CSE300' AND t.teacher_code='T003'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id=cs.id AND s.recurring_flag=1
    AND s.weekday=2 AND s.start_time='13:30:00' AND s.end_time='15:30:00'
);

INSERT INTO schedules (class_section_id, weekday, start_time, end_time, recurring_flag)
SELECT cs.id, 5, '12:55:00', '15:30:00', 1
FROM class_sections cs
JOIN courses  c ON c.id=cs.course_id
JOIN teachers t ON t.id=cs.teacher_id
WHERE c.code='CSE300' AND t.teacher_code='T003'
AND NOT EXISTS (
  SELECT 1 FROM schedules s
  WHERE s.class_section_id=cs.id AND s.recurring_flag=1
    AND s.weekday=5 AND s.start_time='12:55:00' AND s.end_time='15:30:00'
);
