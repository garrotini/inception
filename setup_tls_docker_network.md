## Explore the OneUptime platform

One platform for monitoring, observability &amp; incident response.

Search products...

`⌘K`

[AI](/product/ai-agent)

[Investigates incidents with AI and turns findings into fix pull requests for your review.](/product/ai-agent)

### Essentials

[Monitoring](/product/monitoring)

[Uptime &amp; synthetic checks](/product/monitoring)

[Status Page](/product/status-page)

[Communicate incidents to users](/product/status-page)

[Incidents](/product/incident-management)

[Detect, manage &amp; resolve](/product/incident-management)

[On-Call &amp; Alerts](/product/on-call)

[Smart routing &amp; escalations](/product/on-call)

[Scheduled Maintenance](/product/scheduled-maintenance)

[Plan &amp; communicate downtime](/product/scheduled-maintenance)

### Observability

[Observability](/product/observability)

[Logs, metrics &amp; traces in one](/product/observability)

[Topology](/product/topology)

[Service, infra &amp; network maps](/product/topology)

[Security Events](/product/security-events)

[SIEM signals &amp; Sigma detections](/product/security-events)

[Logs](/product/logs-management)

[Fastest log ingest &amp; search](/product/logs-management)

[Metrics](/product/metrics)

[Application &amp; infra metrics](/product/metrics)

[Traces](/product/traces)

[Distributed request tracing](/product/traces)

[Exceptions](/product/exceptions)

[Error tracking &amp; debugging](/product/exceptions)

[Profiles](/product/profiles)

[CPU &amp; memory profiling](/product/profiles)

[RUM](/product/rum)

[Real user monitoring](/product/rum)

### Infrastructure

[Services](/product/services)

[Catalog every service you run](/product/services)

[Databases](/product/databases)

[Queries, engine metrics &amp; alerts](/product/databases)

[Queues](/product/queues)

[Backlog, consumer lag &amp; dead letters](/product/queues)

[Kubernetes](/product/kubernetes)

[Cluster &amp; pod observability](/product/kubernetes)

[Docker](/product/docker)

[Host &amp; container observability](/product/docker)

[Podman](/product/podman)

[Host &amp; container observability](/product/podman)

[Hosts](/product/host)

[Auto-discovered server metrics](/product/host)

[Proxmox](/product/proxmox)

[VE clusters, VMs &amp; backups](/product/proxmox)

[VMware](/product/vmware)

[vCenter, ESXi hosts, VMs &amp; datastores](/product/vmware)

[AI / LLM Observability](/product/ai-observability)

[Tokens, cost, traces &amp; prompts](/product/ai-observability)

[Ceph](/product/ceph)

[Storage cluster health](/product/ceph)

[Docker Swarm](/product/docker-swarm)

[Nodes, services, tasks &amp; stacks](/product/docker-swarm)

[IoT Devices](/product/iot)

[Fleets, sensors &amp; gateways](/product/iot)

[Network Devices](/product/network-monitoring)

[Switches, routers &amp; firewalls](/product/network-monitoring)

[Serverless](/product/serverless)

[Functions &amp; cold starts](/product/serverless)

[Cloud](/product/cloud)

[AWS, GCP &amp; Azure](/product/cloud)

### Automation &amp; Analytics

[Workflows](/product/workflows)

[No-code automation builder](/product/workflows)

[Runbooks](/product/runbooks)

[Auto-trigger response steps](/product/runbooks)

[Dashboards](/product/dashboards)

[Custom data visualizations](/product/dashboards)

[Open Source](https://github.com/oneuptime/oneuptime)

[Self-host or use our cloud](https://github.com/oneuptime/oneuptime)

`↑ ↓ ↵ esc`

<!-- 🖼️❌ Image not available. Please use `PdfPipelineOptions(generate_picture_images=True)` -->

# How to Set Up Docker Container-to-Container TLS Communication

Secure communication between Docker containers using TLS with certificate generation, configuration, and verification steps.

Nawaz Dhandala

<!-- 🖼️❌ Image not available. Please use `PdfPipelineOptions(generate_picture_images=True)` -->

By @nawazdhandala

• Feb 08, 2026 • Reading time

[Docker](/blog/tag/docker) [TLS](/blog/tag/tls) [SSL](/blog/tag/ssl) [Security](/blog/tag/security) [Networking](/blog/tag/networking) [Encryption](/blog/tag/encryption) [Container](/blog/tag/container) [Certificate](/blog/tag/certificate)

## On this page

Containers on the same Docker network communicate in plaintext by default. The bridge network does not encrypt traffic between containers. For many development setups this is fine, but production workloads handling sensitive data need encryption. Mutual TLS (mTLS) between containers ensures that traffic is encrypted and both parties verify each other's identity.

This guide walks through setting up TLS between Docker containers, from creating a certificate authority to configuring services and verifying the encrypted connection.

## Why Encrypt Container-to-Container Traffic?

Even on a private Docker bridge network, there are reasons to encrypt:

- Compliance requirements (PCI DSS, HIPAA, SOC 2) mandate encryption in transit
- Multi-tenant environments where containers from different teams share a host
- Defense in depth, if an attacker gains access to the host, they cannot read container traffic
- Service identity verification prevents man-in-the-middle attacks between containers

## Setting Up a Private Certificate Authority

Start by creating a CA (Certificate Authority) that signs certificates for your containers:

```
# Create a directory structure for the CA

mkdir -p docker-tls/{ca,server,client}
cd docker-tls

# Generate the CA private key
openssl genrsa -out ca/ca-key.pem 4096

# Create the CA certificate (valid for 10 years)
openssl req -new -x509 -days 3650 -key ca/ca-key.pem -sha256 \
  -out ca/ca-cert.pem \
  -subj "/C=US/ST=California/L=SanFrancisco/O=MyOrg/CN=Docker Internal CA"
```

Verify the CA certificate:

```
# Inspect the CA certificate details
openssl x509 -in ca/ca-cert.pem -noout -text | head -20
```

## Generating Server Certificates

Each service that accepts TLS connections needs a server certificate. Create one for a web service:

```
# Generate the server private key
openssl genrsa -out server/server-key.pem 4096

# Create a certificate signing request (CSR) with SANs for Docker DNS names
openssl req -new -key server/server-key.pem \
  -out server/server.csr \
  -subj "/C=US/ST=California/L=SanFrancisco/O=MyOrg/CN=web-service"
```

Create a SAN (Subject Alternative Name) configuration to support Docker DNS names:

```
# server/san.cnf - Subject Alternative Names for Docker service discovery
cat > server/san.cnf << 'EOF'
[req]
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_ext]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = web-service
DNS.2 = web-service.my-network
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF
```

Sign the server certificate with the CA:

```
# Sign the server certificate using the CA key
openssl x509 -req -days 365 \
  -in server/server.csr \
  -CA ca/ca-cert.pem \
  -CAkey ca/ca-key.pem \
  -CAcreateserial \
  -out server/server-cert.pem \
  -extfile server/san.cnf \
  -extensions v3_ext
```

## Generating Client Certificates

For mutual TLS, clients also need certificates:

```
# Generate the client private key
openssl genrsa -out client/client-key.pem 4096

# Create the client CSR
openssl req -new -key client/client-key.pem \
  -out client/client.csr \
  -subj "/C=US/ST=California/L=SanFrancisco/O=MyOrg/CN=api-client"

# Create client extensions configuration
cat > client/client-ext.cnf << 'EOF'
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

# Sign the client certificate
openssl x509 -req -days 365 \
  -in client/client.csr \
  -CA ca/ca-cert.pem \
  -CAkey ca/ca-key.pem \
  -CAcreateserial \
  -out client/client-cert.pem \
  -extfile client/client-ext.cnf
```

## Configuring an Nginx Container with TLS

Set up Nginx to accept TLS connections and verify client certificates:

```
# nginx-tls.conf - Nginx configuration with mutual TLS
server {
    listen 443 ssl;
    server_name web-service;

    # Server certificate and key
    ssl_certificate /etc/nginx/certs/server-cert.pem;
    ssl_certificate_key /etc/nginx/certs/server-key.pem;

    # CA certificate for verifying client certificates
    ssl_client_certificate /etc/nginx/certs/ca-cert.pem;
    ssl_verify_client optional;

    # TLS protocol and cipher settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        if ($ssl_client_verify != SUCCESS) {
            return 403;
        }

        return 200 '{"status": "ok", "client_dn": "$ssl_client_s_dn"}';
        add_header Content-Type application/json;
    }

    location /health {
        return 200 '{"healthy": true}';
        add_header Content-Type application/json;
    }
}
```

## Docker Compose with TLS

Bring everything together in Docker Compose:

```
# docker-compose.yml - Container-to-container mTLS setup
services:
  web-service:
    image: nginx:alpine
    volumes:
      - ./nginx-tls.conf:/etc/nginx/conf.d/default.conf:ro
      - ./server/server-cert.pem:/etc/nginx/certs/server-cert.pem:ro
      - ./server/server-key.pem:/etc/nginx/certs/server-key.pem:ro
      - ./ca/ca-cert.pem:/etc/nginx/certs/ca-cert.pem:ro
    networks:
      - secure-network
    ports:
      - "443:443"

  api-client:
    image: curlimages/curl:latest
    user: root
    volumes:
      - ./client/client-cert.pem:/certs/client-cert.pem:ro
      - ./client/client-key.pem:/certs/client-key.pem:ro
      - ./ca/ca-cert.pem:/certs/ca-cert.pem:ro
    networks:
      - secure-network
    entrypoint: ["sleep", "3600"]

networks:
  secure-network:
    driver: bridge
```

## Testing the mTLS Connection

Start the services and test:

```
# Start all services
docker compose up -d

# Test mTLS connection from the client container
docker compose exec api-client curl -s \
  --cert /certs/client-cert.pem \
  --key /certs/client-key.pem \
  --cacert /certs/ca-cert.pem \
  https://web-service:443/

# Expected output: {"status": "ok", "client_dn": "CN=api-client,O=MyOrg,L=SanFrancisco,ST=California,C=US"}
```

Test that connections without valid client certificates are rejected:

```
# This should fail because no client cert is provided
docker compose exec api-client curl -s \
  --cacert /certs/ca-cert.pem \
  https://web-service:443/
# Expected: 403 Forbidden
```

## Certificate Rotation

Certificates expire. Automate rotation without downtime:

```
#!/bin/bash
# rotate-certs.sh - Generate new certificates and reload services

cd /path/to/docker-tls

# Generate new server certificate (reuse the same key)
openssl req -new -key server/server-key.pem \
  -out server/server-new.csr \
  -subj "/C=US/ST=California/L=SanFrancisco/O=MyOrg/CN=web-service"

openssl x509 -req -days 365 \
  -in server/server-new.csr \
  -CA ca/ca-cert.pem \
  -CAkey ca/ca-key.pem \
  -CAcreateserial \
  -out server/server-cert.pem \
  -extfile server/san.cnf \
  -extensions v3_ext

# Reload nginx without restarting the container
docker compose exec web-service nginx -s reload

echo "Certificate rotated and nginx reloaded"
```

Schedule this with cron:

```
# Run certificate rotation monthly
0 2 1 * * /path/to/rotate-certs.sh >> /var/log/cert-rotation.log 2>&1
```

## Using Docker Secrets for Certificate Distribution

For Docker Swarm deployments, use Docker secrets instead of bind mounts:

```
# Create secrets from certificate files
docker secret create ca-cert ca/ca-cert.pem
docker secret create server-cert server/server-cert.pem
docker secret create server-key server/server-key.pem
docker secret create client-cert client/client-cert.pem
docker secret create client-key client/client-key.pem
```

Reference secrets in your service definition:

```
# docker-compose.swarm.yml - Using Docker secrets for TLS
services:
  web-service:
    image: nginx:alpine
    secrets:
      - source: ca-cert
        target: /etc/nginx/certs/ca-cert.pem
      - source: server-cert
        target: /etc/nginx/certs/server-cert.pem
      - source: server-key
        target: /etc/nginx/certs/server-key.pem
    configs:
      - source: nginx-tls-config
        target: /etc/nginx/conf.d/default.conf

secrets:
  ca-cert:
    external: true
  server-cert:
    external: true
  server-key:
    external: true

configs:
  nginx-tls-config:
    file: ./nginx-tls.conf
```

## Verifying TLS in Traffic Captures

Confirm that traffic is actually encrypted:

```
# Capture traffic on the Docker bridge network
NETWORK_ID=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' \
  "$(docker compose ps -q web-service)")
sudo tcpdump -i br-${NETWORK_ID:0:12} \
  -w /tmp/docker-tls-capture.pcap -c 100

# In another terminal, make a request
docker compose exec api-client curl -s \
  --cert /certs/client-cert.pem \
  --key /certs/client-key.pem \
  --cacert /certs/ca-cert.pem \
  https://web-service:443/

# Analyze the capture - you should see TLS handshake, not plaintext
tcpdump -r /tmp/docker-tls-capture.pcap -A | head -50
```

The captured traffic will show the TLS handshake and encrypted application data. No plaintext HTTP content should be visible.

## Debugging TLS Issues

Common problems and their solutions:

```
# Check certificate validity
openssl x509 -in server/server-cert.pem -noout -dates

# Verify the certificate chain
openssl verify -CAfile ca/ca-cert.pem server/server-cert.pem

# Test TLS connection with verbose output
docker compose exec api-client curl -v \
  --cert /certs/client-cert.pem \
  --key /certs/client-key.pem \
  --cacert /certs/ca-cert.pem \
  https://web-service:443/ 2>&1

# Check if the SAN matches the hostname
openssl x509 -in server/server-cert.pem -noout -ext subjectAltName
```

## Conclusion

Container-to-container TLS adds a meaningful security layer to Docker deployments. The setup involves creating a CA, generating server and client certificates, mounting them into containers, and configuring services to use them. The overhead is minimal (TLS 1.3 adds roughly 1ms per connection), and the benefits include encrypted traffic, service identity verification, and compliance with security standards. Start with TLS for your most sensitive services, such as databases and authentication services, then expand to cover all inter-service communication.

Share this article

Nawaz Dhandala

<!-- 🖼️❌ Image not available. Please use `PdfPipelineOptions(generate_picture_images=True)` -->

### Nawaz Dhandala

Author

@nawazdhandala • Feb 08, 2026 •

Nawaz is building OneUptime with a passion for engineering reliable systems and improving observability.

[GitHub](https://github.com/nawazdhandala)

Technically validated · Jun 04, 2026

View report

### Help improve this post

Every OneUptime blog post is open source. Found a typo, an inaccuracy, or have a clearer way to explain something? Anyone can contribute - your edits make this post better for everyone who reads it next.

[Edit this post on GitHub](https://github.com/oneuptime/blog/tree/master/posts/2026-02-08-how-to-set-up-docker-container-to-container-tls-communication) [Contributing guidelines](https://github.com/oneuptime/blog)

[Open source](https://github.com/oneuptime/oneuptime)

## OneUptime is the Open-Source  Observability Platform

Your complete reliability stack unified: infrastructure monitoring, incident management, status pages, and APM. Open-source and self-hostable.

[Get started for free](/accounts/register) [Request a demo](/enterprise/demo)

[Status Page Real-time status updates](/product/status-page) [Incidents Detect and resolve fast](/product/incident-management) [Monitoring Monitor any resource](/product/monitoring) [On-Call Smart alert routing](/product/on-call) [Maintenance Plan &amp; communicate downtime](/product/scheduled-maintenance) [Logs Fastest log ingest and search](/product/logs-management) [Metrics Performance insights](/product/metrics) [Traces End-to-end distributed tracing](/product/traces) [Exceptions Catch and fix bugs early](/product/exceptions) [Workflows Automate any process](/product/workflows) [Dashboards Visualize all your data](/product/dashboards) [Kubernetes Monitor K8s clusters](/product/kubernetes) [Profiles CPU &amp; memory profiling](/product/profiles)

[AI Detect, diagnose, and resolve incidents with AI-powered root cause analysis and code fixes.](/product/ai-agent)

## Footer

Open Source Observability

### Build reliable systems with confidence

Join thousands of developers using OneUptime to monitor, debug, and optimize their infrastructure, stack, and apps.

[Read Blog](/blog) [Star on GitHub](https://github.com/oneuptime/oneuptime)

OneUptime

<!-- 🖼️❌ Image not available. Please use `PdfPipelineOptions(generate_picture_images=True)` -->

The complete open-source observability platform. Monitor, debug, and improve your entire stack in one place.

[GitHub](https://github.com/oneuptime/oneuptime) [X](https://x.com/oneuptimehq) [Nostr](https://njump.me/npub1kggtaw83q0mctlwvh854xdu3wjmen8tmq9cx9l030x2ylay6wk8qy2f2e6) [YouTube](https://www.youtube.com/@OneUptimeHQ) [Reddit](https://www.reddit.com/r/oneuptimehq/) [LinkedIn](https://www.linkedin.com/company/oneuptime)

Trusted by thousands of teams worldwide - from Fortune 500 enterprises to fast-growing startups.

### Products

- [Status Page](/product/status-page)
- [Incidents](/product/incident-management)
- [Monitoring](/product/monitoring)
- [On-Call](/product/on-call)
- [Observability](/product/observability)
- [Topology](/product/topology)
- [Security Events](/product/security-events)
- [Logs](/product/logs-management)
- [Metrics](/product/metrics)
- [Traces](/product/traces)
- [Exceptions](/product/exceptions)
- [Profiles](/product/profiles)
- [Real User Monitoring](/product/rum)
- [Kubernetes](/product/kubernetes)
- [Docker](/product/docker)
- [Podman](/product/podman)
- [Hosts](/product/host)
- [Databases](/product/databases)
- [Queues](/product/queues)
- [Proxmox](/product/proxmox)
- [VMware](/product/vmware)
- [AI / LLM Observability](/product/ai-observability)
- [Ceph](/product/ceph)
- [Docker Swarm](/product/docker-swarm)
- [IoT Devices](/product/iot)
- [Network Devices](/product/network-monitoring)
- [Serverless](/product/serverless)
- [Cloud](/product/cloud)
- [Workflows](/product/workflows)
- [Dashboards](/product/dashboards)
- [AI](/product/ai-agent)

### Solutions

- [Enterprise](/enterprise/overview)
- [Self-Hosted](/enterprise/self-hosted)
- [Request Demo](/enterprise/demo)
- [Pricing](/pricing)
- [Trust Center](/trust)
- [Data Residency](/legal/data-residency)

### Teams

- [DevOps](/solutions/devops)
- [SRE](/solutions/sre)
- [Platform](/solutions/platform)
- [Developers](/solutions/developers)

### Tools

- [MCP Server](/tool/mcp-server)
- [CLI](/tool/cli)

### Resources

- [Documentation](/docs)
- [API Reference](/reference)
- [Blog](/blog)
- [Books](/books)
- [Help &amp; Support](/support)
- [GitHub](https://github.com/oneuptime/oneuptime)
- [Changelog](https://github.com/oneuptime/oneuptime/releases)
- [Open Source Friends](/oss-friends)

### Industries

- [FinTech](/industries/fintech)
- [SaaS](/industries/saas)
- [Healthcare](/industries/healthcare)
- [E-Commerce](/industries/ecommerce)
- [Media](/industries/media)
- [Government](/industries/government)

### Company

- [About Us](/about)
- [Careers](https://github.com/OneUptime/interview)
- [Merch Store](https://shop.oneuptime.com/)
- [Contact](/legal/contact)

### Legal

- [Trust Center](/trust)
- [Terms of Service](/legal/terms)
- [Privacy Policy](/legal/privacy)
- [SLA](/legal/sla)
- [Legal Center](/legal)
- [Cookie Policy](/legal/cookies)
- [Cookie settings](#)

### Compare

- [vs PagerDuty](/compare/pagerduty)
- [vs Datadog](/compare/datadog)
- [vs Grafana](/compare/grafana)
- [vs Opsgenie](/compare/opsgenie)
- [vs Statuspage](/compare/statuspage.io)
- [vs Incident.io](/compare/incident.io)
- [vs New Relic](/compare/newrelic)
- [vs Better Stack](/compare/better-uptime)
- [View all comparisons →](/compare)

© 2026 HackerBay, Inc. All rights reserved.

[Open Source](https://github.com/oneuptime/oneuptime) | Made with care for developers worldwide

[SOC 2](/legal/soc-2) [HIPAA](/legal/hipaa) [GDPR](/legal/gdpr) [ISO 27001](/legal/iso-27001)

## Validation report

Technically reviewed for accuracy • Jun 04, 2026

Loading validation report...

Automated technical review

Close