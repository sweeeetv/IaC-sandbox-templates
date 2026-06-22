.
├── Main.go //entry point, starts the web server and hooks up endpoints.
├── go.mod  //dependencies, tracks external Go and pacakges
├── handler // controllers, manages http requests, extracts parameters and sends responses.
│   └── handler.go
├── public
│   └── style.css
├── sample.env
├── store //Storage Layer: Saves and retrieves the short/long URL pairs (DB or memory).
│   └── store.go
├── utils //Helper Logic: Creates the unique, random short-codes.
│   └── generate.go
└── views
    └── index.html