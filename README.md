
Sentiment Analyzer
======================

🧠 Project Overview
-------------------
A sentiment Analyzer is a NestJS-based backend microservices deployed on Google Cloud Platform (GCP). It performs intelligent text summarization and asynchronous sentiment analysis using a Generative AI model (e.g., Google Gemini via Vertex AI or a compatible API). The service uses a modern, event-driven, microservices-like architecture with robust cloud-native infrastructure.

### Workflow Summary
1. `POST /summarize` accepts text, generates a summary, stores data in Cloud SQL, and publishes an event to Pub/Sub.
2. A Cloud Function is triggered by the Pub/Sub message, fetches the summary, calls POST `/sentiment`  with the content id, and updates the database.
3. `GET /results/:id` retrieves the result, using Redis for caching.

🛠️ Technology Stack
-------------------
**Backend:**
- NestJS
- TypeScript
- Jest

**Generative AI:**
- Google Gemini via Vertex AI SDK/API (or compatible LLM)
- Google Language  Client AI

**GCP Services:**
- Compute Engine (GCE)
- Cloud SQL (PostgreSQL)
- Memorystore (Redis)
- Pub/Sub
- Cloud Functions
- IAM / Service Account
- Cloud Logging

**Infrastructure:**
- Terraform
- GitHub Actions

⚙️ Setup Instructions
---------------------
### Prerequisites
- Node.js (v18+)
- Yarn or npm
- Terraform CLI (v1.5+)
- Google Cloud SDK
- GCP project with billing enabled

### Configuring Credentials & Secrets
1. GCP Credentials:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your-service-account.json"
```

2. GenAI / Vertex AI:
Use environment variables.

🧱 Terraform Deployment
------------------------
### Steps to Deploy Infrastructure
```bash
cd infra/terraform/environment/<env_name>
terraform init
terraform plan -var-file="env/dev.tfvars"
terraform apply -var-file="env/dev.tfvars"
```

### Some Important Variables
- `project_id`, `project_name`, `region`, `zone`, `pubsub_topic`, `env_name`

🚀 Application Deployment Overview
-------------------------
### NestJS Core App (GCE)
The nestjs Core App is first build to docker image and pushed to the google image registry. During the Provisioning of the google VM, a meta script is used to pull the image and spin up an container with all the necessary env variables which subsquently will start the application.

### NestJs Worker (App Cloud Function)
Similary the Worker App is first build into a single file javascript application and then zip to an artifact along side the package.json file which only contains the dev dependencies to reduce the cold start of the application (only install what is necessary). Note that this can also be further improved by packaging the application along side with node_modules. This artifact is then deployed the cloud function during terraform apply phase. 

🔄 Running the Application
--------------------------
### POST /summarize
```json
{ "text": "Sample input..." }
```

### POST /sentiment
```json
{ "textToAnalyze": "Summary text..." }
```

### GET /results/:id
```bash
curl http://VM_PUBLIC_IP:3000/results/13
```

🔁 CI/CD Setup
--------------
- Linting (eslint)
- Unit tests (jest)
- Terraform validation/plan
- Docker builds & deployments

🧠 Design Choices & Assumptions
-------------------------------
### Design Decisions
<img src="img/Screenshot 2025-05-19 at 01.17.14.png"/>

The neccassry assumption considered:
1. security - connection to either vm or sql should be secured as such, only the port to the application was opened while no ssh access where allowed to the application. More also no public IP was asigned to the database instance as such all communication to the db were properly secured and made private. It also worthy to not that db password are retotated every deployment and are not passed to env to the application but are dynamically generated.

2. performance - Passing allowing all the communication between the VM, database and the cloud function not to go through the public internet but with the google private network improve the the application latency and also add the extra security layer. 

3. AI -  no much specific reason why the selected AI model was used but just decided to be more cloud native as possible (GCP) but in a real world scenerio an indept reasearch of the most likely models will be sample and possibly an ADR (Architechure Decision Record) will be genrated with possible POC if neccessry.


### Todo:
1. use configuration tools like Ansible playbook for proper deployment and manage configuration
2. use kubernete for docker orchastration (manage the instances)
3. use some third party tools for drift detection
4. fully decouple the microservice deployment flow.