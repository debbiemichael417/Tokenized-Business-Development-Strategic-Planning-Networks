;; Performance Measurement Contract
;; Measures strategy performance using predefined KPIs and generates reports

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-MEASUREMENT-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-REPORT-NOT-FOUND (err u503))

;; Data Variables
(define-data-var next-measurement-id uint u1)
(define-data-var next-report-id uint u1)

;; Data Maps
(define-map performance-measurements
  { measurement-id: uint }
  {
    strategy-id: uint,
    monitor-id: uint,
    measurement-title: (string-ascii 200),
    kpi-definitions: (list 15 (string-ascii 200)),
    measurement-periods: (list 12 uint),
    baseline-metrics: (list 15 uint),
    target-metrics: (list 15 uint),
    actual-metrics: (list 15 uint),
    roi-calculation: uint,
    efficiency-score: uint,
    success-rate: uint,
    creation-block: uint,
    last-calculated: uint
  }
)

(define-map performance-reports
  { report-id: uint }
  {
    measurement-id: uint,
    report-period: uint,
    overall-performance: uint,
    kpi-achievements: (list 15 uint),
    roi-analysis: (string-ascii 1000),
    efficiency-analysis: (string-ascii 1000),
    success-factors: (list 10 (string-ascii 200)),
    improvement-areas: (list 10 (string-ascii 200)),
    recommendations: (string-ascii 1000),
    next-actions: (list 5 (string-ascii 200)),
    report-date: uint,
    generated-by: principal
  }
)

(define-map kpi-benchmarks
  { measurement-id: uint, kpi-index: uint }
  {
    industry-benchmark: uint,
    internal-benchmark: uint,
    best-practice-benchmark: uint,
    performance-rating: (string-ascii 20)
  }
)

(define-map performance-trends
  { measurement-id: uint, period: uint }
  {
    trend-direction: (string-ascii 20),
    growth-rate: uint,
    volatility-index: uint,
    predictive-score: uint,
    confidence-level: uint
  }
)

;; Public Functions

;; Create performance measurement
(define-public (create-performance-measurement
  (strategy-id uint)
  (monitor-id uint)
  (measurement-title (string-ascii 200))
  (kpi-definitions (list 15 (string-ascii 200)))
  (measurement-periods (list 12 uint))
  (baseline-metrics (list 15 uint))
  (target-metrics (list 15 uint)))
  (let
    (
      (measurement-id (var-get next-measurement-id))
    )
    (asserts! (> (len measurement-title) u0) ERR-INVALID-INPUT)
    (asserts! (is-eq (len kpi-definitions) (len baseline-metrics)) ERR-INVALID-INPUT)
    (asserts! (is-eq (len baseline-metrics) (len target-metrics)) ERR-INVALID-INPUT)

    ;; Store performance measurement
    (map-set performance-measurements
      { measurement-id: measurement-id }
      {
        strategy-id: strategy-id,
        monitor-id: monitor-id,
        measurement-title: measurement-title,
        kpi-definitions: kpi-definitions,
        measurement-periods: measurement-periods,
        baseline-metrics: baseline-metrics,
        target-metrics: target-metrics,
        actual-metrics: baseline-metrics,
        roi-calculation: u0,
        efficiency-score: u0,
        success-rate: u0,
        creation-block: block-height,
        last-calculated: block-height
      }
    )

    ;; Increment next measurement ID
    (var-set next-measurement-id (+ measurement-id u1))

    (ok measurement-id)
  )
)

;; Update performance metrics
(define-public (update-performance-metrics (measurement-id uint) (actual-metrics (list 15 uint)))
  (let
    (
      (measurement-data (unwrap! (map-get? performance-measurements { measurement-id: measurement-id }) ERR-MEASUREMENT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (len actual-metrics) (len (get baseline-metrics measurement-data))) ERR-INVALID-INPUT)

    (map-set performance-measurements
      { measurement-id: measurement-id }
      (merge measurement-data {
        actual-metrics: actual-metrics,
        last-calculated: block-height
      })
    )

    (ok true)
  )
)

;; Calculate ROI and efficiency
(define-public (calculate-performance-scores (measurement-id uint) (investment-amount uint) (return-amount uint))
  (let
    (
      (measurement-data (unwrap! (map-get? performance-measurements { measurement-id: measurement-id }) ERR-MEASUREMENT-NOT-FOUND))
      (roi (if (> investment-amount u0) (/ (* (- return-amount investment-amount) u100) investment-amount) u0))
      (efficiency (calculate-efficiency-score measurement-id))
      (success (calculate-success-rate measurement-id))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> investment-amount u0) ERR-INVALID-INPUT)

    (map-set performance-measurements
      { measurement-id: measurement-id }
      (merge measurement-data {
        roi-calculation: roi,
        efficiency-score: efficiency,
        success-rate: success,
        last-calculated: block-height
      })
    )

    (ok { roi: roi, efficiency: efficiency, success-rate: success })
  )
)

;; Generate performance report
(define-public (generate-performance-report
  (measurement-id uint)
  (report-period uint)
  (roi-analysis (string-ascii 1000))
  (efficiency-analysis (string-ascii 1000))
  (success-factors (list 10 (string-ascii 200)))
  (improvement-areas (list 10 (string-ascii 200)))
  (recommendations (string-ascii 1000))
  (next-actions (list 5 (string-ascii 200))))
  (let
    (
      (report-id (var-get next-report-id))
      (measurement-data (unwrap! (map-get? performance-measurements { measurement-id: measurement-id }) ERR-MEASUREMENT-NOT-FOUND))
      (overall-perf (calculate-overall-performance measurement-id))
      (kpi-achievements (calculate-kpi-achievements measurement-id))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set performance-reports
      { report-id: report-id }
      {
        measurement-id: measurement-id,
        report-period: report-period,
        overall-performance: overall-perf,
        kpi-achievements: kpi-achievements,
        roi-analysis: roi-analysis,
        efficiency-analysis: efficiency-analysis,
        success-factors: success-factors,
        improvement-areas: improvement-areas,
        recommendations: recommendations,
        next-actions: next-actions,
        report-date: block-height,
        generated-by: tx-sender
      }
    )

    ;; Increment next report ID
    (var-set next-report-id (+ report-id u1))

    (ok report-id)
  )
)

;; Set KPI benchmarks
(define-public (set-kpi-benchmarks
  (measurement-id uint)
  (kpi-index uint)
  (industry-benchmark uint)
  (internal-benchmark uint)
  (best-practice-benchmark uint)
  (performance-rating (string-ascii 20)))
  (begin
    (asserts! (is-some (map-get? performance-measurements { measurement-id: measurement-id })) ERR-MEASUREMENT-NOT-FOUND)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set kpi-benchmarks
      { measurement-id: measurement-id, kpi-index: kpi-index }
      {
        industry-benchmark: industry-benchmark,
        internal-benchmark: internal-benchmark,
        best-practice-benchmark: best-practice-benchmark,
        performance-rating: performance-rating
      }
    )

    (ok true)
  )
)

;; Record performance trend
(define-public (record-performance-trend
  (measurement-id uint)
  (period uint)
  (trend-direction (string-ascii 20))
  (growth-rate uint)
  (volatility-index uint)
  (predictive-score uint)
  (confidence-level uint))
  (begin
    (asserts! (is-some (map-get? performance-measurements { measurement-id: measurement-id })) ERR-MEASUREMENT-NOT-FOUND)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= confidence-level u100) ERR-INVALID-INPUT)

    (map-set performance-trends
      { measurement-id: measurement-id, period: period }
      {
        trend-direction: trend-direction,
        growth-rate: growth-rate,
        volatility-index: volatility-index,
        predictive-score: predictive-score,
        confidence-level: confidence-level
      }
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get performance measurement
(define-read-only (get-performance-measurement (measurement-id uint))
  (map-get? performance-measurements { measurement-id: measurement-id })
)

;; Get performance report
(define-read-only (get-performance-report (report-id uint))
  (map-get? performance-reports { report-id: report-id })
)

;; Get KPI benchmarks
(define-read-only (get-kpi-benchmarks (measurement-id uint) (kpi-index uint))
  (map-get? kpi-benchmarks { measurement-id: measurement-id, kpi-index: kpi-index })
)

;; Get performance trend
(define-read-only (get-performance-trend (measurement-id uint) (period uint))
  (map-get? performance-trends { measurement-id: measurement-id, period: period })
)

;; Calculate efficiency score
(define-read-only (calculate-efficiency-score (measurement-id uint))
  (match (map-get? performance-measurements { measurement-id: measurement-id })
    measurement-data
      (let
        (
          (baseline-sum (fold + (get baseline-metrics measurement-data) u0))
          (actual-sum (fold + (get actual-metrics measurement-data) u0))
        )
        (if (> baseline-sum u0)
          (/ (* actual-sum u100) baseline-sum)
          u0
        )
      )
    u0
  )
)

;; Calculate success rate
(define-read-only (calculate-success-rate (measurement-id uint))
  (match (map-get? performance-measurements { measurement-id: measurement-id })
    measurement-data
      (let
        (
          (target-metrics (get target-metrics measurement-data))
          (actual-metrics (get actual-metrics measurement-data))
          (achievements (map >= actual-metrics target-metrics))
          (total-kpis (len target-metrics))
          (achieved-kpis (len (filter is-true achievements)))
        )
        (if (> total-kpis u0)
          (/ (* achieved-kpis u100) total-kpis)
          u0
        )
      )
    u0
  )
)

;; Calculate overall performance
(define-read-only (calculate-overall-performance (measurement-id uint))
  (match (map-get? performance-measurements { measurement-id: measurement-id })
    measurement-data
      (let
        (
          (roi (get roi-calculation measurement-data))
          (efficiency (get efficiency-score measurement-data))
          (success (get success-rate measurement-data))
        )
        (/ (+ (+ roi efficiency) success) u3)
      )
    u0
  )
)

;; Calculate KPI achievements
(define-read-only (calculate-kpi-achievements (measurement-id uint))
  (match (map-get? performance-measurements { measurement-id: measurement-id })
    measurement-data
      (let
        (
          (target-metrics (get target-metrics measurement-data))
          (actual-metrics (get actual-metrics measurement-data))
        )
        (map calculate-achievement-percentage actual-metrics target-metrics)
      )
    (list)
  )
)

;; Helper function to calculate achievement percentage
(define-read-only (calculate-achievement-percentage (actual uint) (target uint))
  (if (> target u0)
    (/ (* actual u100) target)
    u0
  )
)

;; Helper function to check if value is true
(define-read-only (is-true (value bool))
  value
)

;; Get next measurement ID
(define-read-only (get-next-measurement-id)
  (var-get next-measurement-id)
)

;; Get next report ID
(define-read-only (get-next-report-id)
  (var-get next-report-id)
)
