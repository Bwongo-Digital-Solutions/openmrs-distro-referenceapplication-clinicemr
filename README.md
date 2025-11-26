# OpenMRS 3.0 Reference Application

This project holds the build configuration for the OpenMRS 3.0 reference application, found on
https://dev3.openmrs.org and https://o3.openmrs.org.

## Quick start

### Run the app (using pre-built images)

```bash
docker compose up
```

or to enable SSL,

```bash
docker compose -f docker-compose.yml -f docker-compose.ssl.yml up
```

The OpenMRS 3.x UI is accessible at http://localhost/openmrs/spa or https://localhost/openmrs/spa

OpenMRS Legacy UI is accessible at http://localhost/openmrs or https://localhost/openmrs

### Production deployment with SSL

For production deployments with HTTPS/SSL certificates:

```bash
SSL_MODE=prod \
CERT_WEB_DOMAINS=your-domain.com \
CERT_CONTACT_EMAIL=admin@your-domain.com \
docker compose -f docker-compose.yml -f docker-compose.ssl.yml up
```

See the [SSL/HTTPS Configuration](#sslhttps-configuration) section for detailed setup instructions.

## Overview

This distribution consists of four images:

- **db** - This is just the standard MariaDB image supplied to use as a database
- **backend** - This image is the OpenMRS backend. It is built from the main Dockerfile included in the root of the project and
  based on the core OpenMRS Docker file. Additional contents for this image are drawn from the `distro` sub-directory which
  includes a full Initializer configuration for the reference application intended as a starting point.
- **frontend** - This image is a simple nginx container that embeds the 3.x frontend, including the modules described in the
  `frontend/spa-assemble-config.json` file.
- **gateway** - This image is an nginx reverse proxy that sits in front of the `backend` and `frontend` containers
  and provides a common interface to both. This helps mitigate CORS issues.

When running with SSL enabled (using `docker-compose.ssl.yml`), an additional service is included:

- **certbot** - This image is used for generating and renewing SSL certificates (Let's Encrypt or self-signed)

## SSL/HTTPS Configuration

The application can be run with SSL/HTTPS support for both development and production environments.

### Development mode (self-signed certificates)

For local development with HTTPS, simply run with the SSL compose file:

```bash
docker compose -f docker-compose.yml -f docker-compose.ssl.yml up
```

This will:
- Automatically generate self-signed certificates for `localhost` and `127.0.0.1`
- Configure nginx to use HTTPS on port 443
- Redirect HTTP (port 80) to HTTPS

The application will be accessible at:
- https://localhost/openmrs/spa
- https://127.0.0.1/openmrs/spa

**Note**: Your browser will show a security warning for self-signed certificates. This is expected - click "Advanced" and proceed to the site.

### Production mode (Let's Encrypt)

For production deployments with valid SSL certificates from Let's Encrypt:

```bash
SSL_MODE=prod \
CERT_WEB_DOMAINS=example.com \
CERT_CONTACT_EMAIL=admin@example.com \
docker compose -f docker-compose.yml -f docker-compose.ssl.yml up
```

**Configuration options**:

- `SSL_MODE=prod` - Use Let's Encrypt certificates (required)
- `CERT_WEB_DOMAINS` - Your domain name(s), comma-separated (e.g., `example.com,www.example.com`)
- `CERT_CONTACT_EMAIL` - Email for Let's Encrypt notifications
- `SSL_STAGING=true` - (Optional) Use Let's Encrypt staging environment for testing

**The certbot container will**:
1. Create a temporary certificate to allow nginx to start
2. Wait for nginx to be ready
3. Request a real Let's Encrypt certificate via ACME HTTP-01 challenge
4. Reload nginx with the real certificate
5. Run a renewal daemon that checks for renewal every 12 hours

**Important**: Ensure your domain's DNS is correctly configured to point to your server before starting, as Let's Encrypt needs to verify domain ownership via HTTP.

### Testing with Let's Encrypt staging

To test the SSL setup without hitting Let's Encrypt rate limits:

```bash
SSL_MODE=prod \
SSL_STAGING=true \
CERT_WEB_DOMAINS=example.com \
CERT_CONTACT_EMAIL=admin@example.com \
docker compose -f docker-compose.yml -f docker-compose.ssl.yml up
```

Staging certificates won't be trusted by browsers but allow you to verify the setup works correctly.

### Manual certificate renewal

While certificates renew automatically in production mode, you can manually force renewal if needed.

**If the certbot container is running** (prod mode):

```bash
# Force renewal
docker compose -f docker-compose.yml -f docker-compose.ssl.yml exec certbot \
  certbot renew --force-renewal --webroot -w /var/www/certbot

# Reload nginx to pick up new certificates
docker compose -f docker-compose.yml -f docker-compose.ssl.yml exec gateway \
  nginx -s reload
```

**If certbot container has stopped or for one-off renewal**:

```bash
# Run certbot in one-off mode (override entrypoint to run certbot directly)
docker compose -f docker-compose.yml -f docker-compose.ssl.yml run --rm \
  --entrypoint certbot certbot \
  renew --force-renewal --webroot -w /var/www/certbot

# Reload nginx
docker compose -f docker-compose.yml -f docker-compose.ssl.yml exec gateway \
  nginx -s reload
```

**Check certificate expiration**:

```bash
# If certbot container is running
docker compose -f docker-compose.yml -f docker-compose.ssl.yml exec certbot \
  certbot certificates

# If certbot container is stopped
docker compose -f docker-compose.yml -f docker-compose.ssl.yml run --rm \
  --entrypoint certbot certbot \
  certificates
```

### Environment variables reference

| Variable | Default | Description |
|----------|---------|-------------|
| `SSL_MODE` | `dev` | `dev` for self-signed certificates, `prod` for Let's Encrypt |
| `SSL_STAGING` | `false` | Use Let's Encrypt staging environment (set to `true` for testing) |
| `CERT_WEB_DOMAINS` | `localhost,127.0.0.1` | Comma-separated list of domain names |
| `CERT_WEB_DOMAIN_COMMON_NAME` | (first domain) | Override the primary domain name |
| `CERT_CONTACT_EMAIL` | (empty) | Email for Let's Encrypt notifications (required in prod mode) |
| `CERT_RSA_KEY_SIZE` | `4096` | RSA key size for certificates |

## Contributing to the configuration

This project uses the [Initializer](https://github.com/mekomsolutions/openmrs-module-initializer) module
to configure metadata for this project. The Initializer configuration can be found in the configuration
subfolder of the distro folder. Any files added to this will be automatically included as part of the
metadata for the RefApp.

Eventually, we would like to split this metadata into two packages:

- `openmrs-core`, which will contain all the metadata necessary to run OpenMRS
- `openmrs-demo`, which will include all of the sample data we use to run the RefApp

The `openmrs-core` package will eventually be a standard part of the distribution, with the `openmrs-demo`
provided as an optional add-on. Most data in this configuration _should_ be regarded as demo data. We
anticipate that implementation-specific metadata will replace data in the `openmrs-demo` package,
though they may use that metadata as a starting point for that customization.

To help us keep track of things, we ask that you suffix any files you add with either
`-core_demo` for files that should be part of the demo package and `-core_data` for
those that should be part of the core package. For example, a form named `test_form.json` would become
`test_core-core_demo.json`.

Frontend configuration can be found in `frontend/config-core_demo.json`.

Thanks!

Offline or Air-Gapped Installations

In situations where the instance running the project is not connected to the internet we provide pre-packaged images which can be loaded on the instance. To obtain the image check under the Releases section and download the path-drc-emr-images-bundle.tgz file.

To load the images on the instance, extract the path-drc-emr-images-bundle.tgz file and run the following script:

./load-images.sh

Backup and Restore

This project provides out-of-the-box backup and restore functionality for your OpenMRS deployment, powered by the robust Restic tool. This enables you to back up and restore your application data using a wide variety of storage backends supported by Restic, such as local disk, S3, Azure, Google Cloud Storage, and more.
How It Works

    Backup and restore are managed by dedicated Docker Compose services using the mekomsolutions/restic-compose-backup and mekomsolutions/restic-compose-backup-restore images.
    The backup service periodically snapshots your data volumes and database, storing them in your configured Restic repository.
    The restore service can be used to recover your data from a specific snapshot.

Configuration
Environment Variables

You can configure backup and restore behavior using the following environment variables in your .env file or directly in your Compose files:
Variable 	Description
RESTIC_REPOSITORY 	The Restic repository URL (e.g., local path, s3, etc.)
RESTIC_PASSWORD 	Password for the Restic repository
RESTIC_KEEP_DAILY 	Number of daily snapshots to keep
RESTIC_KEEP_WEEKLY 	Number of weekly snapshots to keep
RESTIC_KEEP_MONTHLY 	Number of monthly snapshots to keep
RESTIC_KEEP_YEARLY 	Number of yearly snapshots to keep
LOG_LEVEL 	Log verbosity (e.g., info, debug)
CRON_SCHEDULE 	Cron schedule for automatic backups (e.g., 0 2 * * * for daily at 2am)
RESTIC_RESTORE_SNAPSHOT 	(Restore only) The snapshot ID or tag to restore
BACKUP_PATH 	Local directory for storing backup repository (default: ./backup)
Volumes and Labels

    The backend and db services are labeled and configured to include their data volumes in the backup.
    Additional volumes (e.g., for configuration checksums, person images, complex obs) are also included and labeled for backup.

Usage
Restore

To restore from a backup:

    Set the BACKUP_PATH, RESTIC_PASSWORD, and RESTIC_RESTORE_SNAPSHOT environment variables.
    Start the restore service:

docker compose -f docker-compose.yml -f docker-compose-restore.yml up -d

This will restore the specified snapshot to the appropriate volumes. The backend and db services are configured to wait for the restore to complete before starting.

IMPORTANT

The restore process will leave a restore container that will block the backup process. To clean up the restore container, run the following command:

docker compose -f docker-compose.yml -f docker-compose-restore.yml rm restore
docker compose -f docker-compose.yml -f docker-compose-restore.yml exec backup restic unlock -v

References

    Restic Documentation
    mekomsolutions/restic-compose-backup


