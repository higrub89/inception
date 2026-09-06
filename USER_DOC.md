# 📖 Inception — User & Administrator Documentation (`USER_DOC.md`)

This guide provides end users and system administrators with the necessary instructions to operate, manage, and verify the Inception web infrastructure.

---

## 1. Accessing the Services

The infrastructure exposes only HTTPS port `443` through the NGINX reverse proxy. All traffic is encrypted using TLS v1.2 / TLS v1.3.

- **Public Website**: [https://rhiguita.42.fr](https://rhiguita.42.fr)
- **WordPress Admin Panel**: [https://rhiguita.42.fr/wp-login.php](https://rhiguita.42.fr/wp-login.php)
- **HTTP (Port 80)**: Not available. Any connection attempts to `http://rhiguita.42.fr` will be dropped/refused.

> **Note**: Because a self-signed TLS certificate is generated automatically for the local domain, modern web browsers will display a security warning. You must click **Advanced** -> **Accept the Risk and Continue** (or proceed).

---

## 2. Managing the Stack Lifecycle

All operational workflows are controlled via the `Makefile` located at the root of the repository.

### Start the Infrastructure
To initialize storage directories and spin up all containers in detached mode:
```bash
make
# or
make up
```

### Stop the Infrastructure
To stop all running services without deleting database records or uploaded media:
```bash
make stop
```

### Resume Stopped Services
To restart existing containers that were stopped:
```bash
make start
```

### Shut Down Containers and Internal Network
To gracefully stop and remove active containers and networks (persisting volumes):
```bash
make down
```

### View Live Service Status
To inspect the running containers, their health checks, and exposed ports:
```bash
make status
```

### Stream Service Logs
To follow real-time logs across all services:
```bash
make logs
```

---

## 3. User & Credential Management

### Available User Accounts

The infrastructure automatically provisions two accounts during the initial startup:

| Account Type | Username | Email | Permissions / Role | Initial Password Source |
|---|---|---|---|---|
| **Administrator** | `rhiguita_master` | `rhiguita@student.42madrid.com` | Full site administration, page editing, plugin management | `secrets/wp_admin_password.txt` |
| **Standard User** | `student` | `student@student.42madrid.com` | Subscriber role; read posts and submit comments | `secrets/db_password.txt` |

> ⚠️ **Notice**: In compliance with 42 security rules, the administrator username does not contain the word `admin` or `Admin`.

### Credential Locations & Docker Secrets
All sensitive passwords are kept outside Git tracking and mounted into containers via Docker Secrets:
- Database user password: `secrets/db_password.txt`
- Database root password: `secrets/db_root_password.txt`
- WordPress administrator password: `secrets/wp_admin_password.txt`

To view the administrator password:
```bash
cat secrets/wp_admin_password.txt
```

### Logging In
1. Navigate to [https://rhiguita.42.fr/wp-login.php](https://rhiguita.42.fr/wp-login.php).
2. For Administrator access:
   - **Username**: `rhiguita_master`
   - **Password**: The content of `secrets/wp_admin_password.txt`.
3. For Subscriber access:
   - **Username**: `student`
   - **Password**: The content of `secrets/db_password.txt`.

---

## 4. Operational & Health Checks

Perform the following routine sanity checks to ensure system integrity:

1. **Verify Sole Entrypoint (Port 443 only)**:
   ```bash
   # HTTPS must respond (code 200)
   curl -k -I https://rhiguita.42.fr

   # HTTP port 80 must fail / be unreachable
   curl -I http://rhiguita.42.fr:80
   ```

2. **Verify TLS Versions**:
   ```bash
   # TLS 1.2 and TLS 1.3 must succeed:
   curl -k -I --tlsv1.2 https://rhiguita.42.fr
   curl -k -I --tlsv1.3 https://rhiguita.42.fr

   # TLS 1.1 or below must be rejected:
   curl -k -I --tlsv1.1 https://rhiguita.42.fr
   ```

3. **Verify Interactive WordPress Features**:
   - Log in with `student` and publish a comment on an existing post.
   - Log in with `rhiguita_master`, edit a page or post from the dashboard, and verify updates are reflected on the public frontend.

4. **Verify Data Persistence**:
   - Post a comment or publish an article.
   - Run `make down` followed by `make up`.
   - Refresh the page to verify that all posts and comments remain intact.
