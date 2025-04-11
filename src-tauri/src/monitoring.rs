use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use serde::{Serialize, Deserialize};
use sysinfo::{System, SystemExt, ProcessExt};
use tokio::time;

#[derive(Debug, Serialize, Deserialize)]
pub struct PerformanceMetrics {
    pub cpu_usage: f32,
    pub memory_usage: u64,
    pub tps: f32,
    pub player_count: u32,
    pub uptime: u64,
    pub last_tick_time: f32,
    pub entities: u32,
    pub chunks_loaded: u32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PerformanceHistory {
    pub metrics: Vec<PerformanceMetrics>,
    pub max_samples: usize,
}

pub struct PerformanceMonitor {
    system: Arc<Mutex<System>>,
    metrics: Arc<Mutex<PerformanceHistory>>,
    process_id: u32,
    last_tick_time: Arc<Mutex<f32>>,
    running: Arc<Mutex<bool>>,
}

impl PerformanceMonitor {
    pub fn new(process_id: u32) -> Self {
        PerformanceMonitor {
            system: Arc::new(Mutex::new(System::new_all())),
            metrics: Arc::new(Mutex::new(PerformanceHistory {
                metrics: Vec::new(),
                max_samples: 1000,
            })),
            process_id,
            last_tick_time: Arc::new(Mutex::new(0.0)),
            running: Arc::new(Mutex::new(false)),
        }
    }

    pub async fn start(&self) {
        let mut running = self.running.lock().unwrap();
        *running = true;
        drop(running);

        let system = self.system.clone();
        let metrics = self.metrics.clone();
        let process_id = self.process_id;
        let last_tick_time = self.last_tick_time.clone();
        let running = self.running.clone();

        tokio::spawn(async move {
            let mut interval = time::interval(Duration::from_secs(1));
            let start_time = Instant::now();

            while *running.lock().unwrap() {
                interval.tick().await;

                let mut sys = system.lock().unwrap();
                sys.refresh_all();

                let mut metrics_guard = metrics.lock().unwrap();
                let current_metrics = PerformanceMetrics {
                    cpu_usage: sys.process(process_id)
                        .map(|p| p.cpu_usage())
                        .unwrap_or(0.0),
                    memory_usage: sys.process(process_id)
                        .map(|p| p.memory())
                        .unwrap_or(0),
                    tps: 20.0, // TODO: Implement TPS calculation
                    player_count: 0, // TODO: Implement player count tracking
                    uptime: start_time.elapsed().as_secs(),
                    last_tick_time: *last_tick_time.lock().unwrap(),
                    entities: 0, // TODO: Implement entity count tracking
                    chunks_loaded: 0, // TODO: Implement chunk count tracking
                };

                metrics_guard.metrics.push(current_metrics);
                if metrics_guard.metrics.len() > metrics_guard.max_samples {
                    metrics_guard.metrics.remove(0);
                }
            }
        });
    }

    pub fn stop(&self) {
        let mut running = self.running.lock().unwrap();
        *running = false;
    }

    pub fn update_tick_time(&self, tick_time: f32) {
        let mut last_tick_time = self.last_tick_time.lock().unwrap();
        *last_tick_time = tick_time;
    }

    pub fn get_current_metrics(&self) -> Option<PerformanceMetrics> {
        let metrics = self.metrics.lock().unwrap();
        metrics.metrics.last().cloned()
    }

    pub fn get_metrics_history(&self) -> Vec<PerformanceMetrics> {
        let metrics = self.metrics.lock().unwrap();
        metrics.metrics.clone()
    }

    pub fn get_average_metrics(&self, duration: Duration) -> Option<PerformanceMetrics> {
        let metrics = self.metrics.lock().unwrap();
        let now = Instant::now();
        let relevant_metrics: Vec<_> = metrics.metrics
            .iter()
            .filter(|m| now.duration_since(now - Duration::from_secs(m.uptime)) <= duration)
            .collect();

        if relevant_metrics.is_empty() {
            return None;
        }

        let count = relevant_metrics.len() as f32;
        Some(PerformanceMetrics {
            cpu_usage: relevant_metrics.iter().map(|m| m.cpu_usage).sum::<f32>() / count,
            memory_usage: relevant_metrics.iter().map(|m| m.memory_usage).sum::<u64>() / count as u64,
            tps: relevant_metrics.iter().map(|m| m.tps).sum::<f32>() / count,
            player_count: relevant_metrics.iter().map(|m| m.player_count).sum::<u32>() / count as u32,
            uptime: relevant_metrics.last().unwrap().uptime,
            last_tick_time: relevant_metrics.iter().map(|m| m.last_tick_time).sum::<f32>() / count,
            entities: relevant_metrics.iter().map(|m| m.entities).sum::<u32>() / count as u32,
            chunks_loaded: relevant_metrics.iter().map(|m| m.chunks_loaded).sum::<u32>() / count as u32,
        })
    }

    pub fn get_peak_metrics(&self, duration: Duration) -> Option<PerformanceMetrics> {
        let metrics = self.metrics.lock().unwrap();
        let now = Instant::now();
        let relevant_metrics: Vec<_> = metrics.metrics
            .iter()
            .filter(|m| now.duration_since(now - Duration::from_secs(m.uptime)) <= duration)
            .collect();

        if relevant_metrics.is_empty() {
            return None;
        }

        Some(PerformanceMetrics {
            cpu_usage: relevant_metrics.iter().map(|m| m.cpu_usage).fold(0.0, f32::max),
            memory_usage: relevant_metrics.iter().map(|m| m.memory_usage).max().unwrap_or(0),
            tps: relevant_metrics.iter().map(|m| m.tps).fold(0.0, f32::max),
            player_count: relevant_metrics.iter().map(|m| m.player_count).max().unwrap_or(0),
            uptime: relevant_metrics.last().unwrap().uptime,
            last_tick_time: relevant_metrics.iter().map(|m| m.last_tick_time).fold(0.0, f32::max),
            entities: relevant_metrics.iter().map(|m| m.entities).max().unwrap_or(0),
            chunks_loaded: relevant_metrics.iter().map(|m| m.chunks_loaded).max().unwrap_or(0),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_performance_monitor() {
        let monitor = PerformanceMonitor::new(0);
        monitor.start().await;
        
        // Give it some time to collect metrics
        tokio::time::sleep(Duration::from_secs(2)).await;
        
        assert!(monitor.get_current_metrics().is_some());
        assert!(!monitor.get_metrics_history().is_empty());
        
        monitor.stop();
    }
} 