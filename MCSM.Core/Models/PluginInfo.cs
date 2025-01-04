namespace MCSM.Core.Models;

public class PluginInfo
{
    public string Name { get; set; }
    public string Version { get; set; }
    public string Author { get; set; }
    public string Description { get; set; }
    public bool IsEnabled { get; set; }
    public string FilePath { get; set; }
    public Dictionary<string, string> Configuration { get; set; }
}