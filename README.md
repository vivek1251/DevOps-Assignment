# DevOps Assignment — Real-Time WebSocket Chat Application

![CI/CD](https://github.com/vivek1251/DevOps-Assignment/actions/workflows/deploy.yml/badge.svg)

A production-grade deployment of a real-time WebSocket chat application using Docker, Nginx, and GitHub Actions CI/CD — deployed on AWS EC2.

**Live Application:** http://52.206.227.210

---

## Project Overview

This project involved debugging and fixing a deliberately broken deployment setup for a real-time WebSocket chat application. The application code was provided — the task was to identify and fix infrastructure issues, deploy to a cloud server, and automate deployments using CI/CD.

---

## Architecture

```
User Browser
     │
     ▼
http://52.206.227.210 (AWS EC2)
     │
     ▼
┌─────────────────────────────┐
│   NGINX (Docker Container)  │
│   Port 80                   │
│   - Serves frontend HTML    │
│   - Proxies /ws to backend  │
└────────────┬────────────────┘
             │ Docker Network (appnet)
             ▼
┌─────────────────────────────┐
│  Backend (Docker Container) │
│  FastAPI + Uvicorn          │
│  Port 8000                  │
│  - Handles WebSocket conns  │
│  - Manages chat rooms       │
└─────────────────────────────┘
```

---

## Issues Found and Fixed

### Bug 1 — Dockerfile: App bound to localhost
**Problem:** The app was started with `--host 127.0.0.1`, meaning it only listened on localhost inside the container. Nginx could not reach it from another container.

```dockerfile
# Before (broken)
CMD ["uvicorn", "main:app", "--host", "127.0.0.1", "--port", "8000"]

# After (fixed)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Bug 2 — docker-compose.yml: Frontend volume commented out + no network
**Problem:** The frontend volume mount was commented out so Nginx served its default page. There was also no shared Docker network between containers.

```yaml
# Before (broken)
# - ./frontend:/usr/share/nginx/html:ro

# After (fixed)
- ./frontend:/usr/share/nginx/html:ro

# Added shared network to both services
networks:
  - appnet

networks:
  appnet:
    driver: bridge
```

### Bug 3 — nginx.conf: WebSocket headers commented out + wrong proxy_pass
**Problem:** The WebSocket upgrade headers were commented out, breaking the WebSocket connection. The proxy_pass pointed to `localhost` instead of the backend container name.

```nginx
# Before (broken)
proxy_pass http://localhost:8000/ws;
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";

# After (fixed)
proxy_pass http://backend:8000/ws;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

---

## How Docker Containers Are Set Up

The project uses two containers managed by Docker Compose:

**Backend container** — built from the Dockerfile using Python 3.11-slim. It runs a FastAPI application with Uvicorn on port 8000. It is not exposed to the host directly, only accessible within the Docker network.

**Nginx container** — uses the official nginx:alpine image. It listens on port 80, serves the frontend HTML files, and reverse proxies WebSocket connections to the backend container. It is the only container exposed to the internet.

Both containers are configured with `restart: always` so they automatically restart if they crash or if the server reboots.

---

## How Docker Networking Works

Both containers are connected to a custom bridge network called `appnet`. This allows them to communicate using container names as hostnames. Nginx resolves `backend` directly to the backend container's IP address within the network — no hardcoded IPs needed.

```
chat-nginx  ──── appnet (bridge) ──── chat-backend
                 172.x.x.x/16
```

---

## How Nginx Reverse Proxy Works

Nginx handles two types of requests:

- Requests to `/` serve the static frontend HTML from `/usr/share/nginx/html`
- Requests to `/ws` are proxied to the backend container on port 8000

```nginx
location / {
    root /usr/share/nginx/html;
    index index.html;
}

location /ws {
    proxy_pass http://backend:8000/ws;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

---

## How WebSocket Works Through Nginx

WebSocket connections start as a standard HTTP request with an `Upgrade` header. Nginx must forward these headers to the backend — otherwise the connection stays as plain HTTP and WebSocket fails.

The two critical headers are:
- `Upgrade: websocket` — tells the backend to upgrade the connection
- `Connection: upgrade` — tells Nginx to keep the connection open

Without these headers (which were commented out in the original config), the WebSocket handshake fails and the app shows as disconnected.

---

## How CI/CD Pipeline Works

Every `git push` to the `main` branch triggers the GitHub Actions workflow:

```
git push → GitHub Actions triggered
              │
              ▼
         Checkout code
              │
              ▼
         SSH into EC2 (52.206.227.210)
              │
              ▼
         cd ~/devops
         git pull latest code
              │
              ▼
         docker-compose down
         docker-compose up -d --build
              │
              ▼
         App live with latest changes
```

Secrets stored in GitHub Actions — `EC2_HOST`, `EC2_USER`, `EC2_KEY` — no credentials hardcoded anywhere.

---

## Steps to Deploy

### Prerequisites
- AWS EC2 instance (Ubuntu 24.04)
- Docker and Docker Compose installed
- Port 80 open in security group

### 1. Clone the repository
```bash
git clone https://github.com/vivek1251/DevOps-Assignment.git
cd DevOps-Assignment
```

### 2. Run the application
```bash
docker-compose up -d --build
```

### 3. Access the application
Open your browser and go to:
```
http://<your-public-ip>
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Application | FastAPI + Uvicorn (Python) |
| Containerization | Docker |
| Orchestration | Docker Compose |
| Reverse Proxy | Nginx |
| Cloud | AWS EC2 (Ubuntu 24.04) |
| CI/CD | GitHub Actions |

---

## Project Structure

```
DevOps-Assignment/
├── app/
│   ├── main.py               # FastAPI WebSocket application
│   └── requirements.txt      # Python dependencies
├── frontend/
│   └── index.html            # Chat UI
├── .github/
│   └── workflows/
│       └── deploy.yml        # CI/CD pipeline
├── Dockerfile                # Container build instructions
├── docker-compose.yml        # Multi-container setup
├── nginx.conf                # Reverse proxy configuration
└── README.md
```

---

*Built by [Vivek Bommalla](https://github.com/vivek1251)*
