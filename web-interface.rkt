#lang racket

;; Web Interface Module for the DrRacket Usability Evaluation Application
;; This module handles the web server and request handling

(require web-server/servlet
         web-server/servlet-env
         web-server/templates
         "db-operations.rkt"
         racket/format)

(provide start-servlet)

;; Main servlet function
(define (start-servlet request)
  (let ([path (url->string (request-uri request))])
    (cond
      [(equal? path "/") (home-page request)]
      [(equal? path "/evaluate") (evaluation-page request)]
      [(equal? path "/submit") (submit-evaluation request)]
      [(equal? path "/styles.css") (send-css)]
      [(equal? path "/app.js") (send-js)]
      [else (not-found-page)])))

;; Helper function to extract URL path as string
(define (url->string url)
  (string-join (map path/param-path (url-path url)) "/"))

;; Home page with visualization of evaluation data
(define (home-page request)
  (let ([stats (get-evaluation-stats)])
    (response/xexpr
     `(html
       (head
        (title "DrRacket Usability Evaluation")
        (link ((rel "stylesheet") (href "/styles.css")))
        (script ((src "/app.js")))
        (script ((src "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"))))
       (body
        (div ((class "container"))
             (h1 "DrRacket Usability Evaluation")
             (p "Welcome to the DrRacket Usability Evaluation tool. This application allows users to assess the DrRacket software based on Nielsen's 10 usability heuristics.")
             
             (div ((class "stats-container"))
                  (h2 "Current Evaluation Statistics")
                  (div ((class "chart-container"))
                       (canvas ((id "evaluation-chart"))))
                  
                  (script
                   ,(format "~a" 
                            (string-append 
                             "document.addEventListener('DOMContentLoaded', function() {
                                const ctx = document.getElementById('evaluation-chart').getContext('2d');
                                const chart = new Chart(ctx, {
                                    type: 'bar',
                                    data: {
                                        labels: ['Visibility', 'Compatibility', 'Control', 'Consistency', 
                                                'Error Prevention', 'Recognition', 'Flexibility', 'Aesthetics', 
                                                'Error Recovery', 'Help & Documentation'],
                                        datasets: [{
                                            label: 'Average Rating',
                                            data: [" (string-join (map number->string (hash-ref stats 'averages)) ", ") "],
                                            backgroundColor: [
                                                'rgba(54, 162, 235, 0.6)',
                                                'rgba(75, 192, 192, 0.6)',
                                                'rgba(153, 102, 255, 0.6)',
                                                'rgba(255, 159, 64, 0.6)',
                                                'rgba(255, 99, 132, 0.6)',
                                                'rgba(255, 206, 86, 0.6)',
                                                'rgba(54, 162, 235, 0.6)',
                                                'rgba(75, 192, 192, 0.6)',
                                                'rgba(153, 102, 255, 0.6)',
                                                'rgba(255, 159, 64, 0.6)'
                                            ],
                                            borderColor: [
                                                'rgba(54, 162, 235, 1)',
                                                'rgba(75, 192, 192, 1)',
                                                'rgba(153, 102, 255, 1)',
                                                'rgba(255, 159, 64, 1)',
                                                'rgba(255, 99, 132, 1)',
                                                'rgba(255, 206, 86, 1)',
                                                'rgba(54, 162, 235, 1)',
                                                'rgba(75, 192, 192, 1)',
                                                'rgba(153, 102, 255, 1)',
                                                'rgba(255, 159, 64, 1)'
                                            ],
                                            borderWidth: 1
                                        }]
                                    },
                                    options: {
                                        scales: {
                                            y: {
                                                beginAtZero: true,
                                                max: 10
                                            }
                                        },
                                        responsive: true,
                                        maintainAspectRatio: false
                                    }
                                });
                            });"))))
                  
                  (div ((class "stats-summary"))
                       (p ,(format "Total evaluations: ~a" (hash-ref stats 'count)))
                       (p ,(format "Average overall rating: ~a/10" 
                                  (let ([avg (/ (apply + (hash-ref stats 'averages)) 
                                               (length (hash-ref stats 'averages)))])
                                    (number->string (/ (round (* avg 10)) 10)))))))
             
             (div ((class "cta-button"))
                  (a ((href "/evaluate") (class "button")) "Avaliar DrRacket")))))))

;; Evaluation page with the questionnaire
(define (evaluation-page request)
  (response/xexpr
   `(html
     (head
      (title "Evaluate DrRacket - Usability Evaluation")
      (link ((rel "stylesheet") (href "/styles.css")))
      (script ((src "/app.js"))))
     (body
      (div ((class "container"))
           (h1 "Evaluate DrRacket")
           (p "Please rate DrRacket based on Nielsen's 10 usability heuristics. Click on the dots to select your rating (1-10).")
           
           (form ((action "/submit") (method "post") (id "evaluation-form"))
                 
                 (div ((class "evaluation-section"))
                      (h2 "1. Visibilidade do status do sistema")
                      (p "O DrRacket informa claramente quando está processando ou executando um código? É fácil perceber se há algum erro durante a execução? O feedback das ações é imediato e visível?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'visibility')")))))))
                      (input ((type "hidden") (name "visibility") (id "visibility-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "2. Compatibilidade entre o sistema e o mundo real")
                      (p "As mensagens de erro ou de sistema são compreensíveis por usuários não técnicos? Os termos e expressões usados no ambiente refletem a linguagem comum ao usuário?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'compatibility')")))))))
                      (input ((type "hidden") (name "compatibility") (id "compatibility-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "3. Controle e liberdade do usuário")
                      (p "É fácil desfazer ou refazer ações no DrRacket? Você sente que tem controle sobre as ações realizadas no ambiente (rodar, parar, editar)?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'control')")))))))
                      (input ((type "hidden") (name "control") (id "control-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "4. Consistência e padrões")
                      (p "A interface do DrRacket mantém padrões consistentes? Funções semelhantes são representadas de forma semelhante (visual e funcionalmente)?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'consistency')")))))))
                      (input ((type "hidden") (name "consistency") (id "consistency-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "5. Prevenção de erros")
                      (p "O software ajuda a evitar erros antes que eles ocorram? Há alertas ou avisos antes de ações potencialmente destrutivas?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'error_prevention')")))))))
                      (input ((type "hidden") (name "error_prevention") (id "error_prevention-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "6. Reconhecimento em vez de memorização")
                      (p "O ambiente facilita o uso sem exigir que o usuário memorize comandos? Os menus e botões são autoexplicativos e de fácil acesso?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'recognition')")))))))
                      (input ((type "hidden") (name "recognition") (id "recognition-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "7. Flexibilidade e eficiência de uso")
                      (p "Usuários experientes podem utilizar atalhos ou recursos avançados para aumentar a produtividade? O ambiente se adapta bem tanto a iniciantes quanto a usuários mais experientes?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'flexibility')")))))))
                      (input ((type "hidden") (name "flexibility") (id "flexibility-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "8. Estética e design minimalista")
                      (p "A interface é limpa e sem elementos desnecessários? O design facilita o foco nas tarefas principais, como escrever e rodar código?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'aesthetics')")))))))
                      (input ((type "hidden") (name "aesthetics") (id "aesthetics-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "9. Ajudar os usuários a reconhecer, diagnosticar e recuperar erros")
                      (p "As mensagens de erro são claras e ajudam a entender o que precisa ser corrigido? É fácil identificar o tipo de erro e encontrar sua localização no código?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'error_recovery')")))))))
                      (input ((type "hidden") (name "error_recovery") (id "error_recovery-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "10. Ajuda e documentação")
                      (p "A ajuda integrada (como documentação ou dicas) é útil e de fácil acesso? Você consegue encontrar rapidamente a resposta para uma dúvida dentro do próprio DrRacket?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,i) (onclick ,(format "selectRating(this, 'help_docs')")))))))
                      (input ((type "hidden") (name "help_docs") (id "help_docs-value") (value "0"))))
                 
                 (div ((class "form-actions"))
                      (button ((type "submit") (class "button")) "Submit Evaluation"))))))))

;; Process submitted evaluation
(define (submit-evaluation request)
  (define bindings
    (request-bindings/raw request))
  
  (define evaluation-data
    (make-hash))
  
  (hash-set! evaluation-data 'visibility 
             (string->number (extract-binding/single 'visibility bindings)))
  (hash-set! evaluation-data 'compatibility 
             (string->number (extract-binding/single 'compatibility bindings)))
  (hash-set! evaluation-data 'control 
             (string->number (extract-binding/single 'control bindings)))
  (hash-set! evaluation-data 'consistency 
             (string->number (extract-binding/single 'consistency bindings)))
  (hash-set! evaluation-data 'error_prevention 
             (string->number (extract-binding/single 'error_prevention bindings)))
  (hash-set! evaluation-data 'recognition 
             (string->number (extract-binding/single 'recognition bindings)))
  (hash-set! evaluation-data 'flexibility 
             (string->number (extract-binding/single 'flexibility bindings)))
  (hash-set! evaluation-data 'aesthetics 
             (string->number (extract-binding/single 'aesthetics bindings)))
  (hash-set! evaluation-data 'error_recovery 
             (string->number (extract-binding/single 'error_recovery bindings)))
  (hash-set! evaluation-data 'help_docs 
             (string->number (extract-binding/single 'help_docs bindings)))
  
  ;; Save to database
  (save-evaluation evaluation-data)
  
  ;; Redirect back to the home page
  (redirect-to "/"))

;; Send CSS stylesheet
(define (send-css)
  (response/full
   200 #"OK"
   (current-seconds)
   #"text/css"
   '()
   (list 
    #"* {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    }
    
    body {
        background-color: #f5f5f5;
        color: #333;
        line-height: 1.6;
    }
    
    .container {
        max-width: 1000px;
        margin: 0 auto;
        padding: 20px;
    }
    
    h1 {
        color: #2c3e50;
        margin-bottom: 20px;
        text-align: center;
    }
    
    h2 {
        color: #3498db;
        margin-top: 15px;
        margin-bottom: 10px;
    }
    
    p {
        margin-bottom: 15px;
    }
    
    .stats-container {
        background-color: white;
        border-radius: 8px;
        padding: 20px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        margin-bottom: 30px;
    }
    
    .chart-container {
        height: 400px;
        margin: 20px 0;
    }
    
    .stats-summary {
        text-align: center;
        font-size: 18px;
        margin-top: 20px;
    }
    
    .cta-button {
        text-align: center;
        margin: 30px 0;
    }
    
    .button {
        background-color: #3498db;
        color: white;
        padding: 12px 24px;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 16px;
        text-decoration: none;
        display: inline-block;
        transition: background-color 0.3s;
    }
    
    .button:hover {
        background-color: #2980b9;
    }
    
    .evaluation-section {
        background-color: white;
        border-radius: 8px;
        padding: 20px;
        margin-bottom: 20px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
    
    .rating-container {
        display: flex;
        justify-content: center;
        margin: 20px 0;
    }
    
    .rating {
        display: flex;
        gap: 10px;
    }
    
    .dot {
        width: 24px;
        height: 24px;
        border-radius: 50%;
        background-color: #e0e0e0;
        cursor: pointer;
        transition: background-color 0.2s;
    }
    
    .dot:hover {
        background-color: #bdbdbd;
    }
    
    .dot.selected {
        background-color: #3498db;
    }")))

;; Send JavaScript code
(define (send-js)
  (response/full
   200 #"OK"
   (current-seconds)
   #"text/javascript"
   '()
   (list 
    #"// Function to handle rating selection
    function selectRating(dot, fieldName) {
        // Get all dots in the same rating
        const dots = dot.parentElement.getElementsByClassName('dot');
        const value = parseInt(dot.getAttribute('data-value'));
        
        // Update hidden field value
        document.getElementById(fieldName + '-value').value = value;
        
        // Update dot colors based on selected value
        for (let i = 0; i < dots.length; i++) {
            const dotValue = parseInt(dots[i].getAttribute('data-value'));
            
            if (dotValue <= value) {
                // Calculate color based on value (red to green gradient)
                const hue = Math.min(120, value * 12); // 0 = red (0°), 10 = green (120°)
                dots[i].style.backgroundColor = `hsl(${hue}, 80%, 50%)`;
                dots[i].classList.add('selected');
            } else {
                dots[i].style.backgroundColor = '#e0e0e0';
                dots[i].classList.remove('selected');
            }
        }
    }
    
    // Form validation before submission
    document.addEventListener('DOMContentLoaded', function() {
        const form = document.getElementById('evaluation-form');
        
        if (form) {
            form.addEventListener('submit', function(event) {
                const fields = [
                    'visibility', 'compatibility', 'control', 'consistency',
                    'error_prevention', 'recognition', 'flexibility', 'aesthetics',
                    'error_recovery', 'help_docs'
                ];
                
                let allFieldsValid = true;
                
                fields.forEach(function(field) {
                    const value = document.getElementById(field + '-value').value;
                    if (value === '0') {
                        allFieldsValid = false;
                        const section = document.getElementById(field + '-value').closest('.evaluation-section');
                        section.style.borderLeft = '4px solid #e74c3c';
                        section.scrollIntoView({ behavior: 'smooth' });
                    }
                });
                
                if (!allFieldsValid) {
                    event.preventDefault();
                    alert('Por favor, avalie todas as heurísticas antes de enviar.');
                }
            });
        }
    });")))

;; 404 Page
(define (not-found-page)
  (response/xexpr
   #:code 404
   `(html
     (head
      (title "Page Not Found")
      (link ((rel "stylesheet") (href "/styles.css"))))
     (body
      (div ((class "container"))
           (h1 "404 - Page Not Found")
           (p "The page you are looking for does not exist.")
           (a ((href "/") (class "button")) "Return to Home Page"))))))