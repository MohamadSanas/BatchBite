# BatchBite

Campus-based multi-vendor food delivery and batch ordering system.

## Structure

- `backend/` - FastAPI backend
- `frontend/` - Flutter frontend
- `requirements.txt` - root convenience file for backend Python dependencies

## Quick Start

### Backend

1. Create and activate a virtual environment.
2. Install dependencies:
   - `pip install -r requirements.txt`
3. Configure backend env:
   - update `backend/.env`
4. Run API:
   - `uvicorn app.main:app --reload --app-dir backend`

### Frontend

1. `cd frontend`
2. `flutter pub get`
3. `flutter run`
