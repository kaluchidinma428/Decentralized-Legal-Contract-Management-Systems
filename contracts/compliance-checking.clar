;; Compliance Checking Contract
;; Checks contract legal compliance

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-not-found (err u501))
(define-constant err-invalid-rule (err u502))

;; Compliance rule types
(define-constant rule-type-mandatory u1)
(define-constant rule-type-prohibited u2)
(define-constant rule-type-conditional u3)

;; Data structures
(define-map compliance-rules
  { rule-id: uint }
  {
    name: (string-ascii 100),
    jurisdiction: (string-ascii 50),
    rule-type: uint,
    description: (string-ascii 200),
    active: bool,
    created-by: principal,
    created-at: uint
  }
)

(define-map contract-compliance
  { contract-hash: (buff 32) }
  {
    checked: bool,
    compliant: bool,
    checked-by: principal,
    checked-at: uint,
    violations: (list 10 uint)
  }
)

(define-map rule-violations
  { contract-hash: (buff 32), rule-id: uint }
  { violated: bool, severity: uint }
)

(define-data-var next-rule-id uint u1)

;; Public functions
(define-public (add-compliance-rule (name (string-ascii 100)) (jurisdiction (string-ascii 50)) (rule-type uint) (description (string-ascii 200)))
  (let ((rule-id (var-get next-rule-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= rule-type rule-type-conditional) err-invalid-rule)
    (map-set compliance-rules
      { rule-id: rule-id }
      {
        name: name,
        jurisdiction: jurisdiction,
        rule-type: rule-type,
        description: description,
        active: true,
        created-by: tx-sender,
        created-at: block-height
      }
    )
    (var-set next-rule-id (+ rule-id u1))
    (ok rule-id)
  )
)

(define-public (check-contract-compliance (contract-hash (buff 32)) (violations (list 10 uint)))
  (begin
    ;; Only verified law firms should be able to perform compliance checks
    (map-set contract-compliance
      { contract-hash: contract-hash }
      {
        checked: true,
        compliant: (is-eq (len violations) u0),
        checked-by: tx-sender,
        checked-at: block-height,
        violations: violations
      }
    )
    (ok (is-eq (len violations) u0))
  )
)

(define-public (report-violation (contract-hash (buff 32)) (rule-id uint) (severity uint))
  (match (map-get? compliance-rules { rule-id: rule-id })
    rule-data (begin
      (asserts! (get active rule-data) err-not-found)
      (map-set rule-violations
        { contract-hash: contract-hash, rule-id: rule-id }
        { violated: true, severity: severity }
      )
      (ok true)
    )
    err-not-found
  )
)

;; Read-only functions
(define-read-only (get-compliance-rule (rule-id uint))
  (map-get? compliance-rules { rule-id: rule-id })
)

(define-read-only (get-contract-compliance (contract-hash (buff 32)))
  (map-get? contract-compliance { contract-hash: contract-hash })
)

(define-read-only (is-contract-compliant (contract-hash (buff 32)))
  (match (map-get? contract-compliance { contract-hash: contract-hash })
    compliance-data (and (get checked compliance-data) (get compliant compliance-data))
    false
  )
)

(define-read-only (get-violation (contract-hash (buff 32)) (rule-id uint))
  (map-get? rule-violations { contract-hash: contract-hash, rule-id: rule-id })
)
