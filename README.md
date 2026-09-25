# Mangas 📖

Api untuk manga.

---

## 🛠️ Tech Stack

* **Language:** Ruby
* **Framework:** Ruby on Rails
* **Database:** PostgreSQL / MySQL / SQLite *(sesuaikan)*

---

## 🚀 Cara Menjalankan Project (Local Development)

### 1. Prerequisites
Pastikan kamu sudah menginstal:
* **Ruby** (versi 3.x)
* **Rails** (versi 7.x)
* **Bundler**

### 2. Clone Repository
```bash
git clone [https://github.com/USERNAME/Mangas.git](https://github.com/USERNAME/Mangas.git)
cd Mangas

---

## 🔐 Autentikasi API Key

API ini menggunakan dua level API key yang dikirim via header `X-API-KEY`.

### Roles

| Role | ENV Variable | Akses |
|------|-------------|-------|
| `admin` | `API_KEY_ADMIN` | Full CRUD semua resource |
| `user` | `API_KEY_USER` | CRUD reading list milik sendiri saja |
| *(tanpa key)* | — | Read-only (GET index & show) |

### Setup

Salin `.env.example` ke `.env` lalu isi nilainya:

```bash
cp .env.example .env
```

```env
API_KEY_ADMIN=your_admin_secret_key_here
API_KEY_USER=your_user_secret_key_here
```

Generate key aman:
```bash
rails secret | head -c 64
```

### Penggunaan

**Admin** — akses penuh:
```
X-API-KEY: <API_KEY_ADMIN>
```

**User** — create/edit/delete reading list milik sendiri:
```
X-API-KEY: <API_KEY_USER>
X-USER-ID: <user_id>
```

Header `X-USER-ID` wajib disertakan untuk role `user`. `user_id` di body request diabaikan dan selalu di-lock ke nilai header ini, sehingga tidak bisa membuat atau mengubah data milik user lain.

### Matriks Akses Reading List

| Aksi | Tanpa Key | User | Admin |
|------|-----------|------|-------|
| GET index / show | ✅ | ✅ | ✅ |
| POST create | ❌ | ✅ (milik sendiri) | ✅ |
| PATCH/PUT update | ❌ | ✅ (milik sendiri) | ✅ |
| DELETE destroy | ❌ | ✅ (milik sendiri) | ✅ |
