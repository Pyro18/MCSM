# MCSM Project TODO List
## Core Features
### Java Management
- [x] Implementare l'auto-detection di Java nelle impostazioni
- [x] Aggiungere la validazione del percorso Java
- [x] Salvare il percorso Java nelle impostazioni
- [x] Aggiungere supporto per multiple versioni di Java
- [x] Gestione delle versioni Java per server specifici
- [ ] Aggiungere suggerimenti per versioni Java compatibili per ogni versione di Minecraft

### Server Creation & Management
- [x] Implementare una progress bar durante il download del server
- [x] Aggiungere una schermata di download separata
- [x] Implementare il sistema di aggiunta automatica dei server alla homepage
- [x] Aggiungere la validazione dei campi nel form di creazione
- [x] Implementare il sistema di gestione delle versioni dei server
- [x] Implementare sistema di rotazione dei backup
- [ ] Ottimizzazione della memoria per i server a lungo termine
- [ ] Implementare duplicazione server
- [ ] Aggiungere sistema di import/export server
- [ ] Implementare gestione whitelist/blacklist
- [ ] Aggiungere gestione delle mod per server Forge/Fabric
- [x] Implementare gestione EULA automatica
- [x] Aggiungere system tray support

### UI/UX Improvements
- [x] Aggiungere spazi corretti nel layout delle impostazioni
- [x] Implementare tema scuro
- [x] Aggiungere effetti confetti per nuovi server
- [ ] Migliorare il responsive design
- [ ] Aggiungere animazioni di transizione
- [ ] Implementare tema chiaro
- [ ] Aggiungere tooltips per le funzionalità
- [ ] Implementare drag and drop per file di configurazione
- [ ] Aggiungere personalizzazione colori server
- [ ] Migliorare la UI delle statistiche server

### Data Management
- [x] Decidere e implementare il sistema di storage (JSON)
- [x] Implementare il sistema di backup delle configurazioni
- [x] Creare schema per i dati dei server
- [x] Implementare sistema di validazione dei dati
- [x] Implementare storage atomico per la sicurezza dei dati
- [ ] Aggiungere sistema di migrazione dei dati
- [ ] Implementare compressione dei backup
- [ ] Aggiungere export/import delle configurazioni
- [ ] Implementare pulizia automatica dei log vecchi

### Console Management
- [x] Migliore analisi e formattazione dei log
- [x] Gestione della posizione di scorrimento
- [x] Funzionalità di ricerca/filtraggio dei log
- [x] Correggere lo spam della console
- [x] Implementare colorazione sintassi log
- [ ] Aggiungere log viewer separato per file di log
- [ ] Implementare auto-completamento comandi
- [ ] Aggiungere comandi rapidi personalizzabili
- [ ] Implementare macro per comandi frequenti

### Server Monitoring
- [x] Monitoraggio stato server (running/stopped)
- [x] Tracking tempo di gioco
- [ ] Implementare grafici per:
  - [ ] Utilizzo CPU
  - [ ] Utilizzo memoria
  - [ ] Giocatori online
  - [ ] TPS (Ticks Per Second)
- [ ] Aggiungere sistema di alert per:
  - [ ] Crash server
  - [ ] Alto utilizzo risorse
  - [ ] Attività sospette
  - [ ] Backup falliti

### Additional Features
- [x] Implementare sistema di backup automatico
- [x] Aggiungere gestione configurazioni
- [ ] Implementare sistema di plugin
- [ ] Aggiungere supporto per:
  - [ ] Server Forge
  - [ ] Server Fabric
  - [ ] Server Spigot
- [ ] Implementare sistema di notifiche
- [ ] Aggiungere supporto multi-lingua
- [ ] Implementare updater automatico
- [ ] Aggiungere sistema di crash report

### Security
- [x] Implementare backup sicuro con rotazione
- [ ] Aggiungere validazione dei file scaricati
- [ ] Implementare controlli di sicurezza per i comandi
- [ ] Aggiungere sistema di permessi
- [ ] Implementare logging delle azioni sensibili
- [ ] Aggiungere controllo integrità file server

### Testing
- [ ] Aggiungere unit tests per:
  - [ ] Server management
  - [ ] Backup system
  - [ ] Settings management
  - [ ] Java detection
- [ ] Implementare integration tests
- [ ] Aggiungere E2E tests
- [ ] Creare test automatizzati per il CI/CD

## Documentation
- [ ] Creare documentazione per gli utenti:
  - [ ] Guida installazione
  - [ ] Manuale utilizzo
  - [ ] Troubleshooting
- [ ] Aggiungere documentazione per gli sviluppatori:
  - [ ] Setup ambiente
  - [ ] Architettura
  - [ ] API reference
- [ ] Creare wiki con guide e tutorial
- [ ] Aggiungere commenti al codice
- [ ] Creare diagrammi di architettura