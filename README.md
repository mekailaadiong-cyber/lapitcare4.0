# LapitCARE – Project Structure

```
lapitcare_project/
├── index.html            ← open this (Live Server)
├── css/
│   ├── base.css          variables, buttons, forms, cards
│   ├── loginPage.css     login + registration screens (all 3 roles)
│   ├── dashboard.css     top bar, tabs, shared dashboard parts
│   ├── patient.css       clinic cards, booking steps, profile avatar
│   ├── map.css           Leaflet map
│   ├── staff.css         slots grid, doctor availability
│   └── admin.css         report charts
├── js/                   (loaded in this order)
│   ├── utils.js          helpers shared by every page
│   ├── data.js           sample data + app state  ← replace with API calls later
│   ├── notifications.js  patient cards + staff/admin list
│   ├── home.js           landing page
│   ├── loginPage.js      login + registration
│   ├── patient.js        clinics, booking, appointments, feedback
│   ├── map.js            Leaflet interactive map
│   ├── profile.js        My Profile (patient, admin)
│   ├── staff.js          clinic staff dashboard
│   ├── admin.js          administrator dashboard
│   ├── dashboard.js      top bar + tab router
│   └── main.js           starts the app
└── database/
    ├── lapitcare.sql     schema + sample data
    └── queries.sql       queries the backend will use
```

## Run the GUI
1. Open the folder in VS Code → install **Live Server** → right-click `index.html` → *Open with Live Server*.

## Set up MySQL (XAMPP)
1. Start **Apache** and **MySQL** in the XAMPP Control Panel.
2. Open http://localhost/phpmyadmin → **Import** → choose `database/lapitcare.sql` → **Go**.
3. Demo accounts (password for all: `password`): `admin@lapitcare.gov.ph`, `juan@email.com` (patient), `santos@clinic.com` (staff).
4. `database/queries.sql` has the SQL for every screen (login, booking, slots, reports…).

The GUI currently runs on the sample data in `js/data.js`. Next step is a PHP (or Node) API that runs the queries in `queries.sql` and returns JSON, then replacing `data.js` with `fetch()` calls.
