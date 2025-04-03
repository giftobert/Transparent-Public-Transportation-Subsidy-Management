;; Recipient Verification Contract
;; This contract validates eligibility for transit subsidies

(define-data-var admin principal tx-sender)

;; Data structures
(define-map recipients
  { address: principal }
  {
    is-eligible: bool,
    income-level: uint,
    last-verified: uint,
    verification-expiry: uint
  }
)

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))
(define-constant ERR_NOT_REGISTERED (err u102))

;; Read-only functions
(define-read-only (is-admin)
  (is-eq tx-sender (var-get admin))
)

(define-read-only (get-recipient (address principal))
  (map-get? recipients {address: address})
)

(define-read-only (is-eligible (address principal))
  (default-to false (get is-eligible (map-get? recipients {address: address})))
)

(define-read-only (is-verification-expired (address principal))
  (let (
    (recipient-data (map-get? recipients {address: address}))
    (current-time block-height)
  )
    (if (is-none recipient-data)
      true
      (> current-time (unwrap-panic (get verification-expiry recipient-data)))
    )
  )
)

;; Public functions
(define-public (register-recipient (address principal) (income-level uint) (verification-period uint))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? recipients {address: address})) ERR_ALREADY_REGISTERED)

    (map-set recipients
      {address: address}
      {
        is-eligible: true,
        income-level: income-level,
        last-verified: block-height,
        verification-expiry: (+ block-height verification-period)
      }
    )
    (ok true)
  )
)

(define-public (update-eligibility (address principal) (eligible bool))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? recipients {address: address})) ERR_NOT_REGISTERED)

    (let ((recipient-data (unwrap-panic (map-get? recipients {address: address}))))
      (map-set recipients
        {address: address}
        (merge recipient-data {is-eligible: eligible})
      )
    )
    (ok true)
  )
)

(define-public (renew-verification (address principal) (verification-period uint))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? recipients {address: address})) ERR_NOT_REGISTERED)

    (let ((recipient-data (unwrap-panic (map-get? recipients {address: address}))))
      (map-set recipients
        {address: address}
        (merge recipient-data
          {
            last-verified: block-height,
            verification-expiry: (+ block-height verification-period)
          }
        )
      )
    )
    (ok true)
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (var-set admin new-admin)
    (ok true)
  )
)
