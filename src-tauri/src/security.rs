use std::path::PathBuf;
use serde::{Serialize, Deserialize};
use tokio::fs;
use std::collections::HashMap;
use chrono::{DateTime, Utc};
use std::time::Duration;

#[derive(Debug, Serialize, Deserialize)]
pub struct SecurityEvent {
    pub timestamp: DateTime<Utc>,
    pub event_type: SecurityEventType,
    pub source: String,
    pub details: String,
    pub severity: SecuritySeverity,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum SecurityEventType {
    LoginAttempt,
    CommandExecution,
    FileAccess,
    ConfigurationChange,
    BackupOperation,
    PluginInstallation,
    WorldModification,
    PlayerAction,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum SecuritySeverity {
    Info,
    Warning,
    Error,
    Critical,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct SecurityConfig {
    pub enable_backup: bool,
    pub backup_interval: Duration,
    pub max_backups: usize,
    pub backup_path: PathBuf,
    pub enable_logging: bool,
    pub log_retention: Duration,
    pub enable_whitelist: bool,
    pub enable_blacklist: bool,
    pub enable_ops: bool,
    pub enable_anti_griefing: bool,
    pub enable_activity_monitoring: bool,
}

pub struct SecurityManager {
    config: SecurityConfig,
    events: Vec<SecurityEvent>,
    backup_schedule: tokio::time::Interval,
    running: bool,
}

impl SecurityManager {
    pub fn new(config: SecurityConfig) -> Self {
        SecurityManager {
            config,
            events: Vec::new(),
            backup_schedule: tokio::time::interval(Duration::from_secs(3600)), // Default 1 hour
            running: false,
        }
    }

    pub async fn start(&mut self) -> Result<(), String> {
        if self.running {
            return Err("Security manager is already running".to_string());
        }

        self.running = true;
        self.start_backup_schedule().await?;
        self.start_event_monitoring().await?;

        Ok(())
    }

    pub fn stop(&mut self) {
        self.running = false;
    }

    async fn start_backup_schedule(&self) -> Result<(), String> {
        if !self.config.enable_backup {
            return Ok(());
        }

        let config = self.config.clone();
        let mut interval = tokio::time::interval(config.backup_interval);

        tokio::spawn(async move {
            while self.running {
                interval.tick().await;
                if let Err(e) = self.perform_backup().await {
                    eprintln!("Backup failed: {}", e);
                }
            }
        });

        Ok(())
    }

    async fn start_event_monitoring(&self) -> Result<(), String> {
        if !self.config.enable_logging {
            return Ok(());
        }

        // TODO: Implement event monitoring
        Ok(())
    }

    pub async fn perform_backup(&self) -> Result<(), String> {
        if !self.config.enable_backup {
            return Ok(());
        }

        let backup_dir = &self.config.backup_path;
        if !backup_dir.exists() {
            fs::create_dir_all(backup_dir)
                .await
                .map_err(|e| e.to_string())?;
        }

        let timestamp = Utc::now().format("%Y%m%d_%H%M%S").to_string();
        let backup_name = format!("backup_{}.zip", timestamp);
        let backup_path = backup_dir.join(backup_name);

        // TODO: Implement actual backup logic
        self.log_event(SecurityEvent {
            timestamp: Utc::now(),
            event_type: SecurityEventType::BackupOperation,
            source: "SecurityManager".to_string(),
            details: format!("Created backup: {}", backup_name),
            severity: SecuritySeverity::Info,
        });

        self.cleanup_old_backups().await?;

        Ok(())
    }

    async fn cleanup_old_backups(&self) -> Result<(), String> {
        let mut backups: Vec<PathBuf> = fs::read_dir(&self.config.backup_path)
            .await
            .map_err(|e| e.to_string())?
            .filter_map(|entry| entry.ok().map(|e| e.path()))
            .filter(|path| path.extension().and_then(|s| s.to_str()) == Some("zip"))
            .collect();

        backups.sort_by_key(|path| {
            fs::metadata(path)
                .and_then(|m| m.modified())
                .unwrap_or(std::time::SystemTime::UNIX_EPOCH)
        });

        while backups.len() > self.config.max_backups {
            if let Some(oldest) = backups.first() {
                fs::remove_file(oldest)
                    .await
                    .map_err(|e| e.to_string())?;
                backups.remove(0);
            }
        }

        Ok(())
    }

    pub fn log_event(&mut self, event: SecurityEvent) {
        self.events.push(event);
        self.cleanup_old_events();
    }

    fn cleanup_old_events(&mut self) {
        let cutoff = Utc::now() - self.config.log_retention;
        self.events.retain(|event| event.timestamp >= cutoff);
    }

    pub fn get_events(&self) -> &[SecurityEvent] {
        &self.events
    }

    pub fn get_events_by_type(&self, event_type: SecurityEventType) -> Vec<&SecurityEvent> {
        self.events
            .iter()
            .filter(|event| event.event_type == event_type)
            .collect()
    }

    pub fn get_events_by_severity(&self, severity: SecuritySeverity) -> Vec<&SecurityEvent> {
        self.events
            .iter()
            .filter(|event| event.severity == severity)
            .collect()
    }

    pub fn export_events(&self, path: &PathBuf) -> Result<(), String> {
        let json = serde_json::to_string_pretty(&self.events)
            .map_err(|e| e.to_string())?;
        
        fs::write(path, json)
            .await
            .map_err(|e| e.to_string())?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_security_manager() {
        let config = SecurityConfig {
            enable_backup: true,
            backup_interval: Duration::from_secs(1),
            max_backups: 3,
            backup_path: PathBuf::from("test_backups"),
            enable_logging: true,
            log_retention: Duration::from_secs(3600),
            enable_whitelist: true,
            enable_blacklist: true,
            enable_ops: true,
            enable_anti_griefing: true,
            enable_activity_monitoring: true,
        };

        let mut manager = SecurityManager::new(config);
        assert!(manager.start().await.is_ok());
        
        manager.log_event(SecurityEvent {
            timestamp: Utc::now(),
            event_type: SecurityEventType::LoginAttempt,
            source: "test".to_string(),
            details: "Test event".to_string(),
            severity: SecuritySeverity::Info,
        });

        assert_eq!(manager.get_events().len(), 1);
        manager.stop();
    }
} 