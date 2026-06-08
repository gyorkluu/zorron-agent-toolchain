# Common Ports Reference

This document lists commonly used ports that should be considered reserved when allocating ports for new projects.

## Well-Known System Ports (0–1023)

| Port | Protocol | Service | Description |
|------|----------|---------|-------------|
| 20 | TCP | FTP-Data | File Transfer Protocol (Data) |
| 21 | TCP | FTP | File Transfer Protocol (Control) |
| 22 | TCP | SSH | Secure Shell |
| 23 | TCP | Telnet | Telnet Protocol |
| 25 | TCP | SMTP | Simple Mail Transfer Protocol |
| 53 | TCP/UDP | DNS | Domain Name System |
| 67 | UDP | DHCP-Server | Dynamic Host Configuration (Server) |
| 68 | UDP | DHCP-Client | Dynamic Host Configuration (Client) |
| 69 | UDP | TFTP | Trivial File Transfer Protocol |
| 80 | TCP | HTTP | Hypertext Transfer Protocol |
| 110 | TCP | POP3 | Post Office Protocol v3 |
| 119 | TCP | NNTP | Network News Transfer Protocol |
| 123 | UDP | NTP | Network Time Protocol |
| 143 | TCP | IMAP | Internet Message Access Protocol |
| 161 | UDP | SNMP | Simple Network Management Protocol |
| 162 | UDP | SNMP-Trap | SNMP Trap |
| 194 | TCP | IRC | Internet Relay Chat |
| 443 | TCP | HTTPS | HTTP over TLS/SSL |
| 445 | TCP | SMB | Server Message Block |
| 465 | TCP | SMTPS | SMTP over SSL |
| 514 | UDP | Syslog | System Log |
| 515 | TCP | LPD | Line Printer Daemon |
| 587 | TCP | SMTP-Submit | SMTP Message Submission |
| 636 | TCP | LDAPS | LDAP over SSL |
| 993 | TCP | IMAPS | IMAP over SSL |
| 995 | TCP | POP3S | POP3 over SSL |

## Database Ports

| Port | Service | Description |
|------|---------|-------------|
| 1433 | MSSQL | Microsoft SQL Server |
| 1521 | Oracle | Oracle Database |
| 3306 | MySQL | MySQL Database |
| 5432 | PostgreSQL | PostgreSQL Database |
| 5433 | PostgreSQL-Alt | PostgreSQL (alternate / CockroachDB) |
| 6379 | Redis | Redis Key-Value Store |
| 7000 | Cassandra-Cluster | Cassandra Cluster Communication |
| 8529 | ArangoDB | ArangoDB |
| 9042 | Cassandra | Apache Cassandra CQL |
| 9200 | Elasticsearch-HTTP | Elasticsearch REST API |
| 9300 | Elasticsearch-Transport | Elasticsearch Transport |
| 11211 | Memcached | Memcached |
| 2379 | etcd-Client | etcd Client API |
| 2380 | etcd-Peer | etcd Peer Communication |
| 27017 | MongoDB | MongoDB Database |
| 27018 | MongoDB-Shard | MongoDB Shard |
| 28017 | MongoDB-Web | MongoDB Web Interface |
| 54321 | Supabase-DB | Supabase Local PostgreSQL |

## Message Queue & Streaming Ports

| Port | Service | Description |
|------|---------|-------------|
| 2181 | ZooKeeper | Apache ZooKeeper |
| 4222 | NATS | NATS Messaging |
| 5672 | RabbitMQ-AMQP | RabbitMQ AMQP Protocol |
| 61613 | RabbitMQ-STOMP | RabbitMQ STOMP Protocol |
| 61616 | ActiveMQ | Apache ActiveMQ |
| 8161 | ActiveMQ-Web | ActiveMQ Web Console |
| 9092 | Kafka | Apache Kafka Broker |
| 9093 | Kafka-SSL | Kafka Broker (SSL) |
| 15672 | RabbitMQ-Mgmt | RabbitMQ Management UI |
| 29092 | Kafka-Docker | Kafka (Docker mapped) |

## Container & Orchestration Ports

| Port | Service | Description |
|------|---------|-------------|
| 2375 | Docker-API | Docker API (unencrypted) |
| 2376 | Docker-API-TLS | Docker API (TLS) |
| 3000 | Docker-Registry-Mirror | Docker Registry Mirror |
| 5000 | Docker-Registry | Docker Registry |
| 6443 | Kubernetes-API | Kubernetes API Server |
| 7946 | Swarm-Discovery | Docker Swarm Discovery |
| 8500 | Consul-HTTP | Consul HTTP API |
| 8600 | Consul-DNS | Consul DNS |

## Monitoring & Observability Ports

| Port | Service | Description |
|------|---------|-------------|
| 3000 | Grafana | Grafana Dashboard (default) |
| 5601 | Kibana | Kibana Dashboard |
| 8125 | StatsD | StatsD Metrics |
| 9090 | Prometheus | Prometheus Server |
| 9091 | Pushgateway | Prometheus Pushgateway |
| 9100 | Node-Exporter | Prometheus Node Exporter |
| 9113 | Nginx-Exporter | Nginx Prometheus Exporter |
| 9200 | Elasticsearch | Elasticsearch (also serves metrics) |
| 9411 | Zipkin | Zipkin Tracing |
| 14250 | Jaeger-GRPC | Jaeger gRPC |
| 14268 | Jaeger-HTTP | Jaeger HTTP |
| 16686 | Jaeger-UI | Jaeger UI |
| 4317 | OTLP-gRPC | OpenTelemetry gRPC |
| 4318 | OTLP-HTTP | OpenTelemetry HTTP |

## CI/CD & DevOps Ports

| Port | Service | Description |
|------|---------|-------------|
| 8080 | Jenkins | Jenkins CI/CD |
| 8111 | TeamCity | JetBrains TeamCity |
| 9000 | SonarQube | SonarQube |
| 9002 | SonarQube-ELK | SonarQube Embedded Elasticsearch |
| 7990 | Bitbucket | Atlassian Bitbucket |
| 8090 | Confluence | Atlassian Confluence |
| 8085 | Jira | Atlassian Jira |

## Development Server Ports (Common Defaults)

| Port | Service | Description |
|------|---------|-------------|
| 3000 | Next.js / React / Express | Default dev server |
| 3100 | NestJS | Common NestJS dev |
| 3200 | ElysiaJS | ElysiaJS dev server |
| 3300 | Express-Alt | Express alternate |
| 4000 | General API | Common API server |
| 4200 | Angular | Angular CLI dev server |
| 5000 | Flask / Python | Flask dev server |
| 5173 | Vite | Vite default dev server |
| 5174 | Vite-Alt | Vite alternate |
| 6006 | Storybook | Storybook dev server |
| 8000 | Django / Webpack | Django dev / Webpack dev |
| 8080 | Vue CLI / Tomcat | Vue CLI dev / Tomcat |
| 8443 | HTTPS-Dev | HTTPS dev server |
| 8888 | Jupyter | Jupyter Notebook |
| 1337 | Strapi | Strapi CMS |
| 19000 | Expo | Expo React Native |
| 19006 | Expo-Web | Expo Web |

## Mail & Testing Ports

| Port | Service | Description |
|------|---------|-------------|
| 1025 | MailHog/Mailpit-SMTP | Test SMTP Server |
| 1080 | MailHog-Alt | MailHog alternate |
| 8025 | MailHog/Mailpit-Web | Test Mail Web UI |
| 5050 | pgAdmin | PostgreSQL Admin UI |

## Object Storage & File Services

| Port | Service | Description |
|------|---------|-------------|
| 9000 | MinIO-API | MinIO Object Storage API |
| 9001 | MinIO-Console | MinIO Console UI |
| 9200 | SeaweedFS | SeaweedFS Volume Server |

## Port Range Allocation Strategy

When allocating ports for a new project, follow these ranges:

| Range | Category | Example |
|-------|----------|---------|
| 3000–3999 | Development servers | Next.js, NestJS, ElysiaJS, Express |
| 4000–4999 | Backend APIs & services | REST APIs, gRPC services |
| 5000–5199 | Frontend dev tools | Vite, Flask, Storybook |
| 5200–5999 | Reserved for expansion | — |
| 6000–6999 | Testing & QA | Storybook, test runners |
| 7000–7999 | Internal tools | Admin panels, dashboards |
| 8000–8999 | Web frameworks | Django, Webpack, Vue CLI |
| 9000–9999 | Infrastructure | MinIO, Elasticsearch, Prometheus |
| 10000–19999 | Databases & middleware | (use specific ports when possible) |
| 20000–29999 | Docker mapped ports | Container port mappings |
| 30000–32767 | Kubernetes NodePort | K8s NodePort range |
| 49152–65535 | Ephemeral | OS-assigned temporary ports (avoid) |
