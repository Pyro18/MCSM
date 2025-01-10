namespace MCSM.Core.Models;

public class ServerStats
{
    public bool IsRunning { get; set; }
    public int CurrentPlayers { get; set; }
    public int MaxPlayers { get; set; }
    public long MemoryUsage { get; set; }
}