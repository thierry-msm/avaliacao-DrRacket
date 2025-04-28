#lang racket

(define current-dir (current-directory))
(printf "Current directory: ~a\n" current-dir)
(printf "Write permission: ~a\n" (file-exists? current-dir))

(init-database)

;; Rest of the code...

;; Main entry point for DrRacket Usability Evaluation Web Application

(require web-server/servlet
         web-server/servlet-env
         "db-operations.rkt"
         "web-interface.rkt")

;; Initialize the database
;;(init-database)

;; Register exit handler to close database connection
(exit-handler
 (λ (v)
   (close-database)
   (exit v)))

;; Start the web server
(serve/servlet start-servlet
               #:launch-browser? #t
               #:quit? #f
               #:listen-ip #f
               #:port 8000
               #:servlet-path "/")

;; Display a message indicating the server is running
(printf "DrRacket Usability Evaluation server running at http://localhost:8000/\n")

