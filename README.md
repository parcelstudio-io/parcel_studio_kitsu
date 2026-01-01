# Parcel Studio Kitsu

Production management system for Parcel Studio animation projects using Kitsu and Zou.

## Overview

This repository contains the setup and configuration for Parcel Studio's Kitsu production management system. Kitsu is a web application to track animation and VFX production.

## Quick Start

### Local Development
1. Follow the detailed setup instructions in `setup.txt`
2. Start Zou backend services (PostgreSQL, Redis, Meilisearch)
3. Run Zou development server on port 5000
4. Run Zou events server on port 5001
5. Start Kitsu frontend on port 8080

### Cloud Deployment
Use the Docker deployment or follow the GCP deployment instructions in `setup.txt`.

## Files

- `kitsu_documentation.txt` - Official Kitsu installation documentation
- `setup.txt` - Complete setup guide for local development and cloud deployment
- `docker-compose.yml` - Docker configuration for production deployment
- `gcp-deployment.yml` - Google Cloud Platform deployment configuration

## Access

- **Local Development**: http://localhost:8080
- **Production**: [GCP deployment URL will be provided after deployment]

## Default Credentials

- Email: admin@example.com
- Password: mysecretpassword

## Support

For issues and questions, refer to:
- Kitsu Documentation: https://kitsu.cg-wire.com/
- Zou API Documentation: https://zou.cg-wire.com/

## Team

Managed by Parcel Studio Team