-- GV mục tiêu
SET @T_LIST := 'T001,T002,T003';
DROP TEMPORARY TABLE IF EXISTS temp_teacher_cs;
CREATE TEMPORARY TABLE temp_teacher_cs (
  teacher_id BIGINT UNSIGNED,
  class_section_id BIGINT UNSIGNED,
  rn INT
);

-- reset biến user-defined
SET @rn := 0; 
SET @prev_t := 0;

-- Lấy class_sections theo từng GV, đánh số rn=1..n (không dùng window)
INSERT INTO temp_teacher_cs (teacher_id, class_section_id, rn)
SELECT t.id AS teacher_id,
       cs.id AS class_section_id,
       (@rn := IF(@prev_t = t.id, @rn + 1, 1)) AS rn,
       (@prev_t := t.id) AS _dummy
FROM teachers t
JOIN class_sections cs ON cs.teacher_id = t.id
WHERE FIND_IN_SET(t.teacher_code, @T_LIST) > 0
ORDER BY t.id, cs.id;

-- Chỉ giữ tối đa 3 lớp/giảng viên (rn <= 3)
DELETE FROM temp_teacher_cs WHERE rn > 3;

SELECT * FROM temp_teacher_cs;  -- kiểm tra
-- 0=Thứ 2 .. 6=CN; ta dùng 0..5 (Thứ 2..Thứ 7)
DROP TEMPORARY TABLE IF EXISTS tmp_weekdays;
CREATE TEMPORARY TABLE tmp_weekdays (wd TINYINT UNSIGNED);
INSERT INTO tmp_weekdays VALUES (0),(1),(2),(3),(4),(5);

-- 3 slot/ngày
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
