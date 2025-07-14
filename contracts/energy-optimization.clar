;; Energy Optimization Contract
;; Manages automated energy systems for maximum efficiency

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u200))
(define-constant ERR_SCHEDULE_NOT_FOUND (err u201))
(define-constant ERR_INVALID_TIME (err u202))
(define-constant ERR_INVALID_ENERGY_LEVEL (err u203))
(define-constant ERR_OPTIMIZATION_FAILED (err u204))

;; Data Variables
(define-data-var next-schedule-id uint u1)
(define-data-var total-energy-saved uint u0)
(define-data-var optimization-active bool true)

;; Data Maps
(define-map energy-schedules
  { schedule-id: uint }
  {
    owner: principal,
    device-id: uint,
    start-time: uint,
    end-time: uint,
    energy-target: uint,
    priority-level: uint,
    is-active: bool,
    created-block: uint
  }
)

(define-map energy-consumption
  { device-id: uint, time-period: uint }
  {
    consumption-amount: uint,
    efficiency-rating: uint,
    cost-estimate: uint
  }
)

(define-map optimization-rules
  { rule-id: uint }
  {
    condition-type: uint,
    threshold-value: uint,
    action-type: uint,
    energy-savings: uint,
    is-enabled: bool
  }
)

(define-map daily-energy-stats
  { date: uint, owner: principal }
  {
    total-consumption: uint,
    total-savings: uint,
    efficiency-score: uint,
    peak-usage-time: uint
  }
)

;; Public Functions

;; Create energy optimization schedule
(define-public (create-energy-schedule (device-id uint) (start-time uint) (end-time uint) (energy-target uint) (priority-level uint))
  (let
    (
      (schedule-id (var-get next-schedule-id))
    )
    (asserts! (< start-time end-time) ERR_INVALID_TIME)
    (asserts! (and (>= energy-target u1) (<= energy-target u1000)) ERR_INVALID_ENERGY_LEVEL)
    (asserts! (and (>= priority-level u1) (<= priority-level u5)) (err u205))

    (map-set energy-schedules
      { schedule-id: schedule-id }
      {
        owner: tx-sender,
        device-id: device-id,
        start-time: start-time,
        end-time: end-time,
        energy-target: energy-target,
        priority-level: priority-level,
        is-active: true,
        created-block: block-height
      }
    )

    (var-set next-schedule-id (+ schedule-id u1))
    (ok schedule-id)
  )
)

;; Update energy consumption data
(define-public (update-energy-consumption (device-id uint) (time-period uint) (consumption-amount uint) (efficiency-rating uint))
  (let
    (
      (cost-estimate (* consumption-amount u15))
    )
    (asserts! (and (>= efficiency-rating u0) (<= efficiency-rating u100)) (err u206))

    (map-set energy-consumption
      { device-id: device-id, time-period: time-period }
      {
        consumption-amount: consumption-amount,
        efficiency-rating: efficiency-rating,
        cost-estimate: cost-estimate
      }
    )

    (ok true)
  )
)

;; Record daily energy statistics
(define-public (record-daily-stats (date uint) (total-consumption uint) (total-savings uint) (efficiency-score uint) (peak-usage-time uint))
  (begin
    (map-set daily-energy-stats
      { date: date, owner: tx-sender }
      {
        total-consumption: total-consumption,
        total-savings: total-savings,
        efficiency-score: efficiency-score,
        peak-usage-time: peak-usage-time
      }
    )

    (var-set total-energy-saved (+ (var-get total-energy-saved) total-savings))
    (ok true)
  )
)

;; Toggle optimization system
(define-public (toggle-optimization (active bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set optimization-active active)
    (ok active)
  )
)

;; Read-only Functions

;; Get energy schedule
(define-read-only (get-energy-schedule (schedule-id uint))
  (map-get? energy-schedules { schedule-id: schedule-id })
)

;; Get energy consumption data
(define-read-only (get-energy-consumption (device-id uint) (time-period uint))
  (map-get? energy-consumption { device-id: device-id, time-period: time-period })
)

;; Get daily energy statistics
(define-read-only (get-daily-stats (date uint) (owner principal))
  (map-get? daily-energy-stats { date: date, owner: owner })
)

;; Get total energy saved
(define-read-only (get-total-energy-saved)
  (var-get total-energy-saved)
)

;; Check if optimization is active
(define-read-only (is-optimization-active)
  (var-get optimization-active)
)

;; Calculate efficiency score for device
(define-read-only (calculate-efficiency-score (device-id uint) (time-period uint))
  (match (map-get? energy-consumption { device-id: device-id, time-period: time-period })
    consumption-data (get efficiency-rating consumption-data)
    u0
  )
)
