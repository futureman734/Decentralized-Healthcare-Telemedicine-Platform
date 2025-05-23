;; Provider Verification Contract
;; Validates healthcare practitioners

(define-data-var admin principal tx-sender)

;; Provider status: 0 = pending, 1 = verified, 2 = rejected
(define-map providers
  { provider-id: principal }
  {
    name: (string-utf8 100),
    specialty: (string-utf8 100),
    credentials: (string-utf8 255),
    license-number: (string-utf8 50),
    status: uint,
    registration-time: uint
  }
)

;; Register as a provider
(define-public (register-provider
    (name (string-utf8 100))
    (specialty (string-utf8 100))
    (credentials (string-utf8 255))
    (license-number (string-utf8 50)))
  (let ((provider-exists (map-get? providers {provider-id: tx-sender})))
    (asserts! (is-none provider-exists) (err u1)) ;; Error 1: Provider already registered
    (ok (map-set providers
      {provider-id: tx-sender}
      {
        name: name,
        specialty: specialty,
        credentials: credentials,
        license-number: license-number,
        status: u0, ;; Pending by default
        registration-time: block-height
      }))))

;; Verify a provider (admin only)
(define-public (verify-provider (provider-id principal))
  (let ((provider (map-get? providers {provider-id: provider-id})))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not admin
    (asserts! (is-some provider) (err u3)) ;; Error 3: Provider not found
    (ok (map-set providers
      {provider-id: provider-id}
      (merge (unwrap-panic provider) {status: u1})))))

;; Reject a provider (admin only)
(define-public (reject-provider (provider-id principal))
  (let ((provider (map-get? providers {provider-id: provider-id})))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not admin
    (asserts! (is-some provider) (err u3)) ;; Error 3: Provider not found
    (ok (map-set providers
      {provider-id: provider-id}
      (merge (unwrap-panic provider) {status: u2})))))

;; Update provider information (provider only)
(define-public (update-provider-info
    (name (string-utf8 100))
    (specialty (string-utf8 100))
    (credentials (string-utf8 255))
    (license-number (string-utf8 50)))
  (let ((provider (map-get? providers {provider-id: tx-sender})))
    (asserts! (is-some provider) (err u3)) ;; Error 3: Provider not found
    (ok (map-set providers
      {provider-id: tx-sender}
      (merge (unwrap-panic provider)
        {
          name: name,
          specialty: specialty,
          credentials: credentials,
          license-number: license-number
        })))))

;; Get provider information
(define-read-only (get-provider (provider-id principal))
  (map-get? providers {provider-id: provider-id}))

;; Check if provider is verified
(define-read-only (is-verified-provider (provider-id principal))
  (let ((provider (map-get? providers {provider-id: provider-id})))
    (if (and (is-some provider) (is-eq (get status (unwrap-panic provider)) u1))
      true
      false)))

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Error 2: Not admin
    (var-set admin new-admin)
    (ok true)))
