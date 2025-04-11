use std::sync::{Arc, Mutex};
use std::process::{Child, ChildStdout, ChildStderr};
use std::io::{BufReader, BufRead};
use tokio::sync::mpsc;
use serde::{Serialize, Deserialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct ConsoleMessage {
    pub timestamp: String,
    pub level: LogLevel,
    pub message: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum LogLevel {
    Info,
    Warning,
    Error,
    Debug,
}

pub struct ConsoleManager {
    process: Arc<Mutex<Option<Child>>>,
    message_tx: mpsc::Sender<ConsoleMessage>,
    message_rx: mpsc::Receiver<ConsoleMessage>,
}

impl ConsoleManager {
    pub fn new(process: Arc<Mutex<Option<Child>>>) -> Self {
        let (tx, rx) = mpsc::channel(100);
        ConsoleManager {
            process,
            message_tx: tx,
            message_rx: rx,
        }
    }

    pub async fn start_logging(&self) -> Result<(), String> {
        let process = self.process.lock().unwrap();
        if let Some(child) = process.as_ref() {
            if let Some(stdout) = &child.stdout {
                let stdout = stdout.try_clone().map_err(|e| e.to_string())?;
                self.start_stdout_logging(stdout).await?;
            }
            if let Some(stderr) = &child.stderr {
                let stderr = stderr.try_clone().map_err(|e| e.to_string())?;
                self.start_stderr_logging(stderr).await?;
            }
            Ok(())
        } else {
            Err("Server process not found".to_string())
        }
    }

    async fn start_stdout_logging(&self, stdout: ChildStdout) -> Result<(), String> {
        let reader = BufReader::new(stdout);
        let tx = self.message_tx.clone();

        tokio::spawn(async move {
            for line in reader.lines() {
                if let Ok(line) = line {
                    let message = ConsoleMessage {
                        timestamp: chrono::Local::now().to_rfc3339(),
                        level: LogLevel::Info,
                        message: line,
                    };
                    if let Err(e) = tx.send(message).await {
                        eprintln!("Error sending console message: {}", e);
                        break;
                    }
                }
            }
        });

        Ok(())
    }

    async fn start_stderr_logging(&self, stderr: ChildStderr) -> Result<(), String> {
        let reader = BufReader::new(stderr);
        let tx = self.message_tx.clone();

        tokio::spawn(async move {
            for line in reader.lines() {
                if let Ok(line) = line {
                    let message = ConsoleMessage {
                        timestamp: chrono::Local::now().to_rfc3339(),
                        level: LogLevel::Error,
                        message: line,
                    };
                    if let Err(e) = tx.send(message).await {
                        eprintln!("Error sending console message: {}", e);
                        break;
                    }
                }
            }
        });

        Ok(())
    }

    pub async fn send_command(&self, command: &str) -> Result<(), String> {
        let mut process = self.process.lock().unwrap();
        if let Some(child) = process.as_mut() {
            if let Some(stdin) = &mut child.stdin {
                use std::io::Write;
                writeln!(stdin, "{}", command).map_err(|e| e.to_string())?;
                Ok(())
            } else {
                Err("Could not access server stdin".to_string())
            }
        } else {
            Err("Server process not found".to_string())
        }
    }

    pub async fn get_messages(&mut self) -> Vec<ConsoleMessage> {
        let mut messages = Vec::new();
        while let Ok(message) = self.message_rx.try_recv() {
            messages.push(message);
        }
        messages
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::process::Command;

    #[tokio::test]
    async fn test_console_manager() {
        let mut cmd = Command::new("echo")
            .arg("test")
            .stdout(std::process::Stdio::piped())
            .spawn()
            .unwrap();

        let process = Arc::new(Mutex::new(Some(cmd)));
        let mut console = ConsoleManager::new(process);
        
        assert!(console.start_logging().await.is_ok());
        let messages = console.get_messages().await;
        assert!(!messages.is_empty());
    }
} 