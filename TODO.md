# MCSM Project TODO List

## Core Features

### Java Management
- [x] Implementare l'auto-detection di Java nelle impostazioni
- [x] Aggiungere la validazione del percorso Java
- [x] Salvare il percorso Java nelle impostazioni
- [x] Aggiungere supporto per multiple versioni di Java

### Server Creation & Management
- [ ] Implementare una progress bar durante il download del server
- [ ] Aggiungere una schermata di download separata
- [ ] Implementare il sistema di aggiunta automatica dei server alla homepage
- [ ] Aggiungere la validazione dei campi nel form di creazione
- [ ] Implementare il sistema di gestione delle versioni dei server

### UI/UX Improvements
- [x] Aggiungere spazi corretti nel layout delle impostazioni
- [ ] Migliorare il responsive design
- [ ] Aggiungere animazioni di transizione
- [ ] Implementare temi chiari/scuri
- [ ] Aggiungere tooltips per le funzionalità

### Data Management
- [x] Decidere e implementare il sistema di storage (SQLite vs JSON)
- [ ] Implementare il sistema di backup delle configurazioni
- [ ] Creare schema per i dati dei server
- [ ] Aggiungere sistema di migrazione dei dati
- [ ] Implementare sistema di validazione dei dati

### Internationalization
- [ ] Implementare sistema i18n
- [ ] Aggiungere supporto per lingue multiple
- [ ] Creare file di traduzione per:
  - [ ] Italiano
  - [ ] Inglese
  - [ ] Altre lingue prioritarie

### Application Info
- [ ] Aggiungere schermata About con:
  - [ ] Informazioni sulla versione
  - [ ] Credits degli sviluppatori
  - [ ] Link alla pagina GitHub
  - [ ] Changelog
- [ ] Implementare sistema di controllo aggiornamenti

## Additional Features

### Server Management
- [ ] Implementare sistema di backup automatico
- [ ] Aggiungere gestione plugins
- [ ] Implementare sistema di logs
- [ ] Aggiungere monitoraggio risorse
- [ ] Implementare sistema di notifiche

### Security
- [ ] Implementare sistema di autenticazione per operazioni sensibili
- [ ] Aggiungere validazione dei file scaricati
- [ ] Implementare controlli di sicurezza per i comandi
- [ ] Aggiungere sistema di permessi

### Performance
- [ ] Ottimizzare il caricamento delle risorse
- [ ] Implementare lazy loading dei componenti
- [ ] Aggiungere caching dei dati
- [ ] Ottimizzare le operazioni di I/O

### Settings
- [ ] Aggiungere un sistema di modifica dei settings direttamente dal software 
      (usare vscode come estensione o un blocco note custom)

### Testing
- [ ] Aggiungere unit tests
- [ ] Implementare integration tests
- [ ] Aggiungere E2E tests
- [ ] Creare test automatizzati per il CI/CD

## Documentation
- [ ] Creare documentazione per gli utenti
- [ ] Aggiungere documentazione per gli sviluppatori
- [ ] Creare wiki con guide e tutorial
- [ ] Aggiungere commenti al codice
- [ ] Creare diagrammi di architettura