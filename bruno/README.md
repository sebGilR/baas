# BAAS API - Bruno Collection

This folder contains [Bruno](https://www.usebruno.com/) API requests for testing the BAAS (Backend as a Service) API.

## 📁 Collection Structure

```
bruno/
├── bruno.json              # Bruno collection config
├── collection.json         # Collection metadata
├── environments/
│   └── local.bru           # Local environment variables
├── auth/
│   ├── 01-register.bru     # User registration
│   ├── 02-login.bru        # User login
│   ├── 02a-login-invalid.bru   # Login with invalid credentials (error test)
│   ├── 03-refresh-token.bru    # Refresh access token
│   ├── 03a-refresh-token-invalid.bru  # Refresh with invalid token (error test)
│   ├── 04-logout.bru       # Logout (revoke refresh token)
│   └── 04a-logout-invalid.bru  # Logout with invalid token (error test)
└── health/
    ├── health-check.bru    # Health check endpoint
    └── public.bru          # Public endpoint test
```

## 🚀 Getting Started

### Prerequisites

1. Install [Bruno](https://www.usebruno.com/) (free, open-source API client)
2. Make sure the Rails server is running:
   ```bash
   cd /path/to/baas
   bin/rails server
   ```

### Opening the Collection

1. Open Bruno
2. Click "Open Collection"
3. Navigate to this `bruno/` folder
4. Select the folder

### Selecting Environment

1. In Bruno, click on the environment dropdown (top right)
2. Select "local"
3. The `base_url` will be set to `http://localhost:3000`

## 🔐 Authentication Flow

The typical authentication flow is:

1. **Register** (`01-register.bru`) - Create a new user account
   - Automatically saves `access_token` and `refresh_token` to environment

2. **Login** (`02-login.bru`) - Login with existing credentials
   - Automatically saves `access_token` and `refresh_token` to environment

3. **Refresh Token** (`03-refresh-token.bru`) - Get new tokens when access token expires
   - Uses `refresh_token` from environment
   - Automatically updates both tokens in environment

4. **Logout** (`04-logout.bru`) - Revoke the refresh token
   - Uses `refresh_token` from environment
   - Clears tokens from environment

## 📋 Environment Variables

| Variable | Description | Set By |
|----------|-------------|--------|
| `base_url` | API base URL | Manual (in environment) |
| `access_token` | JWT access token (24 hour expiry) | Auto (after login/register) |
| `refresh_token` | Refresh token (30 day expiry) | Auto (after login/register) |

## 🧪 Running Tests

Each request includes built-in tests. To run them:

1. Open a request in Bruno
2. Click "Send"
3. Check the "Tests" tab for results

### Test Coverage

| Endpoint | Tests |
|----------|-------|
| Health Check | Status 200, status "ok", database connected |
| Register | Status 201, tokens present, user/account data |
| Login | Status 200, tokens present, correct expiry |
| Login (Invalid) | Status 401, error format |
| Refresh | Status 200, new tokens, rotation works |
| Refresh (Invalid) | Status 401, error format |
| Logout | Status 204 |
| Logout (Invalid) | Status 400, error format |

## 📝 Request Format

All requests follow the **JSON:API v1.1** specification:

```json
{
  "data": {
    "type": "resource_type",
    "attributes": {
      "field1": "value1",
      "field2": "value2"
    }
  }
}
```

## ❌ Error Response Format

Errors follow JSON:API format:

```json
{
  "errors": [
    {
      "status": "401",
      "title": "Authentication Failed",
      "detail": "Invalid email or password"
    }
  ]
}
```

## 🔗 API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/health` | Health check | No |
| GET | `/api/v1/public` | Public endpoint | No |
| POST | `/api/v1/auth/register` | Register new user | No |
| POST | `/api/v1/auth/login` | Login | No |
| POST | `/api/v1/auth/refresh` | Refresh tokens | No (uses refresh_token) |
| DELETE | `/api/v1/auth/logout` | Logout | No (uses refresh_token) |

## 💡 Tips

1. **Run in sequence**: For the full auth flow, run requests in order (1 → 2 → 3 → 4)
2. **Check environment**: If requests fail, verify tokens are set in the environment
3. **Token rotation**: After refresh, the old refresh token is revoked - use the new one
4. **Duplicate users**: Registration will fail if email already exists - use a unique email

## 🐛 Troubleshooting

### "Connection refused"
- Make sure Rails server is running: `bin/rails server`
- Verify port 3000 is not in use

### "401 Unauthorized"
- For protected endpoints, ensure `access_token` is set
- Token may have expired - try refreshing

### "422 Unprocessable Entity"
- Check request body format
- Verify required fields are present
- Email may already be registered
