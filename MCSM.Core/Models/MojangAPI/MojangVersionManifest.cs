namespace MCSM.Core.Models.MojangAPI;

public class MojangVersionManifest
{
    public List<MojangVersion>? Versions { get; set; }
}

public class MojangVersion
{
    public string Id { get; set; }
    public string Type { get; set; }
    public string Url { get; set; }
    public DateTime ReleaseTime { get; set; }
}

public class MojangVersionData
{
    public DownloadData? Downloads { get; set; }
}

public class DownloadData
{
    public DownloadInfo? Server { get; set; }
}

public class DownloadInfo
{
    public string Url { get; set; }
}