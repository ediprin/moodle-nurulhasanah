# Moodle Nurul Hasanah

Repository ini adalah baseline Moodle terpisah untuk integrasi SIAKAD.

## Baseline

| Item | Nilai |
| --- | --- |
| Moodle upstream | `moodle/moodle` |
| Branch awal | `MOODLE_501_STABLE` |
| Release awal | `5.1.4+ (Build: 20260427)` |
| Web root | `public` |
| Theme tambahan | `theme_moove` |

## Batas Git

Jangan commit:

- `config.php`
- `moodledata`
- dump database
- token Web Service
- password/admin credential
- backup manual
- cache/session/runtime file

## Image

Workflow GitHub membangun image:

```text
ghcr.io/ediprin/moodle-nurulhasanah:staging
ghcr.io/ediprin/moodle-nurulhasanah:<commit-sha>
```

## Dokploy

Gunakan `docker-compose.dokploy.yml`.

Domain staging yang disarankan:

```text
staging-elearning.nurulhasanah.ac.id
```

Domain production nanti:

```text
elearning.nurulhasanah.ac.id
```

Service domain Dokploy:

| Service | Port |
| --- | --- |
| `moodle-app` | `80` |

## First Install

Untuk database kosong, aktifkan sementara:

```env
MOODLE_AUTO_INSTALL=true
MOODLE_ADMIN_PASSWORD=...
MOODLE_REVERSE_PROXY=false
MOODLE_SSL_PROXY=true
```

Setelah install pertama selesai dan admin bisa login, ubah lagi:

```env
MOODLE_AUTO_INSTALL=false
```

## Integrasi SIAKAD

Setelah Moodle staging hidup:

1. Aktifkan REST Web Service.
2. Buat external service `SIAKAD Provisioning`.
3. Tambahkan function minimum sesuai dokumen SIAKAD.
4. Buat token untuk service user khusus.
5. Masukkan endpoint/token ke environment SIAKAD staging.

Endpoint:

```text
https://staging-elearning.nurulhasanah.ac.id/webservice/rest/server.php
```
