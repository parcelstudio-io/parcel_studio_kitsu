# Parcel Studio Kitsu - Source-Based Production Management System

A complete production management system for Parcel Studio's animation projects, built from source for maximum customization and control.

## 🏗️ Architecture Overview

### Core Components
- **Kitsu Frontend** (`src/kitsu/`) - Vue.js web application for production management UI
- **Zou Backend** (`zou-backend/zou/`) - Python Flask API server for data management
- **PostgreSQL** - Primary database for production data
- **Redis** - Caching and session management
- **Meilisearch** - Full-text search engine (optional)

### Development vs Production
- **Development**: Source-based builds with hot reloading
- **Production**: Containerized deployment with optimized builds

---

## 📂 Repository Structure

```
parcel_studio_kitsu/
├── README.md                          # This file - project overview
├── src/                              # Frontend source code
│   └── kitsu/                        # Kitsu frontend (Vue.js)
│       ├── src/                      # Application source
│       ├── package.json              # Node dependencies
│       └── vite.config.js           # Build configuration
├── zou-backend/                      # Backend source code
│   └── zou/                          # Zou API server (Python Flask)
│       ├── zou/                      # Main application code
│       ├── requirements.txt          # Python dependencies
│       └── zou/cli.py               # Database management CLI
├── deployment/                       # Deployment configurations
│   ├── docker-compose.yml           # Local development setup
│   ├── kubernetes/                   # Production Kubernetes configs
│   └── development/                  # Development environment configs
├── scripts/                          # Build and deployment scripts
│   ├── build-dev.sh                 # Development build script
│   ├── build-prod.sh                # Production build script
│   └── deploy-source.sh             # Source-based deployment
├── docs/                            # Documentation
│   ├── DEVELOPMENT.md               # Development setup guide
│   ├── DEPLOYMENT.md               # Deployment instructions
│   └── CUSTOMIZATION.md            # Customization guidelines
└── config/                          # Configuration files
    ├── development.env              # Development environment variables
    └── production.env               # Production environment variables
```

---

## 📋 File Descriptions

### Root Level Files

| File | Purpose | When to Edit |
|------|---------|--------------|
| `README.md` | Project overview and navigation | When changing architecture or adding features |
| `setup.txt` | Comprehensive setup instructions | When deployment process changes |
| `kitsu_documentation.txt` | Official Kitsu documentation | Reference only - don't edit |
| `.gitignore` | Git ignore patterns | When adding new file types to ignore |
| `.env.example` | Environment variable template | When adding new configuration options |

### Deployment Files

| File | Purpose | When to Edit |
|------|---------|--------------|
| `docker-compose.yml` | Local development with Docker | When changing local dev environment |
| `gcp-deployment.yaml` | Kubernetes production deployment | When changing production infrastructure |
| `gcp-deployment-fixed.yaml` | Alternative Kubernetes config | Testing different deployment strategies |
| `deploy.sh` | Automated deployment script | When changing deployment process |
| `cleanup-and-deploy.sh` | Complete cleanup and redeploy | When deployment process changes |
| `deploy-modern.sh` | Modern component deployment | When updating to newer technologies |

### Source Code Directories

| Directory | Contents | Purpose | When to Edit |
|-----------|----------|---------|--------------|
| `src/kitsu/` | Kitsu frontend source | Vue.js web application | **Edit frequently** - UI changes, features |
| `src/kitsu/src/components/` | Vue components | Reusable UI components | When adding new UI elements |
| `src/kitsu/src/store/` | Vuex state management | Application state logic | When changing data flow |
| `src/kitsu/src/router/` | Vue router configuration | Page routing | When adding new pages |
| `zou-backend/zou/` | Zou API source | Python Flask backend | **Edit frequently** - API changes, logic |
| `zou-backend/zou/zou/` | Core API modules | Business logic | When changing data models or API |
| `zou-backend/zou/zou/cli.py` | Database management | DB initialization and admin | When changing database structure |

### Configuration Files

| File | Purpose | When to Edit |
|------|---------|--------------|
| `src/kitsu/package.json` | Frontend dependencies | When adding/updating npm packages |
| `src/kitsu/vite.config.js` | Build configuration | When changing build process |
| `zou-backend/zou/requirements.txt` | Backend dependencies | When adding/updating Python packages |
| `config/development.env` | Development settings | When changing dev environment |
| `config/production.env` | Production settings | When changing production config |

---

## 🚀 Quick Start

### 1. Development Setup
```bash
# Start development environment
./scripts/build-dev.sh

# Access locally
# Kitsu Frontend: http://localhost:8080
# Zou API: http://localhost:5000
```

### 2. Production Deployment
```bash
# Deploy to GCP
./scripts/deploy-source.sh

# Or use Docker Compose locally
docker-compose up -d
```

### 3. Making Changes

#### Frontend Changes (Kitsu)
```bash
cd src/kitsu
npm install
npm run dev
# Edit files in src/kitsu/src/
# Changes auto-reload in browser
```

#### Backend Changes (Zou)
```bash
cd zou-backend/zou
pip install -r requirements.txt
# Edit files in zou/
# Restart server to see changes
```

---

## 🛠️ Development Workflow

### 1. Feature Development
1. **Frontend**: Edit files in `src/kitsu/src/`
2. **Backend**: Edit files in `zou-backend/zou/zou/`
3. **Test locally**: Use `./scripts/build-dev.sh`
4. **Deploy**: Use `./scripts/deploy-source.sh`

### 2. Configuration Changes
1. **Environment**: Edit `config/development.env` or `config/production.env`
2. **Build process**: Edit `scripts/build-*.sh`
3. **Deployment**: Edit `deployment/kubernetes/*`

### 3. Database Changes
1. **Schema**: Edit migration files in `zou-backend/zou/`
2. **Initialize**: Run `python zou/cli.py init-db`
3. **Migrate**: Use Zou's migration system

---

## 🎯 Common Customizations

### Adding New Features
- **Frontend**: Add components in `src/kitsu/src/components/`
- **Backend**: Add API endpoints in `zou-backend/zou/zou/`
- **Database**: Create migrations for new models

### Changing Appearance
- **Themes**: Edit CSS in `src/kitsu/src/assets/`
- **Components**: Modify Vue components in `src/kitsu/src/components/`
- **Branding**: Update logos and assets

### Integration with Tools
- **Pipeline Tools**: Add integrations in `zou-backend/zou/`
- **File Management**: Extend file handling in Zou
- **Notifications**: Add notification services

---

## 📚 Documentation

- **Development Setup**: `docs/DEVELOPMENT.md`
- **Deployment Guide**: `docs/DEPLOYMENT.md`
- **Customization Guide**: `docs/CUSTOMIZATION.md`
- **API Documentation**: `zou-backend/zou/docs/`
- **Frontend Guide**: `src/kitsu/docs/`

---

## 🔧 Support

### Getting Help
- **Official Documentation**: https://kitsu.cg-wire.com/
- **API Reference**: https://zou.cg-wire.com/
- **Community**: CGWire Discord/Slack
- **Issues**: GitHub issues on respective repositories

### Development Environment
- **Node.js**: >= 18.0
- **Python**: >= 3.9
- **PostgreSQL**: >= 12
- **Redis**: >= 6

---

## 📊 Project Status

✅ **Ready for Development**
- Source code cloned and organized
- Build scripts configured
- Development environment setup
- Production deployment ready

🎯 **Next Steps**
1. Run `./scripts/build-dev.sh` to start development
2. Make your customizations in the source code
3. Deploy with `./scripts/deploy-source.sh`

---

*This is a source-based setup for maximum flexibility and customization. All changes can be made directly to the source code and deployed to your GCP infrastructure.*