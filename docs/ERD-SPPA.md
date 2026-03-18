# ERD Ringkas SPPA

## Skop
Dokumen ini menerangkan hubungan jadual utama sistem:
- users
- applications
- application_details
- application_documents
- products
- audit_log

## Diagram (Mermaid)
```mermaid
erDiagram
    USERS ||--o{ APPLICATIONS : submits
    USERS ||--o{ AUDIT_LOG : records_action
    USERS ||--o{ APPLICATIONS : reviews_as_admin

    APPLICATIONS ||--|| APPLICATION_DETAILS : has_detail
    APPLICATIONS ||--o{ APPLICATION_DOCUMENTS : has_documents

    USERS {
        INT id PK
        VARCHAR username UNIQUE
        VARCHAR email UNIQUE
        VARCHAR password_hash
        ENUM role
        VARCHAR full_name
        VARCHAR avatar_url
        ENUM status
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    APPLICATIONS {
        INT id PK
        INT user_id FK
        VARCHAR product_name
        VARCHAR product_category
        TEXT product_description
        VARCHAR company_name
        TEXT company_address
        VARCHAR contact_number
        VARCHAR email
        ENUM status
        TEXT admin_notes
        TIMESTAMP submitted_at
        TIMESTAMP reviewed_at
        INT reviewed_by FK
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    APPLICATION_DETAILS {
        INT id PK
        INT application_id FK UNIQUE
        ENUM application_type
        VARCHAR supplier_name
        TEXT supplier_address
        VARCHAR supplier_phone
        VARCHAR manufacturer_name
        TEXT manufacturer_address
        VARCHAR manufacturer_phone
        VARCHAR principal_name
        TEXT principal_address
        VARCHAR principal_phone
        VARCHAR standard_name
        VARCHAR certification_license
        DATE certification_valid_until
        VARCHAR test_report_reference
        DATE test_report_date
        DECIMAL warranty_years
        VARCHAR sabah_rep_name
        TEXT sabah_rep_address
        VARCHAR sabah_rep_phone
        VARCHAR declaration_name
        VARCHAR declaration_position
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    APPLICATION_DOCUMENTS {
        INT id PK
        INT application_id FK
        VARCHAR document_type
        VARCHAR original_filename
        VARCHAR stored_filename
        TEXT stored_path
        VARCHAR content_type
        BIGINT file_size
        TIMESTAMP created_at
    }

    PRODUCTS {
        INT id PK
        INT no UNIQUE
        INT page
        TEXT supplier_agent
        DATE supplier_valid_until
        VARCHAR product_materials
        VARCHAR product_type
        VARCHAR classification
        VARCHAR brand
        LONGTEXT attachment_urls
        TEXT source_url
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    AUDIT_LOG {
        INT id PK
        INT user_id FK
        VARCHAR action
        TEXT details
        VARCHAR ip_address
        TIMESTAMP created_at
    }
```

## Nota Lokasi Simpanan Data

### 1) Data akaun berdaftar
Disimpan dalam jadual users:
- username, email, role, status, created_at

### 2) Data permohonan
Disimpan dalam:
- applications (ringkasan permohonan)
- application_details (butiran lengkap)

### 3) Data dokumen upload pemohon
Metadata fail disimpan dalam application_documents:
- original_filename, stored_filename, stored_path, content_type, file_size

Fail fizikal dokumen disimpan pada runtime:
- runtime/apache-tomcat-11.0.18/uploads/sistemppa/{applicationId}/

### 4) Data avatar pengguna
Rujukan fail avatar disimpan dalam users.avatar_url.

Fail fizikal avatar disimpan pada runtime:
- runtime/apache-tomcat-11.0.18/uploads/sistemppa/avatars/{userId}/

### 5) Data produk
Sumber utama dari jadual products atau water_products (bergantung data tersedia).

Fail rujukan export/import tempatan:
- data/water_products.json
- data/water_products.csv

## Rujukan Kod Utama
- Konfigurasi DB: src/main/java/com/sistemppa/config/DatabaseConfig.java
- Schema SQL: database/schema.sql
- Simpan dokumen pemohon: src/main/java/com/sistemppa/servlet/ApplicationServlet.java
- Simpan avatar: src/main/java/com/sistemppa/servlet/ProfileServlet.java
- Resolver jadual produk: src/main/java/com/sistemppa/service/DashboardDataService.java
