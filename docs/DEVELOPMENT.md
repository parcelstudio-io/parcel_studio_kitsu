# Parcel Studio Kitsu - Development Guide

## 🏁 Quick Start

### Local Development
```bash
# Start development environment
./scripts/build-dev.sh

# Access your development instance
open http://localhost:5173
```

### Production Deployment to GCP
```bash
# Deploy from source to GCP
./scripts/deploy-source.sh
```

## 📂 Source Code Organization

### Frontend (Kitsu)
- **Location**: `src/kitsu/`
- **Technology**: Vue.js 3 + Vite
- **Development**: Hot reloading enabled
- **Build**: `npm run build`

### Backend (Zou)  
- **Location**: `zou-backend/zou/`
- **Technology**: Python Flask
- **Development**: Auto-restart on changes
- **CLI**: `python zou/cli.py`

## 🛠️ Development Commands

| Command | Purpose |
|---------|---------|
| `./scripts/build-dev.sh` | Start complete development environment |
| `./scripts/stop-dev.sh` | Stop all development services |
| `./scripts/deploy-source.sh` | Deploy to GCP from source |
| `cd src/kitsu && npm run dev` | Frontend development only |
| `cd zou-backend/zou && gunicorn zou.app:app` | Backend development only |

## 🔧 Customization

### Frontend Changes
1. Edit files in `src/kitsu/src/`
2. Changes auto-reload in browser
3. Build with `npm run build`

### Backend Changes  
1. Edit files in `zou-backend/zou/zou/`
2. Restart development server
3. Test API at `http://localhost:5000/api`

### Database Changes
1. Edit models in `zou-backend/zou/zou/models/`
2. Create migrations: `python zou/cli.py db migrate`
3. Apply migrations: `python zou/cli.py db upgrade`

## 🏗️ Architecture

```
Development Environment:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Kitsu Frontend  │────│ Zou Backend     │────│ PostgreSQL      │
│ Vue.js          │    │ Python Flask    │    │ Database        │
│ localhost:5173  │    │ localhost:5000  │    │ localhost:5432  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                         ┌─────────────────┐
                         │ Redis Cache     │
                         │ localhost:6379  │
                         └─────────────────┘
```

## 🎯 Common Development Tasks

### Adding New Features
1. **Frontend**: Add Vue components in `src/kitsu/src/components/`
2. **Backend**: Add API endpoints in `zou-backend/zou/zou/blueprints/`
3. **Database**: Add models in `zou-backend/zou/zou/models/`

### Debugging
- **Frontend logs**: Browser DevTools console
- **Backend logs**: Terminal running Zou server
- **Database logs**: `docker logs dev-postgres`

### Testing
- **Frontend**: `cd src/kitsu && npm run test`
- **Backend**: `cd zou-backend/zou && python -m pytest`

## 🚀 Deployment

### Local Testing
```bash
docker-compose up -d
open http://localhost
```

### GCP Production
```bash
./scripts/deploy-source.sh
# Builds from source and deploys to Kubernetes
```

## 🔐 Default Credentials

- **Email**: `admin@parcelstudio.com`
- **Password**: `parcelstudio2025`

## 📊 Monitoring

### Development
- Kitsu: http://localhost:5173
- Zou API: http://localhost:5000/api
- Database: localhost:5432

### Production
- Monitor with: `kubectl get pods`
- View logs: `kubectl logs -l app=kitsu-frontend`

---

*This development environment is fully customizable and builds everything from source for maximum flexibility.*