;; Art Ownership Contract with Enhanced Metadata and Events

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-SHARE-PRICE u1000000) ;; 1 STX minimum
(define-constant MAX-URI-LENGTH u256)

;; Error codes
(define-constant err-not-authorized (err u100))
(define-constant err-artwork-exists (err u101))
(define-constant err-invalid-shares (err u102))
(define-constant err-insufficient-shares (err u103))
(define-constant err-artwork-not-found (err u104))
(define-constant err-invalid-royalty (err u105))
(define-constant err-payment-failed (err u106))
(define-constant err-no-escrow (err u107))
(define-constant err-invalid-price (err u108))
(define-constant err-invalid-uri (err u109))

;; Define the non-fungible token for artwork
(define-non-fungible-token artwork uint)

;; Define data maps
(define-map artwork-details uint {
    title: (string-ascii 100),
    artist: principal,
    total-shares: uint,
    price-per-share: uint,
    created-at: uint,
    royalty-percentage: uint,
    metadata-uri: (optional (string-utf8 256))
})

(define-map ownership-shares { artwork-id: uint, owner: principal } uint)
(define-map royalty-payments { artwork-id: uint, owner: principal } uint)
(define-map share-transfer-escrow { artwork-id: uint, from: principal, to: principal } uint)

;; Data variables
(define-data-var next-artwork-id uint u1)

;; Events
(define-public (print-artwork-registered (artwork-id uint) (artist principal))
    (ok (print { event: "artwork-registered", artwork-id: artwork-id, artist: artist })))

(define-public (print-shares-transferred (artwork-id uint) (from principal) (to principal) (amount uint))
    (ok (print { event: "shares-transferred", artwork-id: artwork-id, from: from, to: to, amount: amount })))

;; Register new artwork with royalties and metadata
(define-public (register-artwork 
    (title (string-ascii 100)) 
    (total-shares uint) 
    (price-per-share uint) 
    (royalty-percentage uint)
    (metadata-uri (optional (string-utf8 256))))
    (let 
        ((artwork-id (var-get next-artwork-id)))
        
        ;; Input validation
        (asserts! (> total-shares u0) err-invalid-shares)
        (asserts! (<= royalty-percentage u100) err-invalid-royalty)
        (asserts! (>= price-per-share MIN-SHARE-PRICE) err-invalid-price)
        (asserts! (match metadata-uri uri
            (< (len uri) MAX-URI-LENGTH)
            true) err-invalid-uri)
        
        ;; Mint NFT and set details
        (try! (nft-mint? artwork artwork-id tx-sender))
        (map-set artwork-details artwork-id {
            title: title,
            artist: tx-sender,
            total-shares: total-shares,
            price-per-share: price-per-share,
            created-at: block-height,
            royalty-percentage: royalty-percentage,
            metadata-uri: metadata-uri
        })
        
        ;; Set initial ownership
        (map-set ownership-shares {artwork-id: artwork-id, owner: tx-sender} total-shares)
        (var-set next-artwork-id (+ artwork-id u1))
        
        ;; Emit event
        (try! (print-artwork-registered artwork-id tx-sender))
        (ok artwork-id)
    )
)

[... rest of the contract with similar enhancements ...]
