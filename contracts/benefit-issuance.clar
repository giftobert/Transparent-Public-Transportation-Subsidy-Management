;; Benefit Issuance Contract
;; This contract manages distribution of fare assistance

(define-data-var admin principal tx-sender)

;; Data structures
(define-map benefits
  { recipient: principal }
  {
    balance: uint,
    monthly-allocation: uint,
    last-issuance: uint,
    total-received: uint
  }
)

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_RECIPIENT_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_ALREADY_ISSUED_THIS_MONTH (err u103))
(define-constant BLOCKS_PER_MONTH u4380) ;; Approximately 30 days

;; Read-only functions
(define-read-only (is-admin)
  (is-eq tx-sender (var-get admin))
)

(define-read-only (get-benefit-info (recipient principal))
  (map-get? benefits {recipient: recipient})
)

(define-read-only (get-balance (recipient principal))
  (default-to u0 (get balance (map-get? benefits {recipient: recipient})))
)

;; Public functions
(define-public (initialize-benefits (recipient principal) (monthly-amount uint))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)

    (map-set benefits
      {recipient: recipient}
      {
        balance: monthly-amount,
        monthly-allocation: monthly-amount,
        last-issuance: block-height,
        total-received: monthly-amount
      }
    )
    (ok true)
  )
)

(define-public (issue-monthly-benefits (recipient principal))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? benefits {recipient: recipient})) ERR_RECIPIENT_NOT_FOUND)

    (let (
      (benefit-data (unwrap-panic (map-get? benefits {recipient: recipient})))
      (current-block block-height)
      (last-issue (get last-issuance benefit-data))
    )
      ;; Check if enough time has passed since last issuance
      (asserts! (>= (- current-block last-issue) BLOCKS_PER_MONTH) ERR_ALREADY_ISSUED_THIS_MONTH)

      (map-set benefits
        {recipient: recipient}
        {
          balance: (+ (get balance benefit-data) (get monthly-allocation benefit-data)),
          monthly-allocation: (get monthly-allocation benefit-data),
          last-issuance: current-block,
          total-received: (+ (get total-received benefit-data) (get monthly-allocation benefit-data))
        }
      )
      (ok true)
    )
  )
)

(define-public (update-monthly-allocation (recipient principal) (new-amount uint))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? benefits {recipient: recipient})) ERR_RECIPIENT_NOT_FOUND)

    (let ((benefit-data (unwrap-panic (map-get? benefits {recipient: recipient}))))
      (map-set benefits
        {recipient: recipient}
        (merge benefit-data {monthly-allocation: new-amount})
      )
    )
    (ok true)
  )
)

(define-public (use-benefits (recipient principal) (amount uint))
  (begin
    (asserts! (is-some (map-get? benefits {recipient: recipient})) ERR_RECIPIENT_NOT_FOUND)

    (let ((benefit-data (unwrap-panic (map-get? benefits {recipient: recipient}))))
      (asserts! (>= (get balance benefit-data) amount) ERR_INSUFFICIENT_BALANCE)

      (map-set benefits
        {recipient: recipient}
        (merge benefit-data {balance: (- (get balance benefit-data) amount)})
      )
      (ok true)
    )
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (var-set admin new-admin)
    (ok true)
  )
)
