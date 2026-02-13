# Enterprise Agentic RAG System (2026 Edition)

Цей проєкт представляє еталонну архітектуру корпоративної RAG-системи (Retrieval-Augmented Generation), побудованої на Google Cloud Platform.

Система повністю безсерверна (Serverless), керована подіями (Event-driven) та використовує новітні можливості **Gemini 2.0 Flash** і **BigQuery Vector Search**.

## Архітектура

1.  **Ingestion Pipeline (ETL):**
    * Користувач завантажує PDF у **Cloud Storage**.
    * **Eventarc** перехоплює подію та викликає сервіс **Ingestor** (Cloud Run).
    * Ingestor витягує текст, генерує вектори (embeddings) через **Vertex AI (text-embedding-005)**.
    * Вектори зберігаються у **BigQuery**.

2.  **Agentic Inference (Робота Агента):**
    * Користувач задає питання сервісу **Agent API** (Cloud Run).
    * **Gemini 2.0 Flash** аналізує запит.
    * Якщо потрібен контекст, модель **самостійно викликає інструмент (Tool Call)** для пошуку в BigQuery.
    * BigQuery виконує векторний пошук і повертає релевантні частини тексту.
    * Агент формує фінальну відповідь із посиланнями на джерело.

## Стек технологій

| Категорія | Сервіс |
|---|---|
| IaC | Terraform (модульна структура, remote GCS backend) |
| Data | Cloud Storage, BigQuery Vector Search, Eventarc |
| Compute | Cloud Run (scale-to-zero) |
| AI | Vertex AI — Gemini 2.0 Flash, text-embedding-005 |
| CI/CD | Cloud Build, Artifact Registry |
| Networking | VPC, Private Google Access, Serverless VPC Connector |
| Security | IAM (Workload Identity), Least Privilege SAs |
| Observability | Cloud Monitoring Dashboard, Cloud Logging |

## Структура проєкту

```
├── cloudbuild.yaml              # CI/CD pipeline (build + deploy)
├── verify.sh                    # End-to-end verification script
├── .gitignore
├── app/                         # Agent API service
│   ├── Dockerfile
│   ├── main.py                  # Gemini 2.0 + Tool Calling
│   └── requirements.txt
├── ingestion/                   # PDF ingestion service
│   ├── Dockerfile
│   ├── main.py                  # PDF → chunks → embeddings → BQ
│   └── requirements.txt
└── terraform/                   # Infrastructure as Code
    ├── provider.tf              # Google provider + remote backend
    ├── variables.tf             # Input variables
    ├── locals.tf                # Derived / computed values
    ├── apis.tf                  # GCP API enablement
    ├── storage.tf               # GCS docs bucket
    ├── bigquery.tf              # BQ dataset, table, connection, ML model
    ├── network.tf               # VPC, subnet, Private Google Access
    ├── iam.tf                   # Service accounts (least privilege)
    ├── artifact_registry.tf     # Docker image repo
    ├── cloud_run.tf             # Cloud Run services
    ├── eventarc.tf              # GCS → Cloud Run trigger
    ├── monitoring.tf            # Cloud Monitoring dashboard
    ├── outputs.tf               # Output values
    └── terraform.tfvars.example # Config template
```



## 🛠 Попередні вимоги (Prerequisites)

* Google Cloud Project з активним білінгом.
* Встановлені `gcloud CLI` та `Terraform >= 1.5`.
* Python 3.11+.
* `gcloud auth login` та `gcloud auth application-default login` виконані.

## 🚀 Розгортання (Покроково)

### 0. Підготовка конфігурації

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Відредагуйте terraform.tfvars — вкажіть ваш project_id та project_number
```

### 1. (Опціонально) Створення Remote Backend для Terraform State

```bash
PROJECT_ID=$(gcloud config get-value project)
gsutil mb -p $PROJECT_ID -l US gs://${PROJECT_ID}-tfstate
gsutil versioning set on gs://${PROJECT_ID}-tfstate
```
Після цього розкоментуйте блок `backend "gcs"` у `terraform/provider.tf` і вкажіть ваш бакет.

### 2. Інфраструктура (Terraform)

```bash
cd terraform
terraform init
terraform plan    # Перевірте зміни
terraform apply   # Підтвердіть створення ресурсів
```

Terraform автоматично створить:
- GCS bucket для документів
- BigQuery dataset, таблицю та ML-модель для ембеддінгів
- VPC з Private Google Access
- Artifact Registry для Docker-образів
- Cloud Run сервіси (Ingestor + Agent API)
- Eventarc тригер (GCS → Ingestor)
- Dedicated Service Accounts (Least Privilege)
- Cloud Monitoring Dashboard

### 3. Перша збірка та деплой (Cloud Build)

```bash
cd ..  # Повернутися до кореня проєкту
gcloud builds submit --config=cloudbuild.yaml
```

Або вручну зібрати та задеплоїти кожен сервіс:

```bash
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1

# Ingestor
gcloud builds submit ./ingestion \
  --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/rag-repo/rag-ingestor:latest

gcloud run deploy rag-ingestor \
  --image ${REGION}-docker.pkg.dev/${PROJECT_ID}/rag-repo/rag-ingestor:latest \
  --region $REGION \
  --service-account rag-ingestor-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --set-env-vars PROJECT_ID=$PROJECT_ID \
  --no-allow-unauthenticated

# Agent API
gcloud builds submit ./app \
  --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/rag-repo/rag-agent:latest

gcloud run deploy rag-agent \
  --image ${REGION}-docker.pkg.dev/${PROJECT_ID}/rag-repo/rag-agent:latest \
  --region $REGION \
  --service-account rag-api-agent-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --set-env-vars PROJECT_ID=$PROJECT_ID \
  --allow-unauthenticated
```
### 4. Тестування (End-to-End Verification)

Для автоматичної перевірки всієї системи використовується скрипт **verify.sh**. Він генерує тестовий PDF із "секретною" інформацією, завантажує його та перевіряє, чи зможе Агент знайти цей секрет.

 Вимоги:

  * Cloud Shell (рекомендовано) або локальний термінал.
  * Встановлена бібліотека **fpdf** (для генерації PDF): **pip install fpdf**.

 Запуск перевірки:

```bash
chmod +x verify.sh
./verify.sh
```

Якщо ви побачите повідомлення **"VERIFICATION SUCCESSFUL" (ПЕРЕВІРКУ ПРОЙДЕНО УСПІШНО)**, значить система працює коректно: Ingestion pipeline відпрацював, вектори записані, і Gemini 2.0 успішно використав інструмент пошуку (RAG).

## 🔐 Безпека

- **Workload Identity** — жодних JSON-ключів. Всі сервіси автентифікуються через dedicated Service Accounts.
- **Least Privilege** — кожен SA має тільки мінімально необхідні ролі.
- **Private Google Access** — трафік між Cloud Run та Google APIs не виходить в публічний інтернет.
- **VPC Connector** — Cloud Run сервіси маршрутизують трафік через приватну мережу.

## 📊 Моніторинг

Terraform автоматично створює Cloud Monitoring Dashboard з наступними метриками:
- Cloud Run — Request Count та Latency (p99)
- Cloud Run — Active Instances (перевірка scale-to-zero)
- Cloud Build — Build Count by Status
- Vertex AI — Prediction Request Count
- BigQuery — Query Count

Переглянути: [Cloud Monitoring Console](https://console.cloud.google.com/monitoring/dashboards)

## 💰 Управління витратами

| Сервіс | Вартість | Як контролювати |
|---|---|---|
| Cloud Run | ~$0 (scale-to-zero, min-instances=0) | Не ставити `--min-instances=1` |
| BigQuery | Копійки за on-demand queries | Не завантажувати гігабайти |
| Vertex AI | Flash = дешево | Уникати нескінченних циклів запитів |
| Artifact Registry | ~$0.10/GB | Lifecycle policy (5 останніх тегів) |

⚠️ **НЕ створюйте** Vertex AI Vector Search Index Endpoint (~$75/міс) — ми використовуємо BigQuery Vector Search (serverless).

### 🧹 Очищення ресурсів

```bash
# 1. Видалити всю інфраструктуру
cd terraform
terraform destroy

# 2. Видалити образи з Artifact Registry (якщо terraform destroy не зачепив)
gcloud artifacts docker images list \
  ${REGION}-docker.pkg.dev/${PROJECT_ID}/rag-repo \
  --format="value(DIGEST)" | \
  xargs -I {} gcloud artifacts docker images delete \
  ${REGION}-docker.pkg.dev/${PROJECT_ID}/rag-repo/rag-agent@{} --quiet

# 3. (Опціонально) Видалити tfstate bucket
gsutil rm -r gs://${PROJECT_ID}-tfstate
```
