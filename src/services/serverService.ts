import { invoke } from '@tauri-apps/api/core';
import { ServerConfig, ServerStatus } from '../types/server';

export const serverService = {
  async createServer(config: ServerConfig): Promise<string> {
    return await invoke('create_server', { config });
  },

  async startServer(serverPath: string): Promise<string> {
    return await invoke('start_server', { serverPath });
  },

  async stopServer(serverPath: string): Promise<string> {
    return await invoke('stop_server', { serverPath });
  },

  async getServerStatus(serverPath: string): Promise<ServerStatus> {
    return await invoke('get_server_status', { serverPath });
  },

  async getServerList(): Promise<ServerConfig[]> {
    return await invoke('get_server_list');
  },

  async deleteServer(serverPath: string): Promise<string> {
    return await invoke('delete_server', { serverPath });
  },

  async updateServerConfig(serverPath: string, config: Partial<ServerConfig>): Promise<string> {
    return await invoke('update_server_config', { serverPath, config });
  }
}; 