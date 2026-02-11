# Design Document

## Overview

This design implements OAuth 2.0 authentication endpoints for the Laravel API using Laravel Passport. The solution adds a new `AuthApiController` under the `/api/v1/auth` namespace with three primary endpoints: login, refresh, and logout. The design leverages existing authentication infrastructure (Passport, User model, LoginRequest validation) while providing RESTful API access to authentication operations.

## Architecture

### High-Level Architecture

```
Client Application
       ↓
API Routes (/api/v1/auth/*)
       ↓
AuthApiController
       ↓
Laravel Passport (OAuth Server)
       ↓
User Model & Database
```

### Component Interaction Flow

1. **Login Flow**: Client → Login Endpoint → Validate Credentials → Check User Status → Issue Tokens → Log Event → Return Response
2. **Refresh Flow**: Client → Refresh Endpoint → Validate Refresh Token → Issue New Tokens → Return Response
3. **Logout Flow**: Client → Logout Endpoint → Revoke Token → Log Event → Return Response

## Components and Interfaces

### AuthApiController

**Location**: `cls/app/Http/Controllers/Cls/Api/V1/AuthApiController.php`

**Responsibilities**:
- Handle authentication requests (login, refresh, logout)
- Validate user credentials and status
- Issue and revoke OAuth tokens
- Return consistent JSON responses
- Trigger audit logging

**Public Methods**:

```php
public function login(LoginRequest $request): JsonResponse
public function refresh(Request $request): JsonResponse
public function logout(Request $request): JsonResponse
```

### API Routes

**Location**: `cls/routes/api.php`

**New Routes**:
```php
Route::prefix('/v1/auth')->middleware('throttle:60,1')->group(function () {
    Route::post('/login', [AuthApiController::class, 'login']);
    Route::post('/refresh', [AuthApiController::class, 'refresh'])->middleware('auth:api');
    Route::post('/logout', [AuthApiController::class, 'logout'])->middleware('auth:api');
});
```

### Request/Response Formats

**Login Request**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Login Success Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh_token": "def50200a8f...",
    "token_type": "Bearer",
    "expires_in": 31536000
  }
}
```

**Login Error Response**:
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

**Refresh Request**:
```json
{
  "refresh_token": "def50200a8f..."
}
```

**Logout Response**:
```json
{
  "success": true,
  "message": "Successfully logged out"
}
```

## Data Models

### User Model

**Existing Model**: `App\Cls\User`

**Relevant Attributes**:
- `id`: Primary key
- `email`: User email (unique)
- `password`: Hashed password
- `approved`: Boolean flag for account approval
- `password_updated_at`: Timestamp for password expiry checking
- `role_id`: Foreign key to roles table

**Relevant Methods**:
- `isApproved()`: Check if user account is approved
- `isExpired()`: Check if password has expired
- `createToken(string $name)`: Create Passport access token

### OAuth Tokens

**Managed by Laravel Passport**:
- `oauth_access_tokens`: Stores access tokens
- `oauth_refresh_tokens`: Stores refresh tokens

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Valid credentials produce tokens

*For any* user with valid credentials and approved status, authenticating via the login endpoint should return both an access token and a refresh token.

**Validates: Requirements 1.1**

### Property 2: Invalid credentials are rejected

*For any* authentication attempt with incorrect email or password, the login endpoint should return an error response with success=false and not issue any tokens.

**Validates: Requirements 1.2**

### Property 3: Unapproved users cannot authenticate

*For any* user account where approved=false, authentication attempts should be rejected with an appropriate error message regardless of credential validity.

**Validates: Requirements 1.4**

### Property 4: Expired passwords prevent authentication

*For any* user account where password_updated_at is more than 180 days old (when AUTH_EXPIRY=1), authentication attempts should be rejected with a password reset message.

**Validates: Requirements 1.5**

### Property 5: Valid refresh tokens produce new tokens

*For any* valid refresh token, the refresh endpoint should return a new access token and refresh token pair.

**Validates: Requirements 2.1**

### Property 6: Invalid refresh tokens are rejected

*For any* invalid, expired, or malformed refresh token, the refresh endpoint should return an error response without issuing new tokens.

**Validates: Requirements 2.2**

### Property 7: Token revocation prevents reuse

*For any* access token that has been revoked via the logout endpoint, subsequent API requests using that token should be rejected with an authentication error.

**Validates: Requirements 3.3**

### Property 8: Successful login events are logged

*For any* successful authentication via the login endpoint, the system should create a log entry containing the user ID, IP address, and event type.

**Validates: Requirements 4.1**

### Property 9: Failed login attempts are logged

*For any* failed authentication attempt, the system should create a log entry containing the attempted email, IP address, and failure indication.

**Validates: Requirements 4.2**

### Property 10: Logout events are logged

*For any* successful logout via the logout endpoint, the system should create a log entry containing the user ID, IP address, and logout event type.

**Validates: Requirements 4.3**

### Property 11: Validation errors return field-level details

*For any* login request with missing or invalid fields, the response should contain validation error messages identifying which fields failed validation.

**Validates: Requirements 1.3, 6.2, 7.4**

### Property 12: Response format consistency

*For any* authentication endpoint response (success or error), the JSON structure should contain a "success" boolean field and a "message" string field.

**Validates: Requirements 6.1**

## Error Handling

### Error Categories

1. **Validation Errors** (422 Unprocessable Entity)
   - Missing required fields
   - Invalid email format
   - Empty password

2. **Authentication Errors** (401 Unauthorized)
   - Invalid credentials
   - Expired password
   - Unapproved account
   - Invalid/expired refresh token

3. **Authorization Errors** (403 Forbidden)
   - Revoked token usage

4. **Server Errors** (500 Internal Server Error)
   - Database connection failures
   - Passport configuration issues

### Error Response Strategy

All errors return consistent JSON format:
```json
{
  "success": false,
  "message": "Human-readable error message",
  "errors": {
    "field_name": ["Validation error details"]
  }
}
```

### Specific Error Handling

- **Unapproved Account**: Return "Awaiting Approval" message
- **Expired Password**: Return "Password has expired, please reset" message
- **Invalid Credentials**: Return "Unauthorized" message (generic for security)
- **Invalid Refresh Token**: Return "Invalid or expired refresh token" message

## Testing Strategy

### Unit Testing

Unit tests will verify specific scenarios and edge cases:

1. **Login Endpoint Tests**:
   - Test successful login with valid credentials
   - Test login rejection with invalid email
   - Test login rejection with invalid password
   - Test login rejection for unapproved users
   - Test login rejection for expired passwords
   - Test validation error for missing email
   - Test validation error for missing password
   - Test validation error for malformed email

2. **Refresh Endpoint Tests**:
   - Test successful token refresh with valid refresh token
   - Test rejection of invalid refresh token
   - Test rejection of expired refresh token
   - Test rejection of missing refresh token

3. **Logout Endpoint Tests**:
   - Test successful logout with valid token
   - Test logout with already revoked token
   - Test token becomes invalid after logout

### Property-Based Testing

Property-based tests will verify universal correctness properties using **Pest** with the **Pest Property Testing** plugin (or PHPUnit with a property testing library if Pest doesn't support it natively).

**Configuration**: Each property test should run a minimum of 100 iterations.

**Test Tagging**: Each property-based test must include a comment with this format:
```php
// Feature: oauth-api-authentication, Property 1: Valid credentials produce tokens
```

**Property Tests**:

1. **Property 1 Test**: Generate random valid user credentials → authenticate → verify tokens are present in response
2. **Property 2 Test**: Generate random invalid credentials → authenticate → verify error response with success=false
3. **Property 3 Test**: Generate random unapproved user → authenticate → verify rejection with "Awaiting Approval"
4. **Property 4 Test**: Generate random user with expired password → authenticate → verify rejection with password reset message
5. **Property 5 Test**: Generate valid refresh token → refresh → verify new tokens returned
6. **Property 6 Test**: Generate invalid refresh token → refresh → verify error response
7. **Property 7 Test**: Authenticate → logout → attempt API call with revoked token → verify rejection
8. **Property 8 Test**: Authenticate successfully → verify log entry exists with correct user ID and IP
9. **Property 9 Test**: Fail authentication → verify log entry exists with attempted email
10. **Property 10 Test**: Logout → verify log entry exists with user ID
11. **Property 11 Test**: Generate request with random missing/invalid fields → verify validation errors contain field names
12. **Property 12 Test**: Call any auth endpoint → verify response contains "success" and "message" fields

### Integration Testing

Integration tests will verify end-to-end flows:
- Complete authentication flow: login → access protected route → refresh → access protected route → logout
- Verify existing API routes continue to work with new authentication routes
- Verify rate limiting applies to authentication endpoints

## Implementation Notes

### Passport Token Management

Laravel Passport handles token generation and validation automatically. The controller will use:
- `auth()->attempt()` for credential validation
- `$user->createToken()` for access token generation
- `$request->user()->token()->revoke()` for token revocation

### Refresh Token Implementation

Passport automatically issues refresh tokens. The refresh endpoint will:
1. Accept refresh token in request body
2. Use Passport's token refresh mechanism via HTTP client to `/oauth/token` endpoint
3. Return new token pair to client

### Rate Limiting

Authentication endpoints will use the existing `throttle:60,1` middleware (60 requests per minute) to prevent brute force attacks.

### Backward Compatibility

All existing routes and functionality remain unchanged. The new authentication routes are additive only, placed in a separate route group under `/api/v1/auth`.

### Logging Integration

The implementation will use the existing `LogEventsJob` for audit logging, maintaining consistency with the current web-based login controller.
