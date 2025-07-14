;; energy-optimization.clar

;; This contract simulates a basic energy optimization system.
;; It allows users to submit energy consumption data, and the contract
;; calculates an optimization score based on predefined parameters.

(define-constant ERR-INVALID-DATA (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-ALREADY-SUBMITTED (err u102))

(define-map user-data
  { user: principal, date: uint }
  { energy-consumption: uint, optimization-score: uint }
)

(define-read-only (is-valid-data (energy-consumption uint))
  (if (and (< energy-consumption u1000) (> energy-consumption u0))
      true
      false)
)

(define-read-only (calculate-optimization-score (energy-consumption uint))
  (let ((base-score (- u1000 energy-consumption)))
    (if (> base-score u500)
        u500
        base-score)
  )
)

(define-public (submit-data (energy-consumption uint) (date uint))
  (begin
    (asserts! (is-valid-data energy-consumption) ERR-INVALID-DATA)
    (asserts! (not (map-get? user-data { user: tx-sender, date: date })) ERR-ALREADY-SUBMITTED)

    (let ((optimization-score (calculate-optimization-score energy-consumption)))
      (map-insert user-data { user: tx-sender, date: date } { energy-consumption: energy-consumption, optimization-score: optimization-score })
      (ok optimization-score)
    )
  )
)

(define-read-only (get-user-data (user principal) (date uint))
  (match (map-get? user-data { user: user, date: date })
    some(data) data
    none { energy-consumption: u0, optimization-score: u0 }
  )
)
