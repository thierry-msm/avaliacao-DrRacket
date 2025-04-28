#lang racket

;; Database Operations Module for the DrRacket Usability Evaluation Application
;; This module handles all database-related operations

(require db
         srfi/19) ; para data legível

(provide init-database
         save-evaluation
         get-evaluation-stats
         close-database)

;; Database connection
(define db-conn #f)

;; Initialize the database
(define (init-database)
  ;; Caminho para subpasta segura dentro do projeto
  (define db-dir (build-path (current-directory) "data"))
  (unless (directory-exists? db-dir)
    (make-directory* db-dir)) ; Cria se não existir

  ;; Caminho completo para o arquivo do banco (formato robusto)
  (define db-path (build-path db-dir "usability-evaluation.db"))
  (displayln (format "Criando banco de dados em: ~a" db-path))

  ;; Conecta ao SQLite
  (set! db-conn (sqlite3-connect #:database (path->string db-path)))

  ;; Cria a tabela se ainda não existir
  (query-exec db-conn
              "CREATE TABLE IF NOT EXISTS evaluations (
                 id INTEGER PRIMARY KEY AUTOINCREMENT,
                 timestamp TEXT,
                 visibility INTEGER,
                 compatibility INTEGER,
                 control INTEGER,
                 consistency INTEGER,
                 error_prevention INTEGER,
                 recognition INTEGER,
                 flexibility INTEGER,
                 aesthetics INTEGER,
                 error_recovery INTEGER,
                 help_docs INTEGER
               )"))

;; Save a new evaluation to the database
(define (save-evaluation evaluation-data)
  ;; Timestamp legível
  (define timestamp (date->string (current-date) "~Y-~m-~d ~H:~M:~S"))
  (query-exec db-conn
              "INSERT INTO evaluations 
               (timestamp, visibility, compatibility, control, consistency, 
                error_prevention, recognition, flexibility, aesthetics, 
                error_recovery, help_docs) 
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
              timestamp
              (hash-ref evaluation-data 'visibility)
              (hash-ref evaluation-data 'compatibility)
              (hash-ref evaluation-data 'control)
              (hash-ref evaluation-data 'consistency)
              (hash-ref evaluation-data 'error_prevention)
              (hash-ref evaluation-data 'recognition)
              (hash-ref evaluation-data 'flexibility)
              (hash-ref evaluation-data 'aesthetics)
              (hash-ref evaluation-data 'error_recovery)
              (hash-ref evaluation-data 'help_docs)))

;; Get statistics from all evaluations
(define (get-evaluation-stats)
  (define evaluation-count 
    (query-value db-conn "SELECT COUNT(*) FROM evaluations"))
  
  (define averages
    (if (> evaluation-count 0)
        (list 
         (query-value db-conn "SELECT AVG(visibility) FROM evaluations")
         (query-value db-conn "SELECT AVG(compatibility) FROM evaluations")
         (query-value db-conn "SELECT AVG(control) FROM evaluations")
         (query-value db-conn "SELECT AVG(consistency) FROM evaluations")
         (query-value db-conn "SELECT AVG(error_prevention) FROM evaluations")
         (query-value db-conn "SELECT AVG(recognition) FROM evaluations")
         (query-value db-conn "SELECT AVG(flexibility) FROM evaluations")
         (query-value db-conn "SELECT AVG(aesthetics) FROM evaluations")
         (query-value db-conn "SELECT AVG(error_recovery) FROM evaluations")
         (query-value db-conn "SELECT AVG(help_docs) FROM evaluations"))
        '(0 0 0 0 0 0 0 0 0 0)))
  
  (hash 'count evaluation-count
        'averages averages))

;; Close the database connection
(define (close-database)
  (when db-conn
    (disconnect db-conn)
    (set! db-conn #f)))