;; Usage Tracking Contract
;; This contract monitors actual transportation utilization

(define-data-var admin principal tx-sender)

;; Data structures
(define-map usage-records
  { recipient: principal }
  {
    total-trips: uint,
    total-spent: uint,
    last-trip-time: uint,
    trip-history: (list 10 {time: uint, amount: uint, route: (string-utf8 32)})
  }
)

(define-map transit-routes
  { route-id: (string-utf8 32) }
  {
    name: (string-utf8 64),
    base-fare: uint,
    active: bool
  }
)

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ROUTE_NOT_FOUND (err u101))
(define-constant ERR_ROUTE_INACTIVE (err u102))

;; Read-only functions
(define-read-only (is-admin)
  (is-eq tx-sender (var-get admin))
)

(define-read-only (get-usage-record (recipient principal))
  (map-get? usage-records {recipient: recipient})
)

(define-read-only (get-route-info (route-id (string-utf8 32)))
  (map-get? transit-routes {route-id: route-id})
)

;; Public functions
(define-public (initialize-usage-record (recipient principal))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)

    (map-set usage-records
      {recipient: recipient}
      {
        total-trips: u0,
        total-spent: u0,
        last-trip-time: u0,
        trip-history: (list)
      }
    )
    (ok true)
  )
)

(define-public (add-transit-route (route-id (string-utf8 32)) (name (string-utf8 64)) (base-fare uint))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)

    (map-set transit-routes
      {route-id: route-id}
      {
        name: name,
        base-fare: base-fare,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (update-route-status (route-id (string-utf8 32)) (active bool))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? transit-routes {route-id: route-id})) ERR_ROUTE_NOT_FOUND)

    (let ((route-data (unwrap-panic (map-get? transit-routes {route-id: route-id}))))
      (map-set transit-routes
        {route-id: route-id}
        (merge route-data {active: active})
      )
    )
    (ok true)
  )
)

(define-public (record-trip (recipient principal) (route-id (string-utf8 32)) (amount uint))
  (begin
    (asserts! (is-some (map-get? transit-routes {route-id: route-id})) ERR_ROUTE_NOT_FOUND)

    (let (
      (route-data (unwrap-panic (map-get? transit-routes {route-id: route-id})))
      (usage-data (default-to
        {total-trips: u0, total-spent: u0, last-trip-time: u0, trip-history: (list)}
        (map-get? usage-records {recipient: recipient})
      ))
    )
      ;; Check if route is active
      (asserts! (get active route-data) ERR_ROUTE_INACTIVE)

      ;; Create new trip record
      (let (
        (new-trip {time: block-height, amount: amount, route: route-id})
        (updated-history (unwrap-panic (as-max-len? (append (get trip-history usage-data) new-trip) u10)))
      )
        (map-set usage-records
          {recipient: recipient}
          {
            total-trips: (+ (get total-trips usage-data) u1),
            total-spent: (+ (get total-spent usage-data) amount),
            last-trip-time: block-height,
            trip-history: updated-history
          }
        )
        (ok true)
      )
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
