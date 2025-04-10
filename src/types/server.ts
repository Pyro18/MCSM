export interface ServerConfig {
  name: string;
  version: string;
  port: number;
  memory: string;
  path: string;
}

export interface ServerStatus {
  running: boolean;
  players: number;
  cpu_usage: number;
  memory_usage: number;
}

export interface ServerProcess {
  pid: number;
  status: 'running' | 'stopped' | 'starting' | 'stopping';
  startTime?: Date;
  lastBackup?: Date;
} 