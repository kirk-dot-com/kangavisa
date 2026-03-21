# KangaVisa Admin Console PRD v1.0

## 1. Purpose

Define the Administration Console for KangaVisa, enabling:

- System governance
- Rules engine control
- GovData management
- Client access control
- Privacy and compliance oversight

Audience:
- Antigravity (engineering)
- Product / Founder
- Future data/admin operators

---

## 2. Core Principles

- Explainability first (every flag + rule visible)
- Privacy by design (no PII leakage)
- Low operational overhead (automation-first)
- Role-based access control (RBAC)
- Audit everything

---

## 3. User Roles (RBAC)

### Super Admin
Full access across all modules

### Data Analyst
Read analytics, create reports, no rule editing

### Product Admin
Manage visa configs, evidence, flags

### GovData Client
Read-only dashboard access

---

## 4. Core Modules

---

## 4.1 System Overview Dashboard

### Purpose
Real-time system health and insights

### Components
- Total users (by visa)
- Readiness score distribution
- Top flags
- Funnel conversion

### API
GET /admin/overview

---

## 4.2 GovData Monitor

### Purpose
Oversee datasets and analytics outputs

### Components
- Dataset volume by country
- Cohort size validation
- Data freshness timestamps

### Actions
- Enable/disable dataset export
- Apply suppression thresholds

### API
GET /admin/govdata

---

## 4.3 Rules Engine Manager

### Purpose
Manage flag detection rules

### Components
- Flag list (RF_*)
- Rule conditions
- Trigger thresholds

### Actions
- Edit thresholds
- Enable/disable rules
- Add new rules

### API
GET /admin/rules  
POST /admin/rules/update

---

## 4.4 Visa Configuration Manager

### Purpose
Control visa logic

### Components
- Visa subclasses
- Requirements
- Evidence items
- Flag mappings

### Actions
- Add/update visa configs

### API
GET /admin/visas  
POST /admin/visas/update

---

## 4.5 Case Monitor (Internal)

### Purpose
Debug and QA system outputs

### Components
- De-identified case summaries
- Flags triggered
- Scores

### API
GET /admin/cases

---

## 4.6 Client Management

### Purpose
Manage GovData customers

### Components
- Client accounts
- Subscription tier
- Permissions

### Actions
- Grant/revoke access
- Configure datasets

### API
GET /admin/clients  
POST /admin/clients/update

---

## 4.7 Consent & Privacy Manager

### Purpose
Ensure compliance

### Components
- Consent rates
- Opt-in logs
- Data usage logs

### Actions
- Revoke data access
- Audit usage

### API
GET /admin/consent

---

## 5. Database Schema Additions

```sql
admin_users (
  id uuid primary key,
  email text,
  role text,
  created_at timestamp
);

admin_roles (
  role text primary key,
  permissions jsonb
);

client_accounts (
  id uuid primary key,
  name text,
  tier text,
  created_at timestamp
);

client_permissions (
  client_id uuid,
  dataset text,
  access_level text
);

flag_configs (
  id uuid primary key,
  flag_code text,
  enabled boolean,
  threshold jsonb
);

visa_configs (
  id uuid primary key,
  visa_code text,
  config jsonb
);

audit_logs (
  id uuid primary key,
  action text,
  user_id uuid,
  timestamp timestamp
);
```

---

## 6. Key Workflows

### Add New Visa
- Update visa_configs
- Map flags
- Deploy

### Adjust Rule
- Modify threshold
- Save config
- Log audit

### Onboard Client
- Create client account
- Assign permissions
- Enable dashboard

---

## 7. Security

- JWT-based auth
- RLS on all tables
- Admin routes protected
- Audit logging mandatory

---

## 8. Success Criteria

- Admin can modify rules without dev support
- No PII leakage
- All actions auditable
- System runs with minimal intervention

---

## 9. Future Enhancements

- Visual rule builder
- Automated anomaly detection
- Role-based dashboards
- Alerting system

---

## 10. Summary

The Admin Console is the control layer of KangaVisa.

It ensures:
- Trust
- Control
- Scalability

Without it, the system cannot operate safely at scale.
