;; Define the non-fungible token for artwork
(define-non-fungible-token artwork uint)

;; Define data maps for artwork details and ownership shares
(define-map artwork-details uint {
    title: (string-ascii 100),
    artist: principal,
    total-shares: uint,
    price-per-share: uint,
    created-at: uint,
    royalty-percentage: uint
})

(define-map ownership-shares { artwork-id: uint, owner: principal } uint)
(define-map royalty-payments { artwork-id: uint, owner: principal } uint)
(define-map share-transfer-escrow { artwork-id: uint, from: principal, to: principal } uint)

;; Error codes
(define-constant err-not-authorized (err u100))
(define-constant err-artwork-exists (err u101))
(define-constant err-invalid-shares (err u102))
(define-constant err-insufficient-shares (err u103))
(define-constant err-artwork-not-found (err u104))
(define-constant err-invalid-royalty (err u105))
(define-constant err-payment-failed (err u106))
(define-constant err-no-escrow (err u107))

;; Data variables
(define-data-var next-artwork-id uint u1)

;; Register new artwork with royalties
(define-public (register-artwork (title (string-ascii 100)) (total-shares uint) (price-per-share uint) (royalty-percentage uint))
    (let 
        ((artwork-id (var-get next-artwork-id)))
        (asserts! (> total-shares u0) err-invalid-shares)
        (asserts! (<= royalty-percentage u100) err-invalid-royalty)
        (try! (nft-mint? artwork artwork-id tx-sender))
        (map-set artwork-details artwork-id {
            title: title,
            artist: tx-sender,
            total-shares: total-shares,
            price-per-share: price-per-share,
            created-at: block-height,
            royalty-percentage: royalty-percentage
        })
        (map-set ownership-shares {artwork-id: artwork-id, owner: tx-sender} total-shares)
        (var-set next-artwork-id (+ artwork-id u1))
        (ok artwork-id)
    )
)

;; Initialize share transfer escrow
(define-public (initiate-share-transfer (artwork-id uint) (recipient principal) (shares uint))
    (let
        ((sender-shares (default-to u0 (map-get? ownership-shares {artwork-id: artwork-id, owner: tx-sender}))))
        (asserts! (>= sender-shares shares) err-insufficient-shares)
        (map-set share-transfer-escrow 
            {artwork-id: artwork-id, from: tx-sender, to: recipient}
            shares
        )
        (ok true)
    )
)

;; Complete share transfer with royalty payment
(define-public (complete-share-transfer (artwork-id uint) (seller principal) (payment uint))
    (let 
        ((escrow-shares (unwrap! (map-get? share-transfer-escrow {artwork-id: artwork-id, from: seller, to: tx-sender}) err-no-escrow))
         (seller-shares (default-to u0 (map-get? ownership-shares {artwork-id: artwork-id, owner: seller})))
         (artwork (unwrap! (map-get? artwork-details artwork-id) err-artwork-not-found))
         (royalty-amount (/ (* payment (get royalty-percentage artwork)) u100)))
        
        ;; Process royalty payment to artist
        (try! (stx-transfer? royalty-amount tx-sender (get artist artwork)))
        
        ;; Update royalty tracking
        (map-set royalty-payments 
            {artwork-id: artwork-id, owner: (get artist artwork)}
            (+ royalty-amount (default-to u0 (map-get? royalty-payments {artwork-id: artwork-id, owner: (get artist artwork)})))
        )
        
        ;; Transfer shares
        (map-set ownership-shares {artwork-id: artwork-id, owner: seller} (- seller-shares escrow-shares))
        (map-set ownership-shares 
            {artwork-id: artwork-id, owner: tx-sender} 
            (+ escrow-shares (default-to u0 (map-get? ownership-shares {artwork-id: artwork-id, owner: tx-sender})))
        )
        
        ;; Clear escrow
        (map-delete share-transfer-escrow {artwork-id: artwork-id, from: seller, to: tx-sender})
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

;; Get total royalties earned
(define-read-only (get-royalties-earned (artwork-id uint) (owner principal))
    (ok (default-to u0 (map-get? royalty-payments {artwork-id: artwork-id, owner: owner})))
)

;; Check if principal has any shares
(define-read-only (has-shares (artwork-id uint) (owner principal))
    (ok (> (default-to u0 (map-get? ownership-shares {artwork-id: artwork-id, owner: owner})) u0))
)
