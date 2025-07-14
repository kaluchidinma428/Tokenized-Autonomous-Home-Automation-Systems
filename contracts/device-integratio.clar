;; device-integration.clar

;; This contract allows for the integration of various devices
;; with the Stacks blockchain. It provides functionality to
;; register devices, update their status, and query their information.

(define-constant ERR-DEVICE-ALREADY-REGISTERED (err u100))
(define-constant ERR-DEVICE-NOT-FOUND (err u101))
(define-constant ERR-UNAUTHORIZED (err u102))
(define-constant ERR-INVALID-DEVICE-TYPE (err u103))

;; Data Maps

(define-map devices
  ((device-id principal))
  { device-type: uint,
    owner: principal,
    status: bool
  }
)

;; Public Functions

;; Registers a new device.
(define-public (register-device (device-id principal) (device-type uint))
  (begin
    (asserts! (is-eq (map-get? devices { device-id: device-id }) none) ERR-DEVICE-ALREADY-REGISTERED)
    (asserts! (and (>= device-type u1) (<= device-type u5)) ERR-INVALID-DEVICE-TYPE)
    (map-insert devices { device-id: device-id }
      { device-type: device-type,
        owner: tx-sender,
        status: false
      }
    )
    (ok true)
  )
)

;; Updates the status of a device.
(define-public (update-device-status (device-id principal) (new-status bool))
  (let ((device (map-get? devices { device-id: device-id })))
    (match device
      device-data
      (begin
        (asserts! (is-eq (get owner device-data) tx-sender) ERR-UNAUTHORIZED)
        (map-set devices { device-id: device-id }
          { device-type: (get device-type device-data),
            owner: (get owner device-data),
            status: new-status
          }
        )
        (ok true)
      )
      (err ERR-DEVICE-NOT-FOUND)
    )
  )
)

;; Read-Only Functions

;; Retrieves device information.
(define-read-only (get-device-info (device-id principal))
  (map-get? devices { device-id: device-id })
)

;; Checks if a device is registered.
(define-read-only (is-device-registered (device-id principal))
  (is-some (map-get? devices { device-id: device-id }))
)
