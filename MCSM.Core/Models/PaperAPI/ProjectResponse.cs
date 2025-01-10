using System.Text.Json.Serialization;

namespace MCSM.Core.Models.PaperAPI;

public class PaperVersionResponse
{
    [JsonPropertyName("project_id")]
    public string ProjectId { get; set; }

    [JsonPropertyName("project_name")]
    public string ProjectName { get; set; }

    [JsonPropertyName("version_groups")]
    public List<string> VersionGroups { get; set; }

    [JsonPropertyName("versions")]
    public List<string> Versions { get; set; }
}

public class BuildsResponse
{
    [JsonPropertyName("project_id")]
    public string ProjectId { get; set; }

    [JsonPropertyName("project_name")]
    public string ProjectName { get; set; }

    [JsonPropertyName("version")]
    public string Version { get; set; }

    [JsonPropertyName("builds")]
    public List<VersionBuild> Builds { get; set; }
}

public class VersionBuild
{
    [JsonPropertyName("build")]
    public int Build { get; set; }

    [JsonPropertyName("time")]
    public DateTime Time { get; set; }

    [JsonPropertyName("channel")]
    public string Channel { get; set; }

    [JsonPropertyName("promoted")]
    public bool Promoted { get; set; }

    [JsonPropertyName("changes")]
    public List<Change> Changes { get; set; }

    [JsonPropertyName("downloads")]
    public Dictionary<string, Download> Downloads { get; set; }
}

public class Change
{
    [JsonPropertyName("commit")]
    public string Commit { get; set; }

    [JsonPropertyName("summary")]
    public string Summary { get; set; }

    [JsonPropertyName("message")]
    public string Message { get; set; }
}

public class Download
{
    [JsonPropertyName("name")]
    public string Name { get; set; }

    [JsonPropertyName("sha256")]
    public string Sha256 { get; set; }
}