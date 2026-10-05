USE lapitcare;

-- 1. LOGIN: fetch the account, then verify with password_verify() in PHP
SELECT user_id, role, full_name, password_hash, status FROM users WHERE email = 'juan@email.com';

-- 2. PATIENT: verified clinics with their services (clinic list + map markers)
SELECT c.clinic_id, c.name, c.specialty, c.address, c.latitude, c.longitude, c.phone, c.email,
       c.operating_hours, c.status, c.alert_message, c.queue_count, c.avg_wait_min,
       GROUP_CONCAT(s.name SEPARATOR ', ') AS services
FROM clinics c LEFT JOIN clinic_services s ON s.clinic_id = c.clinic_id AND s.kind = 'service'
WHERE c.registration = 'verified'
GROUP BY c.clinic_id;

-- 3. PATIENT: emergency banner
SELECT name, alert_message FROM clinics WHERE registration = 'verified' AND status = 'emergency' AND alert_message IS NOT NULL;

-- 4. PATIENT: free slots for a clinic on a date (not blocked, doctor available, no live appointment)
SELECT sl.slot_id, TIME_FORMAT(sl.slot_time, '%l:%i %p') AS time_label
FROM slots sl
JOIN doctors d ON d.doctor_id = sl.doctor_id
LEFT JOIN appointments a ON a.slot_id = sl.slot_id AND a.status NOT IN ('cancelled','rejected')
WHERE d.clinic_id = 1 AND sl.slot_date = CURDATE()
  AND d.availability = 'available' AND sl.is_blocked = 0 AND a.appt_id IS NULL
ORDER BY sl.slot_time;

-- 5. PATIENT: book an appointment (the UNIQUE active_slot_id rejects double-booking)
INSERT INTO appointments (patient_id, clinic_id, slot_id, service_id, reason, notes)
VALUES (2, 1, 5, 2, 'Consultation', 'Cough and fever');

-- 6. PATIENT: my appointments with a status filter (tabs: All / Pending / Approved / Completed / Cancelled)
SELECT a.appt_id, c.name AS clinic, sv.name AS service, sl.slot_date, sl.slot_time, a.status, a.notes
FROM appointments a
JOIN clinics c ON c.clinic_id = a.clinic_id
JOIN slots sl ON sl.slot_id = a.slot_id
LEFT JOIN clinic_services sv ON sv.service_id = a.service_id
WHERE a.patient_id = 2 AND a.status = 'pending'
ORDER BY sl.slot_date, sl.slot_time;

-- 7. PATIENT: cancel (frees the slot automatically)
UPDATE appointments SET status = 'cancelled' WHERE appt_id = 3 AND patient_id = 2 AND status IN ('pending','approved');

-- 8. PATIENT: feedback only for COMPLETED appointments (BR-019)
INSERT INTO feedback (appt_id, category, rating, comment)
SELECT appt_id, 'Waiting Time', 4, 'Short wait.' FROM appointments
WHERE appt_id = 5 AND patient_id = 2 AND status = 'completed';

-- 9. STAFF: today's appointments for my clinic (clinic data isolation, NFR-017)
SELECT a.appt_id, CONCAT('APT-', LPAD(a.appt_id, 4, '0')) AS code, u.full_name AS patient,
       TIMESTAMPDIFF(YEAR, u.birthdate, CURDATE()) AS age, a.reason, sl.slot_time, a.status
FROM appointments a
JOIN users u ON u.user_id = a.patient_id
JOIN slots sl ON sl.slot_id = a.slot_id
WHERE a.clinic_id = (SELECT clinic_id FROM clinic_staff WHERE user_id = 6) AND sl.slot_date = CURDATE()
ORDER BY sl.slot_time;

-- 10. STAFF: approve / reject / mark done
UPDATE appointments SET status = 'approved'  WHERE appt_id = 3 AND clinic_id = 1;
UPDATE appointments SET status = 'rejected'  WHERE appt_id = 4 AND clinic_id = 1;
UPDATE appointments SET status = 'completed' WHERE appt_id = 2 AND clinic_id = 1;

-- 11. STAFF: doctor availability, queue, clinic status, block a slot
UPDATE doctors SET availability = 'on_leave' WHERE doctor_id = 1;
UPDATE clinics SET queue_count = queue_count + 1 WHERE clinic_id = 1;
UPDATE clinics SET status = 'emergency', alert_message = 'High patient volume – expect extended wait times.' WHERE clinic_id = 1;
UPDATE slots SET is_blocked = 1 WHERE slot_id = 8;

-- 12. STAFF: feedback for my clinic
SELECT f.category, f.rating, f.comment, f.created_at FROM feedback f
JOIN appointments a ON a.appt_id = f.appt_id WHERE a.clinic_id = 1 ORDER BY f.created_at DESC;

-- 13. ADMIN: overview cards
SELECT (SELECT COUNT(*) FROM clinics) AS registered_clinics,
       (SELECT COUNT(*) FROM clinics WHERE registration = 'verified') AS verified,
       (SELECT COUNT(*) FROM clinics WHERE registration = 'pending') AS pending,
       (SELECT COUNT(*) FROM appointments) AS total_appointments,
       (SELECT COUNT(*) FROM users WHERE role <> 'admin') AS registered_users,
       (SELECT COUNT(*) FROM users WHERE role = 'patient') AS patients;

-- 14. ADMIN: registered clinics with staff + appointment counts; verify / suspend / reinstate
SELECT c.clinic_code, c.name, c.specialty, c.owner_name, c.registration,
       (SELECT COUNT(*) FROM clinic_staff s WHERE s.clinic_id = c.clinic_id) AS staff,
       (SELECT COUNT(*) FROM appointments a WHERE a.clinic_id = c.clinic_id) AS appointments
FROM clinics c ORDER BY c.clinic_id;
UPDATE clinics SET registration = 'verified'  WHERE clinic_id = 4;
UPDATE clinics SET registration = 'suspended' WHERE clinic_id = 5;

-- 15. ADMIN: users + deactivate / reactivate
SELECT full_name, email, role, status, DATE_FORMAT(created_at, '%b %e, %Y') AS joined FROM users WHERE role <> 'admin';
UPDATE users SET status = 'inactive' WHERE user_id = 2;

-- 16. ADMIN: reports
SELECT DATE_FORMAT(sl.slot_date, '%Y-%m') AS month, COUNT(*) AS total
FROM appointments a JOIN slots sl ON sl.slot_id = a.slot_id GROUP BY month ORDER BY month;          -- over time
SELECT status, COUNT(*) AS total FROM appointments GROUP BY status;                                   -- status pie
SELECT sv.name, COUNT(*) AS total FROM appointments a JOIN clinic_services sv ON sv.service_id = a.service_id
GROUP BY sv.name ORDER BY total DESC LIMIT 5;                                                         -- top services
SELECT c.name, COUNT(*) AS total FROM appointments a JOIN clinics c ON c.clinic_id = a.clinic_id
GROUP BY c.clinic_id ORDER BY total DESC;                                                             -- by facility

-- 17. NOTIFICATIONS: unread badge + mark all read
SELECT COUNT(*) FROM notifications WHERE user_id = 2 AND is_read = 0;
UPDATE notifications SET is_read = 1 WHERE user_id = 2;

-- 18. AUDIT LOG (NFR-018)
INSERT INTO activity_logs (user_id, action) VALUES (6, 'Approved appointment APT-0003');
