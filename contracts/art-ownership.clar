;; Define the non-fungible token for artwork
(define-non-fungible-token artwork uint)

;; Define data maps for artwork details and ownership shares
(define-map artwork-details uint {
    title: (string-ascii 100),
    artist: principal,
    total-shares: uint,
    price-per-share: uint,
    created-at: uint
})

(define-map ownership-shares { artwork-id: uint, owner: principal } uint)

;; Error codes
(define-constant err-not-authorized (err u100))
(define-constant err-artwork-exists (err u101))
(define-constant err-invalid-shares (err u102))
(define-constant err-insufficient-shares (err u103))
(define-constant err-artwork-not-found (err u104))

;; Data variables
(define-data-var next-artwork-id uint u1)

;; Register new artwork
(define-public (register-artwork (title (string-ascii 100)) (total-shares uint) (price-per-share uint))
    (let 
        ((artwork-id (var-get next-artwork-id)))
        (asserts! (> total-shares u0) err-invalid-shares)
        (try! (nft-mint? artwork artwork-id tx-sender))
        (map-set artwork-details artwork-id {
            title: title,
            artist: tx-sender,
            total-shares: total-shares,
            price-per-share: price-per-share,
            created-at: block-height
        })
        (map-set ownership-shares {artwork-id: artwork-id, owner: tx-sender} total-shares)
        (var-set next-artwork-id (+ artwork-id u1))
        (ok artwork-id)
    )
)

;; Transfer shares
(define-public (transfer-shares (artwork-id uint) (recipient principal) (shares uint))
    (let 
        ((sender-shares (default-to u0 (map-get? ownership-shares {artwork-id: artwork-id, owner: tx-sender}))))
        (asserts! (>= sender-shares shares) err-insufficient-shares)
        (map-set ownership-shares {artwork-id: artwork-id, owner: tx-sender} (- sender-shares shares))
        (map-set ownership-shares 
            {artwork-id: artwork-id, owner: recipient} 
            (+ shares (default-to u0 (map-get? ownership-shares {artwork-id: artwork-id, owner: recipient})))
        )
        (ok true)
    )
)

;; Get artwork details
(define-read-only (get-artwork-details (artwork-id uint))
    (ok (map-get? artwork-details artwork-id))
)

;; Get shares owned by principal
(define-read-only (get-shares (artwork-id uint) (owner principal))
    (ok (default-to u0 (map-get? ownership-shares {artwork-id: artwork-id, owner: owner})))
)

;; Check if principal has any shares
(define-read-only (has-shares (artwork-id uint) (owner principal))
    (ok (> (default-to u0 (map-get? ownership-shares {artwork-id: artwork-id, owner: owner})) u0))
)
