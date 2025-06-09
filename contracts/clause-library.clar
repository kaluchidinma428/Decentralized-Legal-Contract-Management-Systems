;; Clause Library Contract
;; Maintains standardized legal clauses

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-already-exists (err u302))

;; Data structures
(define-map legal-clauses
  { clause-id: uint }
  {
    title: (string-ascii 100),
    category: (string-ascii 50),
    content-hash: (buff 32),
    jurisdiction: (string-ascii 50),
    approved: bool,
    created-by: principal,
    created-at: uint,
    usage-count: uint
  }
)

(define-map clause-tags
  { clause-id: uint, tag: (string-ascii 30) }
  { tagged: bool }
)

(define-data-var next-clause-id uint u1)

;; Public functions
(define-public (add-clause (title (string-ascii 100)) (category (string-ascii 50)) (content-hash (buff 32)) (jurisdiction (string-ascii 50)))
  (let ((clause-id (var-get next-clause-id)))
    (map-set legal-clauses
      { clause-id: clause-id }
      {
        title: title,
        category: category,
        content-hash: content-hash,
        jurisdiction: jurisdiction,
        approved: false,
        created-by: tx-sender,
        created-at: block-height,
        usage-count: u0
      }
    )
    (var-set next-clause-id (+ clause-id u1))
    (ok clause-id)
  )
)

(define-public (approve-clause (clause-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? legal-clauses { clause-id: clause-id })
      clause-data (begin
        (map-set legal-clauses
          { clause-id: clause-id }
          (merge clause-data { approved: true })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

(define-public (tag-clause (clause-id uint) (tag (string-ascii 30)))
  (match (map-get? legal-clauses { clause-id: clause-id })
    clause-data (begin
      (map-set clause-tags
        { clause-id: clause-id, tag: tag }
        { tagged: true }
      )
      (ok true)
    )
    err-not-found
  )
)

(define-public (use-clause (clause-id uint))
  (match (map-get? legal-clauses { clause-id: clause-id })
    clause-data (begin
      (asserts! (get approved clause-data) err-not-found)
      (map-set legal-clauses
        { clause-id: clause-id }
        (merge clause-data { usage-count: (+ (get usage-count clause-data) u1) })
      )
      (ok (get content-hash clause-data))
    )
    err-not-found
  )
)

;; Read-only functions
(define-read-only (get-clause (clause-id uint))
  (map-get? legal-clauses { clause-id: clause-id })
)

(define-read-only (is-clause-tagged (clause-id uint) (tag (string-ascii 30)))
  (match (map-get? clause-tags { clause-id: clause-id, tag: tag })
    tag-data (get tagged tag-data)
    false
  )
)
