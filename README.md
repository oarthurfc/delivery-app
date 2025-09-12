# 📦 Delivery System

A complete delivery management system developed as an academic project at PUC Minas, implementing a modern architecture with a Flutter mobile app, backend microservices, and serverless cloud infrastructure.

## 🎥 Demonstration

> 📂 Demonstration videos are organized in the [`docs/videos`](docs/videos) folder of this repository.

<p align="center">
  <a href="https://www.youtube.com/watch?v=tKkOWpcZqjU" target="_blank" style="text-decoration: none;">
    <img src="https://img.youtube.com/vi/tKkOWpcZqjU/maxresdefault.jpg" width="600" alt="Complete System Demo" style="border-radius: 15px; border: 2px solid #ddd; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
    <br><br>
    <img src="https://img.shields.io/badge/YouTube-Watch%20Full%20Demo-red?style=for-the-badge&logo=youtube" alt="Watch on YouTube">
    <br><br>
    <strong style="color: #333; font-family: Arial, sans-serif; font-size: 18px;">🎬 Complete Demo: Mobile + Microservices + Serverless</strong>
  </a>
</p>

<p align="center" style="color: #666; font-style: italic; margin-top: 10px;">
  Video demonstrating all integrated system features
</p>

## 🚀 Overview

The Delivery project is a complete solution for delivery management and tracking, providing dedicated interfaces for customers and drivers. The system was developed following modern architecture principles, focusing on scalability, performance, and user experience.

**Key features:**

* 📱 Hybrid mobile app developed with Flutter
* 🔧 Microservices architecture for the backend
* ☁️ Azure Functions integration for serverless processing
* 📍 Real-time tracking with geolocation
* 🔔 Push notifications and email system
* 📸 Photo capture for delivery confirmation
* 🐰 Asynchronous communication via RabbitMQ

## 🏗️ Architecture Preview

<p align="center">
  <img src="docs/diagramas/arquitetura.jpeg" alt="System Architecture" width="800" style="border-radius: 15px; border: 2px solid #ddd; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">

More architecture details are available in the **Backend** documentation: [`backend/README.md`](backend/README.md)

</p>

## 📁 Project Structure

```
delivery/
├── mobile/                   # Flutter mobile app
│   ├── lib/                  # Dart source code
│   ├── android/              # Android configuration
│   ├── ios/                  # iOS configuration
│   └── pubspec.yaml          # Flutter dependencies
│
├── backend/                  # Microservices and API Gateway
│   ├── docker-compose.yml    # Service orchestration
│   ├── api-gateway/          # API Gateway (Spring Cloud Gateway)
│   ├── auth-service/         # Authentication service (Node.js)
│   ├── order-service/        # Order service (Java 21)
│   ├── tracking-service/     # Tracking service (Node.js)
│   ├── setup-all.sh/.bat     # Auto-setup scripts
│   ├── .env.example          # Example environment variables
│   └── README.md             # Backend documentation
│
├── cloud/                    # Cloud infrastructure
│   └── functions/            # Azure Functions serverless
│       ├── src/              # Functions source code
│       ├── package.json      # Node.js dependencies
│       └── host.json         # Azure Functions config
│
└── docs/                     # Project documentation
  ├── diagramas/              # Architecture diagrams
  ├── especificacoes_entregas/# Delivery specifications
  └── videos/                 # Demo videos
```

## 🏗️ Development Phases

### Phase 1: Mobile Development - [Docs](docs/especificacoes_entregas/entrega_01.md)

The first phase focused on building the Flutter mobile app, implementing separate interfaces for customers and drivers. Features include real-time tracking, order history, photo capture with geolocation for delivery proof, and offline storage with SQLite. Push notifications, preferences via Shared Preferences, and robust error handling (connectivity issues, denied permissions) were also implemented.

### Phase 2: Microservices Architecture - [Docs](docs/especificacoes_entregas/entrega_02.md)

In the second phase, the backend was developed using a microservices architecture, creating independent services for authentication (JWT), order management (full CRUD), real-time tracking, and notifications. Communication between services is both synchronous (REST) and asynchronous (messaging), with an API Gateway centralizing routing and authentication. This ensures scalability, maintainability, and fault isolation.

### Phase 3: Serverless Infrastructure - [Docs](docs/especificacoes_entregas/entrega_03.md)

The final phase integrated serverless components into the existing architecture, complementing traditional microservices with Azure Functions. This includes a robust notification system using serverless functions, integration between RabbitMQ and Azure Functions for asynchronous email and push processing, and real-time event management. The result is a hybrid infrastructure combining microservices reliability with serverless scalability and low operational cost.

## 🚀 Running the Project

### Prerequisites

* Flutter SDK (3.0+)
* Dart SDK
* Android Studio / Xcode (for mobile development)
* Docker (for microservices)
* Node.js 20+ (for Node.js services)
* Java 21 JDK (for Java services)
* Maven (included in project wrappers)
* Azure account (for serverless functions)

### Running the Mobile App

```bash
cd mobile/
flutter pub get
flutter run
```

### Running the Microservices

1. Go to the backend folder:

```bash
cd backend/
```

2. Set up environment variables:

```bash
cp .env.example .env
# Edit .env as needed
```

3. Run the automatic setup:

**Windows:**

```bash
./setup-all.bat
```

**Linux/Mac:**

```bash
chmod +x setup-all.sh
./setup-all.sh
```

**Or manually:**

```bash
docker-compose up --build -d
```

Services that will start:

* **API Gateway** (port 8000): Single entry point for all APIs
* **Auth Service** (port 3000): Manages authentication and JWT
* **Order Service** (port 8080): Order management
* **Tracking Service** (port 8081): Real-time tracking
* **MongoDB**: Database for authentication
* **PostgreSQL**: Databases for orders and tracking
* **RabbitMQ**: Messaging system

### Deploying Serverless (Azure Functions)

1. Go to the functions folder:

```bash
cd functions-sb/
```

2. Install dependencies:

```bash
npm install
```

3. Configure Azure environment variables:

```bash
# Configure according to your Azure account
```

4. Deploy to Azure:

```bash
func azure functionapp publish <function-app-name>
```

## 🌐 Service URLs

After successful startup, services are available at:

| Service                 | URL                                                              | Description                    |
| ----------------------- | ---------------------------------------------------------------- | ------------------------------ |
| **🌐 API Gateway**      | [http://localhost:8000](http://localhost:8000)                   | Main entry point               |
| **🔐 Auth Service**     | [http://localhost:3000](http://localhost:3000)                   | Authentication & authorization |
| **📦 Order Service**    | [http://localhost:8080](http://localhost:8080)                   | Order management               |
| **📍 Tracking Service** | [http://localhost:8081](http://localhost:8081)                   | Real-time tracking             |
| **📖 Tracking Docs**    | [http://localhost:8081/api/docs](http://localhost:8081/api/docs) | Swagger documentation          |
| **🐰 RabbitMQ**         | [http://localhost:15672](http://localhost:15672)                 | Management UI                  |

### Databases

| Database                  | Host      | Port  | User           | Password       |
| ------------------------- | --------- | ----- | -------------- | -------------- |
| **PostgreSQL (Orders)**   | localhost | 5432  | delivery\_user | delivery\_pass |
| **PostgreSQL (Tracking)** | localhost | 5433  | root           | root           |
| **MongoDB**               | localhost | 27017 | root           | rootpassword   |

## 🧪 Testing the System

### Quick Health Check

```bash
# Health check for all services
curl http://localhost:3000/health       # Auth
curl http://localhost:8080/health       # Orders  
curl http://localhost:8081/api/tracking/health  # Tracking
curl http://localhost:8000/health       # Gateway
```

### Test via API Gateway

```bash
# All requests go through the gateway
curl http://localhost:8000/api/auth/health
curl http://localhost:8000/api/orders/health
curl http://localhost:8000/api/tracking/health
```

## 🔧 Useful Commands

```bash
# View logs for all services
docker-compose logs -f

# View logs for a specific service
docker-compose logs -f tracking-service

# Stop all services
docker-compose down

# Rebuild and restart everything
docker-compose down && docker-compose up --build -d

# Check container status
docker-compose ps
```

## 📚 Documentation

For detailed information about architecture, APIs, and deployment, see:

* **Backend**: [`backend/README.md`](backend/README.md)
* **Tracking Service**: [`backend/tracking-service/README.md`](backend/tracking-service/README.md)
* **API Gateway**: [`backend/api-gateway/README.md`](backend/api-gateway/README.md)
* **Order Service**: [`backend/order-service/README.md`](backend/order-service/order/README.md)
* **Auth Service**: [`backend/auth-service/README.md`](backend/auth-service/README.md)
* **Specifications**: [`docs/especificacoes_entregas/`](docs/especificacoes_entregas/)

## 🛠️ Technologies Used

* **Mobile:** Flutter, Dart, SQLite, GPS, Camera
* **Backend:** Spring Boot, Node.js, PostgreSQL, MongoDB, RabbitMQ
* **Cloud:** Azure Functions, Azure Service Bus
* **DevOps:** Docker, Docker Compose, Maven
* **Documentation:** Swagger/OpenAPI

## 📈 System Features

### 🔒 Security

* ✅ JWT authentication shared between services
* ✅ Isolated Docker networks
* ✅ API data validation
* ✅ Input sanitization

### 📊 Scalability

* ✅ Independent microservices architecture
* ✅ Asynchronous communication via RabbitMQ
* ✅ Serverless functions for demand spikes
* ✅ Domain-specific databases

### 🔍 Observability

* ✅ Health checks for all services
* ✅ Structured, centralized logs
* ✅ Interactive Swagger documentation
* ✅ Resource monitoring

### 🚀 DevOps

* ✅ Full containerization with Docker
* ✅ Orchestration via Docker Compose
* ✅ Automated setup scripts
* ✅ Serverless deployment via Azure Functions
