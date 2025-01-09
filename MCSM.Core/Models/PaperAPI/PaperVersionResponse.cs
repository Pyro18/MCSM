namespace MCSM.Core.Models.PaperAPI;

// GET /v2/projects/paper
public class ProjectResponse
{
    public string Project_id { get; set; }
    public string Project_name { get; set; }
    public List<string> Version_groups { get; set; }
    public List<string> Versions { get; set; }
}

// GET /v2/projects/paper/versions/{version}/builds
public class BuildsResponse
{
    public string Project_id { get; set; }
    public string Project_name { get; set; }
    public string Version { get; set; }
    public List<VersionBuild> Builds { get; set; }
}

public class VersionBuild
{
    public int Build { get; set; }
    public DateTime Time { get; set; }
    public string Channel { get; set; }
    public bool Promoted { get; set; }
    public List<Change> Changes { get; set; }
    public Dictionary<string, Download> Downloads { get; set; }
}

public class Change
{
    public string Commit { get; set; }
    public string Summary { get; set; }
    public string Message { get; set; }
}

public class Download
{
    public string Name { get; set; }
    public string Sha256 { get; set; }
}