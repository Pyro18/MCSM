namespace MCSM.Core.Models;

public class LogEntry
{
    public DateTime Timestamp { get; set; }
    public string Message { get; set; }
    public LogLevel Level { get; set; }
    public string Source { get; set; }

    public enum LogLevel
    {
        Info,
        Warning,
        Error,
        Debug
    }
}