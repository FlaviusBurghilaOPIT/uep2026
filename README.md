# uep2026

# Remote CarePro

A post-surgery care platform for clinicians and patients.

## Prerequisites
- [Git](https://git-scm.com)
- [Node.js](https://nodejs.org) (v18 or higher)
- [Docker](https://www.docker.com/products/docker-desktop)

## Getting Started

### 1. Clone the repo
git clone https://github.com/FlaviusBurghilaOPIT/uep2026.git
cd uep2026

### 2. Copy the env file
cp .env.example .env

### 3. Start the mock server
docker-compose up mock

### 4. Start the React web app (new terminal tab)
cd web
npm install
npm run dev

### 5. Open in browser
http://localhost:5173

## Team Branches
- p1/platform — Platform, AI, AWS (P1)
- p2/web-authoring — Clinician web authoring screens (P2)
- p3/web-monitoring — Clinician web monitoring screens (P3)
- p4/mobile — Patient mobile app (P4)
- p5/backend — Backend services (P5)

## API
- Mock server runs at http://localhost:8001
- Real backend runs at http://localhost:8000

## Mobile App (Flutter)
For detailed Flutter mobile app setup (Android, iOS, local backend seeding, demo credentials, debugging), see **[mobile/README.md](mobile/README.md)**.