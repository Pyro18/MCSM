using System.Text.Json.Serialization;

namespace MCSM.Core.Models;

public class ServerInfo
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Name { get; set; } = "New Server";
    public string Version { get; set; }
    public bool IsPaperMC { get; set; } = true;
    public DateTime CreatedDate { get; set; } = DateTime.Now;
    public DateTime LastStarted { get; set; }
    public ServerStatus Status { get; set; } = ServerStatus.Stopped;
    public ServerConfig Config { get; set; } = new ServerConfig();
}

public enum ServerStatus
{
    Stopped,
    Running,
    Crashed,
    Starting,
    Stopping
}