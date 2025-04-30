# DrRacket Usability Evaluation Application

## Descrição
Esta é uma aplicação web desenvolvida em Racket para avaliar a usabilidade do software DrRacket com base nas 10 heurísticas de usabilidade de Jakob Nielsen. Ela permite que os usuários preencham um questionário de avaliação e visualizem estatísticas agregadas das avaliações enviadas.

## Funcionalidades
- **Página inicial**: Exibe gráficos com estatísticas das avaliações enviadas.
- **Página de avaliação**: Permite que os usuários avaliem o DrRacket com base em critérios como visibilidade, compatibilidade, controle, consistência, entre outros.
- **Banco de dados**: Armazena as avaliações enviadas em um banco SQLite.

## Estrutura do Projeto
```
.
├── db-operations.rkt       # Módulo para operações no banco de dados
├── main.rkt                # Ponto de entrada principal do aplicativo
├── web-interface.rkt       # Módulo que define as rotas e a interface web
├── data/                   # Diretório para o banco de dados SQLite
│   └── usability-evaluation.db
└── compiled/               # Diretório gerado automaticamente pelo Racket
```

## Pré-requisitos
- [Racket](https://racket-lang.org/) instalado no sistema.

## Como Executar
1. Clone este repositório ou baixe os arquivos.
2. Certifique-se de que o Racket está instalado.
3. Navegue até o diretório do projeto no terminal.
4. Execute o seguinte comando:
   ```bash
   racket main.rkt
   ```
5. Abra o navegador e acesse `http://localhost:8000/`.

## Rotas Disponíveis
- `/`: Página inicial com estatísticas das avaliações.
- `/evaluate`: Página para preencher o questionário de avaliação.
- `/submit`: Endpoint para enviar as avaliações (método POST).
- `/styles.css`: Estilos CSS para a aplicação.
- `/app.js`: Código JavaScript para interatividade.

## Banco de Dados
- O banco de dados é criado automaticamente no diretório `data/` ao iniciar o servidor.
- Nome do arquivo: `usability-evaluation.db`.
- Tabela: `evaluations` com os seguintes campos:
  - `id`: Identificador único.
  - `timestamp`: Data e hora da avaliação.
  - `visibility`, `compatibility`, `control`, `consistency`, `error_prevention`, `recognition`, `flexibility`, `aesthetics`, `error_recovery`, `help_docs`: Campos de avaliação (valores de 1 a 10).

## Tecnologias Utilizadas
- Linguagem: Racket
- Banco de Dados: SQLite
- Frontend: HTML, CSS, JavaScript (incluindo Chart.js para gráficos)

## Problemas Conhecidos
- A rota raiz (`/`) pode ser interpretada como uma string vazia (`""`) em algumas configurações. Certifique-se de que as rotas estão configuradas corretamente no arquivo `web-interface.rkt`.

## Contribuição
Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.

## Licença
Este projeto está licenciado sob a licença MIT.