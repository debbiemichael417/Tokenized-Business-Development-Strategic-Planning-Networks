;; Implementation Planning Contract
;; Manages detailed implementation plans for approved strategies

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-PLAN-NOT-FOUND (err u301))
(define-constant ERR-INVALID-INPUT (err u302))
(define-constant ERR-STRATEGY-NOT-APPROVED (err u303))
(define-constant ERR-PHASE-NOT-FOUND (err u304))

;; Data Variables
(define-data-var next-plan-id uint u1)
(define-data-var next-phase-id uint u1)

;; Data Maps
(define-map implementation-plans
  { plan-id: uint }
  {
    strategy-id: uint,
    planner-id: uint,
    plan-title: (string-ascii 200),
    total-phases: uint,
    estimated-duration: uint,
    total-budget: uint,
    start-date: uint,
    status: (string-ascii 20),
    creation-block: uint,
    last-updated: uint
  }
)

(define-map implementation-phases
  { phase-id: uint }
  {
    plan-id: uint,
    phase-number: uint,
    phase-title: (string-ascii 200),
    description: (string-ascii 1000),
    action-items: (list 20 (string-ascii 200)),
    dependencies: (list 5 uint),
    assigned-resources: (list 10 (string-ascii 100)),
    phase-budget: uint,
    estimated-duration: uint,
    start-block: uint,
    end-block: uint,
    completion-percentage: uint,
    status: (string-ascii 20)
  }
)

(define-map phase-milestones
  { phase-id: uint, milestone-id: uint }
  {
    milestone-title: (string-ascii 200),
    description: (string-ascii 500),
    target-date: uint,
    completion-date: uint,
    is-completed: bool,
    completion-criteria: (string-ascii 500)
  }
)

;; Public Functions

;; Create implementation plan
(define-public (create-implementation-plan
  (strategy-id uint)
  (planner-id uint)
  (plan-title (string-ascii 200))
  (total-phases uint)
  (estimated-duration uint)
  (total-budget uint)
  (start-date uint))
  (let
    (
      (plan-id (var-get next-plan-id))
    )
    (asserts! (> (len plan-title) u0) ERR-INVALID-INPUT)
    (asserts! (> total-phases u0) ERR-INVALID-INPUT)
    (asserts! (<= total-phases u20) ERR-INVALID-INPUT)
    (asserts! (> estimated-duration u0) ERR-INVALID-INPUT)
    (asserts! (> start-date block-height) ERR-INVALID-INPUT)

    ;; Store implementation plan
    (map-set implementation-plans
      { plan-id: plan-id }
      {
        strategy-id: strategy-id,
        planner-id: planner-id,
        plan-title: plan-title,
        total-phases: total-phases,
        estimated-duration: estimated-duration,
        total-budget: total-budget,
        start-date: start-date,
        status: "planning",
        creation-block: block-height,
        last-updated: block-height
      }
    )

    ;; Increment next plan ID
    (var-set next-plan-id (+ plan-id u1))

    (ok plan-id)
  )
)

;; Create implementation phase
(define-public (create-implementation-phase
  (plan-id uint)
  (phase-number uint)
  (phase-title (string-ascii 200))
  (description (string-ascii 1000))
  (action-items (list 20 (string-ascii 200)))
  (dependencies (list 5 uint))
  (assigned-resources (list 10 (string-ascii 100)))
  (phase-budget uint)
  (estimated-duration uint))
  (let
    (
      (phase-id (var-get next-phase-id))
      (plan-data (unwrap! (map-get? implementation-plans { plan-id: plan-id }) ERR-PLAN-NOT-FOUND))
    )
    (asserts! (> (len phase-title) u0) ERR-INVALID-INPUT)
    (asserts! (> phase-number u0) ERR-INVALID-INPUT)
    (asserts! (<= phase-number (get total-phases plan-data)) ERR-INVALID-INPUT)
    (asserts! (> estimated-duration u0) ERR-INVALID-INPUT)

    ;; Store implementation phase
    (map-set implementation-phases
      { phase-id: phase-id }
      {
        plan-id: plan-id,
        phase-number: phase-number,
        phase-title: phase-title,
        description: description,
        action-items: action-items,
        dependencies: dependencies,
        assigned-resources: assigned-resources,
        phase-budget: phase-budget,
        estimated-duration: estimated-duration,
        start-block: u0,
        end-block: u0,
        completion-percentage: u0,
        status: "planned"
      }
    )

    ;; Increment next phase ID
    (var-set next-phase-id (+ phase-id u1))

    (ok phase-id)
  )
)

;; Start implementation phase
(define-public (start-phase (phase-id uint))
  (let
    (
      (phase-data (unwrap! (map-get? implementation-phases { phase-id: phase-id }) ERR-PHASE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status phase-data) "planned") ERR-INVALID-INPUT)

    (map-set implementation-phases
      { phase-id: phase-id }
      (merge phase-data {
        start-block: block-height,
        status: "in-progress"
      })
    )

    (ok true)
  )
)

;; Update phase progress
(define-public (update-phase-progress (phase-id uint) (completion-percentage uint))
  (let
    (
      (phase-data (unwrap! (map-get? implementation-phases { phase-id: phase-id }) ERR-PHASE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= completion-percentage u100) ERR-INVALID-INPUT)

    (map-set implementation-phases
      { phase-id: phase-id }
      (merge phase-data {
        completion-percentage: completion-percentage,
        status: (if (is-eq completion-percentage u100) "completed" "in-progress")
      })
    )

    (ok true)
  )
)

;; Complete implementation phase
(define-public (complete-phase (phase-id uint))
  (let
    (
      (phase-data (unwrap! (map-get? implementation-phases { phase-id: phase-id }) ERR-PHASE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status phase-data) "in-progress") ERR-INVALID-INPUT)

    (map-set implementation-phases
      { phase-id: phase-id }
      (merge phase-data {
        end-block: block-height,
        completion-percentage: u100,
        status: "completed"
      })
    )

    (ok true)
  )
)

;; Add phase milestone
(define-public (add-phase-milestone
  (phase-id uint)
  (milestone-id uint)
  (milestone-title (string-ascii 200))
  (description (string-ascii 500))
  (target-date uint)
  (completion-criteria (string-ascii 500)))
  (begin
    (asserts! (is-some (map-get? implementation-phases { phase-id: phase-id })) ERR-PHASE-NOT-FOUND)
    (asserts! (> (len milestone-title) u0) ERR-INVALID-INPUT)
    (asserts! (> target-date block-height) ERR-INVALID-INPUT)

    (map-set phase-milestones
      { phase-id: phase-id, milestone-id: milestone-id }
      {
        milestone-title: milestone-title,
        description: description,
        target-date: target-date,
        completion-date: u0,
        is-completed: false,
        completion-criteria: completion-criteria
      }
    )

    (ok true)
  )
)

;; Complete milestone
(define-public (complete-milestone (phase-id uint) (milestone-id uint))
  (let
    (
      (milestone-data (unwrap! (map-get? phase-milestones { phase-id: phase-id, milestone-id: milestone-id }) ERR-INVALID-INPUT))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (get is-completed milestone-data)) ERR-INVALID-INPUT)

    (map-set phase-milestones
      { phase-id: phase-id, milestone-id: milestone-id }
      (merge milestone-data {
        completion-date: block-height,
        is-completed: true
      })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get implementation plan
(define-read-only (get-implementation-plan (plan-id uint))
  (map-get? implementation-plans { plan-id: plan-id })
)

;; Get implementation phase
(define-read-only (get-implementation-phase (phase-id uint))
  (map-get? implementation-phases { phase-id: phase-id })
)

;; Get phase milestone
(define-read-only (get-phase-milestone (phase-id uint) (milestone-id uint))
  (map-get? phase-milestones { phase-id: phase-id, milestone-id: milestone-id })
)

;; Get next plan ID
(define-read-only (get-next-plan-id)
  (var-get next-plan-id)
)

;; Get next phase ID
(define-read-only (get-next-phase-id)
  (var-get next-phase-id)
)
