-- LapitCARE database (MySQL 5.7+ / MariaDB 10.3+, works in XAMPP phpMyAdmin)
-- Import: phpMyAdmin > Import > choose this file
DROP DATABASE IF EXISTS lapitcare;
CREATE DATABASE lapitcare CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lapitcare;

-- ========== TABLES ==========
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  role ENUM('patient','staff','admin') NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,          -- use PHP password_hash(), never plain text
  phone VARCHAR(20), birthdate DATE,
  sex ENUM('male','female'), barangay VARCHAR(60), address VARCHAR(150),
  status ENUM('active','inactive','pending') NOT NULL DEFAULT 'active',
  consent_at DATETIME NULL,                     -- Data Privacy Act consent (BR-026)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clinics (
  clinic_id INT AUTO_INCREMENT PRIMARY KEY,
  clinic_code VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(120) NOT NULL, specialty VARCHAR(80), owner_name VARCHAR(100),
  address VARCHAR(150), latitude DECIMAL(9,6), longitude DECIMAL(9,6),
  phone VARCHAR(20), email VARCHAR(100), operating_hours VARCHAR(80),
  status ENUM('open','limited','closed','emergency') NOT NULL DEFAULT 'open',
  alert_message VARCHAR(255), queue_count INT NOT NULL DEFAULT 0, avg_wait_min INT NOT NULL DEFAULT 0,
  registration ENUM('pending','verified','suspended') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clinic_staff (
  staff_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL UNIQUE, clinic_id INT NOT NULL,
  license_no VARCHAR(50), access_code VARCHAR(30),
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
);

CREATE TABLE clinic_services (
  service_id INT AUTO_INCREMENT PRIMARY KEY,
  clinic_id INT NOT NULL, name VARCHAR(80) NOT NULL,
  kind ENUM('specialty','service') NOT NULL DEFAULT 'service',
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id) ON DELETE CASCADE
);

CREATE TABLE doctors (
  doctor_id INT AUTO_INCREMENT PRIMARY KEY,
  clinic_id INT NOT NULL, name VARCHAR(100) NOT NULL, title VARCHAR(60),
  availability ENUM('available','on_leave','unavailable') NOT NULL DEFAULT 'available',
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id) ON DELETE CASCADE
);

CREATE TABLE slots (
  slot_id INT AUTO_INCREMENT PRIMARY KEY,
  doctor_id INT NOT NULL, slot_date DATE NOT NULL, slot_time TIME NOT NULL,
  is_blocked TINYINT(1) NOT NULL DEFAULT 0,     -- staff can block a slot
  UNIQUE KEY uq_slot (doctor_id, slot_date, slot_time),
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
);

CREATE TABLE appointments (
  appt_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL, clinic_id INT NOT NULL, slot_id INT NOT NULL, service_id INT NULL,
  reason VARCHAR(150), notes VARCHAR(255),
  status ENUM('pending','approved','completed','cancelled','rejected','no_show') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- Double-booking prevention (BR-003): only ONE live appointment per slot.
  -- Cancelled/rejected rows set this to NULL, so the slot becomes free again (BR-027).
  active_slot_id INT GENERATED ALWAYS AS (IF(status IN ('cancelled','rejected'), NULL, slot_id)) STORED,
  UNIQUE KEY uq_active_slot (active_slot_id),
  FOREIGN KEY (patient_id) REFERENCES users(user_id),
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id),
  FOREIGN KEY (slot_id) REFERENCES slots(slot_id),
  FOREIGN KEY (service_id) REFERENCES clinic_services(service_id)
);

CREATE TABLE notifications (
  notif_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  type ENUM('appointment','resource','emergency','system') NOT NULL,
  title VARCHAR(100) NOT NULL, message VARCHAR(255) NOT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE feedback (
  feedback_id INT AUTO_INCREMENT PRIMARY KEY,
  appt_id INT NOT NULL UNIQUE,                  -- one feedback per completed appointment (BR-019)
  category ENUM('Service Quality','Cleanliness','Staff Attitude','Waiting Time') NOT NULL,
  rating TINYINT NOT NULL, comment TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (rating BETWEEN 1 AND 5),
  FOREIGN KEY (appt_id) REFERENCES appointments(appt_id)
);

CREATE TABLE activity_logs (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT, action VARCHAR(150) NOT NULL, logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- ========== SAMPLE DATA (all demo passwords = "password") ==========
SET @pw = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';
INSERT INTO users (role, full_name, email, password_hash, phone, birthdate, sex, barangay, address, status, consent_at, created_at) VALUES
('admin','Administrator','admin@lapitcare.gov.ph',@pw,'09200001111','1980-01-01','male','Poblacion','Pagadian City','active',NOW(),'2025-06-01'),
('patient','Juan Dela Cruz','juan@email.com',@pw,'09501234567','1990-05-12','male','Dao','123 Rizal St., Barangay Dao, Pagadian City','active',NOW(),'2025-09-10'),
('patient','Rosa Macarambon','rosa@email.com',@pw,'09171112222','1998-03-02','female','Tuburan','Tuburan, Pagadian City','active',NOW(),'2025-09-15'),
('patient','Elmer Galvez','elmer@email.com',@pw,'09183334444','1980-11-20','male','Gatas','Gatas, Pagadian City','active',NOW(),'2025-08-28'),
('patient','Carla Montilla','carla@email.com',@pw,'09195556666','2006-07-09','female','San Pedro','San Pedro, Pagadian City','inactive',NOW(),'2025-10-01'),
('staff','Dr. Maria Santos','santos@clinic.com',@pw,'09187654321','1985-02-10','female','Dao','Rizal Ave, Pagadian City','active',NOW(),'2025-07-01'),
('staff','Dr. Leni Cruz','leni@skin.com',@pw,'09181230000','1987-09-14','female','Gatas','Gatas, Pagadian City','active',NOW(),'2025-07-15');

INSERT INTO clinics (clinic_code,name,specialty,owner_name,address,latitude,longitude,phone,email,operating_hours,status,alert_message,queue_count,avg_wait_min,registration) VALUES
('SGC-2025','Santos General Clinic','General Medicine','Dr. Maria Santos','Rizal Ave, Pagadian City',7.828300,123.436600,'(062) 215-1001','sgc@clinic.ph','Mon–Fri 8:00 AM – 5:00 PM','open',NULL,3,15,'verified'),
('MEC-2025','Mindanao Eye Center','Ophthalmology','Dr. Ramon Ilagan','Jose Rizal St, Pagadian City',7.823100,123.441200,'(062) 215-2002','mec@clinic.ph','Mon–Fri 8:00 AM – 5:00 PM','emergency','High patient volume – expect extended wait times.',28,90,'verified'),
('PSC-2025','Pagadian Skin Clinic','Dermatology','Dr. Leni Cruz','Gatas District, Pagadian City',7.832500,123.431800,'(062) 215-3003','psc@clinic.ph','Mon–Fri 8:00 AM – 5:00 PM','limited','Reduced staffing today – dermatologist available until 12 PM only.',7,30,'verified'),
('CWC-2025',"Children's Wellness Clinic",'Pediatrics','Dr. Joy Reyes','San Pedro, Pagadian City',7.835200,123.445500,'(062) 215-4004','cwc@clinic.ph','Mon–Fri 8:00 AM – 5:00 PM','open',NULL,0,10,'pending'),
('PHC-2025','Pagadian Heart Center','Cardiology','Dr. Victor Lagura','Balangasan, Pagadian City',7.819500,123.428500,'(062) 215-5005','phc@clinic.ph','Mon–Fri 8:00 AM – 5:00 PM','closed','Closed for facility repair.',0,0,'verified'),
('OGC-2025','OB-GYN Care Clinic','OB-GYN','Dr. Ana Reyes','Poblacion, Pagadian City',7.826800,123.433900,'(062) 215-6006','ogc@clinic.ph','Mon–Fri 8:00 AM – 5:00 PM','open',NULL,2,20,'suspended');

INSERT INTO clinic_staff (user_id, clinic_id, license_no, access_code) VALUES (6,1,'PRC-0012345','SGC-2025'),(7,3,'PRC-0067890','PSC-2025');

INSERT INTO clinic_services (clinic_id, name, kind) VALUES
(1,'General Medicine','specialty'),(1,'Consultation','service'),(1,'Vaccination','service'),(1,'Laboratory','service'),
(2,'Ophthalmology','specialty'),(2,'Eye Exam','service'),(2,'Consultation','service'),
(3,'Dermatology','specialty'),(3,'Skin Consultation','service'),(3,'Acne Treatment','service'),
(4,'Pediatrics','specialty'),(4,'Checkup','service'),(4,'Immunization','service'),
(5,'Cardiology','specialty'),(5,'ECG','service'),(6,'OB-GYN','specialty'),(6,'Prenatal Care','service');

INSERT INTO doctors (clinic_id, name, title, availability) VALUES
(1,'Dr. Maria Santos','General Physician','available'),(2,'Dr. Ramon Ilagan','Ophthalmologist','available'),
(3,'Dr. Leni Cruz','Dermatologist','available'),(4,'Dr. Joy Reyes','Pediatrician','available'),
(5,'Dr. Victor Lagura','Cardiologist','available'),(6,'Dr. Ana Reyes','OB-GYN','available');

-- Today's slots for Dr. Maria Santos (doctor 1); 11:00 AM and 3:00 PM are blocked
INSERT INTO slots (doctor_id, slot_date, slot_time, is_blocked) VALUES
(1,CURDATE(),'08:00:00',0),(1,CURDATE(),'08:30:00',0),(1,CURDATE(),'09:00:00',0),(1,CURDATE(),'09:30:00',0),
(1,CURDATE(),'10:00:00',0),(1,CURDATE(),'10:30:00',0),(1,CURDATE(),'11:00:00',1),(1,CURDATE(),'14:00:00',0),
(1,CURDATE(),'14:30:00',0),(1,CURDATE(),'15:00:00',1),(2,CURDATE(),'13:00:00',0),(3,CURDATE(),'15:00:00',0);

INSERT INTO appointments (patient_id, clinic_id, slot_id, service_id, reason, status) VALUES
(2,1,6,2,'Hypertension follow-up','approved'),
(3,1,2,2,'Prenatal check-up','approved'),
(4,1,3,2,'Back pain consultation','pending'),
(5,1,4,2,'General check-up','pending'),
(2,1,1,4,'Diabetes monitoring','completed');

INSERT INTO notifications (user_id, type, title, message) VALUES
(2,'appointment','Appointment Approved','Your appointment at Santos General Clinic has been approved. Please bring a valid ID.'),
(2,'emergency','Emergency Status Alert','Mindanao Eye Center is experiencing high patient volume. Expect extended wait times.'),
(2,'resource','Facility Status Update','Pagadian Heart Center is temporarily closed for facility repairs.'),
(6,'appointment','New Appointment Request','Elmer Galvez requested Back pain consultation.'),
(1,'system','Verification Needed',"Children's Wellness Clinic is awaiting verification.");

INSERT INTO feedback (appt_id, category, rating, comment) VALUES (5,'Service Quality',5,'Fast and friendly service.');
