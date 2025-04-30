#lang racket

(require web-server/servlet
         web-server/servlet-env
         web-server/dispatch
         "db-operations.rkt"
         racket/format)

(provide start-servlet)

;; Define as rotas mais explicitamente
(define-values (dispatch url->request)
  (dispatch-rules
   [("") home-page]
   [("evaluate") evaluation-page]
   [("submit") #:method "post" submit-evaluation]
   [("styles.css") send-css]
   [("app.js") send-js]
   [else not-found-page]))

;; Função principal para debug
(define (start-servlet request)
  (printf "Request URI: ~a\n" (request-uri request))
  (printf "Request method: ~a\n" (request-method request))
  (printf "URL path: ~a\n" (map path/param-path (url-path (request-uri request))))
  
  ;; Tente o dispatch, se falhar, mostre o erro e retorne a página 404
  (with-handlers ([exn:fail? (lambda (e)
                              (printf "Dispatch error: ~a\n" (exn-message e))
                              (not-found-page))])
    (dispatch request)))

;; Home page com visualização de dados de avaliação
(define (home-page request)
  (let ([stats (get-evaluation-stats)])
    (response/xexpr
     `(html
       (head
        (title "Avaliação de usabilidade DrRacket")
        (link ((rel "stylesheet") (href "/styles.css")))
        (script ((src "/app.js")))
        (script ((src "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"))))
       (body
        (div ((class "container"))
             (h1 "Avaliação de usabilidade DrRacket")
             (p "Bem-vindo à ferramenta de Avaliação de Usabilidade DrRacket. Este aplicativo permite que os usuários avaliem o software DrRacket com base nas 10 heurísticas de usabilidade de Jacob Nielsen.")
             
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
                                        labels: ['Visibilidade', 'Compatibilidade', 'Controle', 'Consistência', 
                                                'Prevenção de Erros', 'Reconhecimento', 'Flexibilidade', 'Estética', 
                                                'Recuperação de Erros', 'Ajuda e Documentação'],
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
                       (p ,(format "Total de avaliações: ~a" (hash-ref stats 'count)))
                       (p ,(format "Média geral: ~a/10" 
                                  (let ([avg (/ (apply + (hash-ref stats 'averages)) 
                                               (length (hash-ref stats 'averages)))])
                                    (number->string (/ (round (* avg 10)) 10)))))))
             
             (div ((class "cta-button"))
                  (a ((href "/evaluate") (class "button")) "Avaliar DrRacket")))))))

;; Evaluation page with the questionnaire
;; Evaluation page with the questionnaire
(define (evaluation-page request)
  (response/xexpr
   `(html
     (head
      (title "Avaliação DrRacket - Questionário")
      (link ((rel "stylesheet") (href "/styles.css")))
      (script ((src "/app.js"))))
     (body
      (div ((class "container"))
           (h1 "Avaliação DrRacket")
           (p "Avalie o DrRacket com base nas 10 heurísticas de usabilidade da Nielsen. Clique nos pontos para selecionar sua avaliação (1 a 10).")
           
           (form ((action "/submit") (method "post") (id "evaluation-form"))
                 
                 (div ((class "evaluation-section"))
                      (h2 "1. Visibilidade do status do sistema")
                      (p "O DrRacket informa claramente quando está processando ou executando um código? É fácil perceber se há algum erro durante a execução? O feedback das ações é imediato e visível?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'visibility')")))))))
                      (input ((type "hidden") (name "visibility") (id "visibility-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "2. Compatibilidade entre o sistema e o mundo real")
                      (p "As mensagens de erro ou de sistema são compreensíveis por usuários não técnicos? Os termos e expressões usados no ambiente refletem a linguagem comum ao usuário?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'compatibility')")))))))
                      (input ((type "hidden") (name "compatibility") (id "compatibility-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "3. Controle e liberdade do usuário")
                      (p "É fácil desfazer ou refazer ações no DrRacket? Você sente que tem controle sobre as ações realizadas no ambiente (rodar, parar, editar)?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'control')")))))))
                      (input ((type "hidden") (name "control") (id "control-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "4. Consistência e padrões")
                      (p "A interface do DrRacket mantém padrões consistentes? Funções semelhantes são representadas de forma semelhante (visual e funcionalmente)?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'consistency')")))))))
                      (input ((type "hidden") (name "consistency") (id "consistency-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "5. Prevenção de erros")
                      (p "O software ajuda a evitar erros antes que eles ocorram? Há alertas ou avisos antes de ações potencialmente destrutivas?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'error_prevention')")))))))
                      (input ((type "hidden") (name "error_prevention") (id "error_prevention-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "6. Reconhecimento em vez de memorização")
                      (p "O ambiente facilita o uso sem exigir que o usuário memorize comandos? Os menus e botões são autoexplicativos e de fácil acesso?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'recognition')")))))))
                      (input ((type "hidden") (name "recognition") (id "recognition-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "7. Flexibilidade e eficiência de uso")
                      (p "Usuários experientes podem utilizar atalhos ou recursos avançados para aumentar a produtividade? O ambiente se adapta bem tanto a iniciantes quanto a usuários mais experientes?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'flexibility')")))))))
                      (input ((type "hidden") (name "flexibility") (id "flexibility-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "8. Estética e design minimalista")
                      (p "A interface é limpa e sem elementos desnecessários? O design facilita o foco nas tarefas principais, como escrever e rodar código?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'aesthetics')")))))))
                      (input ((type "hidden") (name "aesthetics") (id "aesthetics-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "9. Ajudar os usuários a reconhecer, diagnosticar e recuperar erros")
                      (p "As mensagens de erro são claras e ajudam a entender o que precisa ser corrigido? É fácil identificar o tipo de erro e encontrar sua localização no código?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'error_recovery')")))))))
                      (input ((type "hidden") (name "error_recovery") (id "error_recovery-value") (value "0"))))
                 
                 (div ((class "evaluation-section"))
                      (h2 "10. Ajuda e documentação")
                      (p "A ajuda integrada (como documentação ou dicas) é útil e de fácil acesso? Você consegue encontrar rapidamente a resposta para uma dúvida dentro do próprio DrRacket?")
                      (div ((class "rating-container")) 
                           (div ((class "rating")) 
                                ,@(for/list ([i (in-range 1 11)])
                                    `(span ((class "dot") (data-value ,(number->string i)) (onclick ,(format "selectRating(this, 'help_docs')")))))))
                      (input ((type "hidden") (name "help_docs") (id "help_docs-value") (value "0"))))
                 
                 (div ((class "form-actions"))
                      (button ((type "submit") (class "button")) "Enviar"))))))))

;; Process submitted evaluation
;; Process submitted evaluation
(define (submit-evaluation request)
  (define bindings
    (request-bindings/raw request))
  
  (define evaluation-data
    (make-hash))
  
  ;; Função auxiliar para extrair valor do binding e convertê-lo para número
  (define (extract-value field-name)
    (define field-bytes (string->bytes/utf-8 (symbol->string field-name)))
    (define binding (bindings-assq field-bytes bindings))
    (if binding
        (string->number (bytes->string/utf-8 (binding:form-value binding)))
        0)) ; Valor padrão se não encontrar o campo
  
  (hash-set! evaluation-data 'visibility (extract-value 'visibility))
  (hash-set! evaluation-data 'compatibility (extract-value 'compatibility))
  (hash-set! evaluation-data 'control (extract-value 'control))
  (hash-set! evaluation-data 'consistency (extract-value 'consistency))
  (hash-set! evaluation-data 'error_prevention (extract-value 'error_prevention))
  (hash-set! evaluation-data 'recognition (extract-value 'recognition))
  (hash-set! evaluation-data 'flexibility (extract-value 'flexibility))
  (hash-set! evaluation-data 'aesthetics (extract-value 'aesthetics))
  (hash-set! evaluation-data 'error_recovery (extract-value 'error_recovery))
  (hash-set! evaluation-data 'help_docs (extract-value 'help_docs))
  
  ;; Save to database
  (save-evaluation evaluation-data)
  
  ;; Redirect back to the home page
  (redirect-to "/"))

;; Send CSS stylesheet
(define (send-css request)
  (printf "Serving CSS file.\n")
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
(define (send-js request)
  (printf "Serving JS file.\n")
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
(define (not-found-page request)
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