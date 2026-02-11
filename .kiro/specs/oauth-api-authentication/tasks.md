# Implementation Plan

- [x] 1. Create AuthApiController with core authentication methods
  - Create `cls/app/Http/Controllers/Cls/Api/V1/AuthApiController.php`
  - Implement login method that validates credentials and issues tokens
  - Implement logout method that revokes tokens
  - Implement refresh method that issues new token pairs
  - Add proper use statements for User, LoginRequest, LogEventsJob, and Passport components
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 3.1_

- [ ]* 1.1 Write property test for valid credentials producing tokens
  - **Property 1: Valid credentials produce tokens**
  - **Validates: Requirements 1.1**

- [ ]* 1.2 Write property test for invalid credentials rejection
  - **Property 2: Invalid credentials are rejected**
  - **Validates: Requirements 1.2**

- [ ]* 1.3 Write property test for unapproved user rejection
  - **Property 3: Unapproved users cannot authenticate**
  - **Validates: Requirements 1.4**

- [ ]* 1.4 Write property test for expired password rejection
  - **Property 4: Expired passwords prevent authentication**
  - **Validates: Requirements 1.5**

- [x] 2. Implement login endpoint logic with user status validation
  - Add credential validation using LoginRequest
  - Check user approval status and return appropriate error
  - Check password expiry status and return appropriate error
  - Generate access and refresh tokens using Passport
  - Dispatch login event to LogEventsJob with user ID and IP
  - Return JSON response with tokens or error message
  - _Requirements: 1.1, 1.2, 1.4, 1.5, 4.1, 4.2, 6.1_

- [ ]* 2.1 Write unit tests for login endpoint scenarios
  - Test successful login with valid approved user
  - Test rejection of unapproved user
  - Test rejection of expired password user
  - Test rejection of invalid credentials
  - Test validation errors for missing fields
  - Test validation errors for invalid email format
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 7.1, 7.2, 7.3_

- [x] 3. Implement refresh endpoint logic
  - Whenever need to run php command for testing, always use with docker. container name is "cls"
  - Accept refresh token from request body
  - Validate refresh token format and presence
  - Use Passport's OAuth token endpoint to exchange refresh token for new tokens
  - Handle invalid or expired refresh token errors
  - Return JSON response with new token pair or error
  - _Requirements: 2.1, 2.2, 2.4_

- [ ]* 3.1 Write property test for valid refresh token
  - **Property 5: Valid refresh tokens produce new tokens**
  - **Validates: Requirements 2.1**

- [ ]* 3.2 Write property test for invalid refresh token rejection
  - **Property 6: Invalid refresh tokens are rejected**
  - **Validates: Requirements 2.2**

- [ ]* 3.3 Write unit tests for refresh endpoint
  - Test successful refresh with valid token
  - Test rejection of invalid refresh token
  - Test rejection of expired refresh token
  - Test rejection of missing refresh token
  - _Requirements: 2.1, 2.2, 2.4_

- [x] 4. Implement logout endpoint logic with token revocation
  - Get authenticated user from request
  - Revoke the current access token
  - Dispatch logout event to LogEventsJob with user ID and IP
  - Return JSON success response
  - Handle errors for already revoked tokens
  - _Requirements: 3.1, 3.2, 4.3_

- [ ]* 4.1 Write property test for token revocation
  - **Property 7: Token revocation prevents reuse**
  - **Validates: Requirements 3.3**

- [ ]* 4.2 Write unit tests for logout endpoint
  - Test successful logout with valid token
  - Test logout with already revoked token
  - Test that token cannot be used after logout
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 5. Add authentication routes to api.php
  - Whenever need to run php command for testing, always use with docker. container name is "cls"
  - Add new route group under `/api/v1/auth` prefix
  - Apply `throttle:60,1` middleware to all auth routes
  - Register POST `/login` route without auth middleware
  - Register POST `/refresh` route with `auth:api` middleware
  - Register POST `/logout` route with `auth:api` middleware
  - Add use statement for AuthApiController
  - Verify existing routes remain unchanged
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ]* 5.1 Write property test for logging successful authentication
  - **Property 8: Successful login events are logged**
  - **Validates: Requirements 4.1**

- [ ]* 5.2 Write property test for logging failed authentication
  - **Property 9: Failed login attempts are logged**
  - **Validates: Requirements 4.2**

- [ ]* 5.3 Write property test for logging logout events
  - **Property 10: Logout events are logged**
  - **Validates: Requirements 4.3**

- [x] 6. Implement consistent error response formatting
  - Ensure all controller methods return JSON with `success` and `message` fields
  - Add `data` field for successful responses containing tokens
  - Add `errors` field for validation failures with field-level details
  - Use appropriate HTTP status codes (200, 401, 422, 500)
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ]* 6.1 Write property test for validation error format
  - **Property 11: Validation errors return field-level details**
  - **Validates: Requirements 1.3, 6.2, 7.4**

- [ ]* 6.2 Write property test for response format consistency
  - **Property 12: Response format consistency**
  - **Validates: Requirements 6.1**

- [ ]* 6.3 Write integration tests for complete authentication flows
  - Test full flow: login → access protected route → refresh → access protected route → logout
  - Test that existing API routes work alongside new auth routes
  - Test rate limiting on authentication endpoints
  - _Requirements: 5.1, 5.2, 5.3_

- [ ] 7. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
