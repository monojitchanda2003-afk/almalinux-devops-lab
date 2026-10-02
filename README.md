# AlmaLinux DevOps Lab

A hands-on Linux administration project: a hardened AlmaLinux 9 web server built in Oracle VirtualBox, covering SSH key authentication, nginx, firewalld, SELinux, cron automation, backups, log analysis, and troubleshooting.

## Environment
- Oracle VirtualBox, AlmaLinux 9 VM (4 GB RAM, 2 CPUs, 100 GB disk)
- NAT networking with port forwarding: host `2222` to guest `22` (SSH)
- Administration done from Windows PowerShell over SSH

## What I built

### 1. Users and SSH hardening
- Created a `devops` group and a `devuser` account
- Generated an ed25519 key pair on Windows and installed the public key in `~/.ssh/authorized_keys` (permissions `700` on `.ssh`, `600` on the file)
- Disabled root login and password authentication with a drop-in file, `/etc/ssh/sshd_config.d/00-hardening.conf`:
  ```
  PermitRootLogin no
  PasswordAuthentication no
  ```
- Verified with `sudo sshd -T`, and confirmed a password attempt is rejected with `Permission denied (publickey,...)`

### 2. Web server and firewall
- Installed and enabled nginx and firewalld
- Opened only the required services (`ssh`, `http`) and checked with `firewall-cmd --list-all`

### 3. SELinux
- Found SELinux **disabled** (`SELINUX=disabled`), so re-enabled it: set `permissive`, touched `/.autorelabel`, rebooted for the filesystem relabel, checked for denials with `ausearch -m avc`, then switched to enforcing mode
- Served a custom site from `/srv/site`; the default label was `var_t`
- Fixed the label permanently with `semanage fcontext` and `restorecon`, giving `httpd_sys_content_t`

### 4. Automation with cron
- `scripts/health_check.sh` reports disk, memory, load, service status (sshd, nginx, firewalld) and the SELinux mode
- Scheduled every 5 minutes, logging to `health.log`
- Nightly `tar.gz` backup of `/srv/site` at 02:00, with 7-day retention cleanup at 02:30

### 5. Log analysis
- Reviewed `/var/log/secure` for accepted and rejected SSH logins
- Used `journalctl -u sshd` and the nginx access and error logs

### 6. Troubleshooting drills
| Drill | Symptom | How I diagnosed it | Fix |
|-------|---------|--------------------|-----|
| nginx stopped | `Connection refused` on port 80 | `systemctl status nginx`, `ss -tulnp` | `systemctl start nginx` |
| HTTP removed from firewall | Service unreachable from outside | `firewall-cmd --list-all` | `firewall-cmd --reload` (permanent rule still present) |
| Wrong SELinux label | `403 Forbidden` | AVC denial in `ausearch` (`httpd_t` on `var_t`) | `restorecon` |
| `chmod 000` on the page | `403 Forbidden` | `error.log` shows `Permission denied`, no AVC denial | `chmod 644` |

## Issues faced and fixes
- **firewalld was installed but not running:** enabled it with `systemctl enable --now firewalld`
- **SELinux was disabled:** re-enabled it through permissive mode and an autorelabel
- **Cron could not find `getenforce`:** cron runs with a minimal `PATH`, so I added `export PATH=...` to the script
- **Two kinds of 403:** a wrong SELinux label leaves an AVC denial, while a file permission problem does not

## Screenshots

### SSH hardening
![SSH hardening result](screenshots/ssh-hardening.png)
*Password login rejected, while key-based login succeeds.*

### SELinux label fix
![SELinux label fix](screenshots/selinux-labels.png)
*Before and after the SELinux context correction.*

### 403 and AVC denial
![403 forbidden and AVC denial](screenshots/403-avc.png)
*The 403 response and the corresponding SELinux AVC audit log.*

### Health check and monitoring
![Health check output](screenshots/health-log.png)
*Cron health check output showing services and system status.*

## Skills demonstrated
Linux administration, SSH key authentication, firewalld, SELinux, nginx, cron, Bash scripting, log analysis, troubleshooting.
