;; Device Integration Contract
;; Manages smart home device registration and tokenization

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DEVICE_NOT_FOUND (err u101))
(define-constant ERR_DEVICE_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_DEVICE_TYPE (err u103))
(define-constant ERR_DEVICE_OFFLINE (err u104))

;; Data Variables
(define-data-var next-device-id uint u1)
(define-data-var total-devices uint u0)

;; Data Maps
(define-map devices
  { device-id: uint }
  {
    owner: principal,
    device-type: uint,
    name: (string-ascii 50),
    status: uint,
    compatibility-score: uint,
    registration-block: uint,
    last-update: uint
  }
)

(define-map device-tokens
  { device-id: uint }
  {
    token-id: uint,
    is-active: bool,
    permissions: uint
  }
)

(define-map user-devices
  { owner: principal, device-id: uint }
  { is-owner: bool }
)

(define-map device-compatibility
  { device-type-a: uint, device-type-b: uint }
  { compatibility-rating: uint }
)

;; Public Functions

;; Register a new smart device
(define-public (register-device (device-type uint) (name (string-ascii 50)))
  (let
    (
      (device-id (var-get next-device-id))
      (current-block block-height)
    )
    (asserts! (and (>= device-type u1) (<= device-type u5)) ERR_INVALID_DEVICE_TYPE)
    (asserts! (is-none (map-get? devices { device-id: device-id })) ERR_DEVICE_ALREADY_EXISTS)

    (map-set devices
      { device-id: device-id }
      {
        owner: tx-sender,
        device-type: device-type,
        name: name,
        status: u1,
        compatibility-score: u100,
        registration-block: current-block,
        last-update: current-block
      }
    )

    (map-set device-tokens
      { device-id: device-id }
      {
        token-id: device-id,
        is-active: true,
        permissions: u255
      }
    )

    (map-set user-devices
      { owner: tx-sender, device-id: device-id }
      { is-owner: true }
    )

    (var-set next-device-id (+ device-id u1))
    (var-set total-devices (+ (var-get total-devices) u1))

    (ok device-id)
  )
)

;; Update device status
(define-public (update-device-status (device-id uint) (new-status uint))
  (let
    (
      (device (unwrap! (map-get? devices { device-id: device-id }) ERR_DEVICE_NOT_FOUND))
    )
    (asserts! (is-eq (get owner device) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= new-status u0) (<= new-status u3)) (err u105))

    (map-set devices
      { device-id: device-id }
      (merge device {
        status: new-status,
        last-update: block-height
      })
    )

    (ok true)
  )
)

;; Transfer device ownership
(define-public (transfer-device (device-id uint) (new-owner principal))
  (let
    (
      (device (unwrap! (map-get? devices { device-id: device-id }) ERR_DEVICE_NOT_FOUND))
    )
    (asserts! (is-eq (get owner device) tx-sender) ERR_NOT_AUTHORIZED)

    (map-delete user-devices { owner: tx-sender, device-id: device-id })
    (map-set user-devices
      { owner: new-owner, device-id: device-id }
      { is-owner: true }
    )

    (map-set devices
      { device-id: device-id }
      (merge device {
        owner: new-owner,
        last-update: block-height
      })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get device information
(define-read-only (get-device (device-id uint))
  (map-get? devices { device-id: device-id })
)

;; Get device token information
(define-read-only (get-device-token (device-id uint))
  (map-get? device-tokens { device-id: device-id })
)

;; Check if user owns device
(define-read-only (is-device-owner (owner principal) (device-id uint))
  (default-to false (get is-owner (map-get? user-devices { owner: owner, device-id: device-id })))
)

;; Get compatibility rating between device types
(define-read-only (get-compatibility (device-type-a uint) (device-type-b uint))
  (default-to u50 (get compatibility-rating (map-get? device-compatibility { device-type-a: device-type-a, device-type-b: device-type-b })))
)

;; Get total number of devices
(define-read-only (get-total-devices)
  (var-get total-devices)
)

;; Get next device ID
(define-read-only (get-next-device-id)
  (var-get next-device-id)
)
