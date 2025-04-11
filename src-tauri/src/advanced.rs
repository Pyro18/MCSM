use std::path::PathBuf;
use serde::{Serialize, Deserialize};
use tokio::fs;
use std::collections::HashMap;
use chrono::{DateTime, Utc};
use std::time::Duration;
use tokio::time;
use std::sync::{Arc, Mutex};
use tokio::sync::mpsc;

#[derive(Debug, Serialize, Deserialize)]
pub struct ScheduledTask {
    pub id: String,
    pub name: String,
    pub command: String,
    pub schedule: TaskSchedule,
    pub last_run: Option<DateTime<Utc>>,
    pub next_run: DateTime<Utc>,
    pub enabled: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum TaskSchedule {
    Interval(Duration),
    Cron(String),
    OneTime(DateTime<Utc>),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Notification {
    pub id: String,
    pub title: String,
    pub message: String,
    pub level: NotificationLevel,
    pub timestamp: DateTime<Utc>,
    pub read: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum NotificationLevel {
    Info,
    Warning,
    Error,
    Success,
}

pub struct AdvancedManager {
    tasks: Arc<Mutex<HashMap<String, ScheduledTask>>>,
    notifications: Arc<Mutex<Vec<Notification>>>,
    running: Arc<Mutex<bool>>,
    notification_tx: mpsc::Sender<Notification>,
    notification_rx: mpsc::Receiver<Notification>,
}

impl AdvancedManager {
    pub fn new() -> Self {
        let (tx, rx) = mpsc::channel(100);
        AdvancedManager {
            tasks: Arc::new(Mutex::new(HashMap::new())),
            notifications: Arc::new(Mutex::new(Vec::new())),
            running: Arc::new(Mutex::new(false)),
            notification_tx: tx,
            notification_rx: rx,
        }
    }

    pub async fn start(&self) -> Result<(), String> {
        let mut running = self.running.lock().unwrap();
        *running = true;
        drop(running);

        self.start_task_scheduler().await?;
        self.start_notification_handler().await?;

        Ok(())
    }

    pub fn stop(&self) {
        let mut running = self.running.lock().unwrap();
        *running = false;
    }

    async fn start_task_scheduler(&self) -> Result<(), String> {
        let tasks = self.tasks.clone();
        let running = self.running.clone();
        let notification_tx = self.notification_tx.clone();

        tokio::spawn(async move {
            let mut interval = time::interval(Duration::from_secs(1));

            while *running.lock().unwrap() {
                interval.tick().await;
                let now = Utc::now();

                let mut tasks_guard = tasks.lock().unwrap();
                for task in tasks_guard.values_mut() {
                    if task.enabled && task.next_run <= now {
                        // Execute task
                        if let Err(e) = Self::execute_task(task, &notification_tx).await {
                            eprintln!("Task execution failed: {}", e);
                        }

                        // Update task schedule
                        match &task.schedule {
                            TaskSchedule::Interval(duration) => {
                                task.next_run = now + *duration;
                            }
                            TaskSchedule::Cron(_) => {
                                // TODO: Implement cron schedule calculation
                            }
                            TaskSchedule::OneTime(_) => {
                                task.enabled = false;
                            }
                        }
                        task.last_run = Some(now);
                    }
                }
            }
        });

        Ok(())
    }

    async fn start_notification_handler(&self) -> Result<(), String> {
        let notifications = self.notifications.clone();
        let mut rx = self.notification_rx.clone();

        tokio::spawn(async move {
            while let Some(notification) = rx.recv().await {
                let mut notifications_guard = notifications.lock().unwrap();
                notifications_guard.push(notification);
            }
        });

        Ok(())
    }

    async fn execute_task(task: &ScheduledTask, notification_tx: &mpsc::Sender<Notification>) -> Result<(), String> {
        // TODO: Implement task execution
        let notification = Notification {
            id: uuid::Uuid::new_v4().to_string(),
            title: format!("Task executed: {}", task.name),
            message: format!("Command: {}", task.command),
            level: NotificationLevel::Info,
            timestamp: Utc::now(),
            read: false,
        };

        notification_tx.send(notification).await.map_err(|e| e.to_string())?;
        Ok(())
    }

    pub fn add_task(&self, task: ScheduledTask) {
        let mut tasks = self.tasks.lock().unwrap();
        tasks.insert(task.id.clone(), task);
    }

    pub fn remove_task(&self, id: &str) {
        let mut tasks = self.tasks.lock().unwrap();
        tasks.remove(id);
    }

    pub fn get_task(&self, id: &str) -> Option<ScheduledTask> {
        let tasks = self.tasks.lock().unwrap();
        tasks.get(id).cloned()
    }

    pub fn get_all_tasks(&self) -> Vec<ScheduledTask> {
        let tasks = self.tasks.lock().unwrap();
        tasks.values().cloned().collect()
    }

    pub fn get_notifications(&self) -> Vec<Notification> {
        let notifications = self.notifications.lock().unwrap();
        notifications.clone()
    }

    pub fn get_unread_notifications(&self) -> Vec<Notification> {
        let notifications = self.notifications.lock().unwrap();
        notifications.iter()
            .filter(|n| !n.read)
            .cloned()
            .collect()
    }

    pub fn mark_notification_read(&self, id: &str) {
        let mut notifications = self.notifications.lock().unwrap();
        if let Some(notification) = notifications.iter_mut().find(|n| n.id == id) {
            notification.read = true;
        }
    }

    pub fn clear_notifications(&self) {
        let mut notifications = self.notifications.lock().unwrap();
        notifications.clear();
    }

    pub async fn send_notification(&self, notification: Notification) -> Result<(), String> {
        self.notification_tx.send(notification).await.map_err(|e| e.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_advanced_manager() {
        let manager = AdvancedManager::new();
        assert!(manager.start().await.is_ok());

        let task = ScheduledTask {
            id: "test-task".to_string(),
            name: "Test Task".to_string(),
            command: "test".to_string(),
            schedule: TaskSchedule::Interval(Duration::from_secs(1)),
            last_run: None,
            next_run: Utc::now(),
            enabled: true,
        };

        manager.add_task(task);
        assert_eq!(manager.get_all_tasks().len(), 1);

        let notification = Notification {
            id: "test-notification".to_string(),
            title: "Test".to_string(),
            message: "Test message".to_string(),
            level: NotificationLevel::Info,
            timestamp: Utc::now(),
            read: false,
        };

        assert!(manager.send_notification(notification).await.is_ok());
        assert_eq!(manager.get_notifications().len(), 1);

        manager.stop();
    }
} 