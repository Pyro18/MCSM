using MCSM.Core.Models;
using MCSM.Core.Models.PaperAPI;
using MCSM.Core.Models.MojangAPI;
using MCSM.Core.Utils;
using System.Net.Http;
using System.Text.Json;

namespace MCSM.Core.Services;

public class UpdateManager
{
    private readonly Logger _logger;
    private readonly string _versionsPath;
    private readonly HttpClient _httpClient;
    private const string MOJANG_VERSION_MANIFEST = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json";
    private const string PAPERMC_API = "https://api.papermc.io/v2/projects/paper";

    public UpdateManager()
    {
        _logger = new Logger();
        _versionsPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "versions");
        _httpClient = new HttpClient();
        
        if (!Directory.Exists(_versionsPath))
            Directory.CreateDirectory(_versionsPath);
    }

    public async Task<List<string>> GetAvailableVersions()
    {
        try
        {
            // First try to get versions from PaperMC API
            var paperVersions = await GetPaperMCVersions();
            if (paperVersions.Any())
                return paperVersions;

            // Fallback to Mojang versions if PaperMC fails
            return await GetMojangVersions();
        }
        catch (Exception ex)
        {
            _logger.Log($"Error retrieving versions: {ex.Message}", LogEntry.LogLevel.Error);
            // Return some fallback versions in case both APIs fail
            return new List<string> { "1.20.4", "1.20.2", "1.19.4" };
        }
    }

    private async Task<List<string>> GetPaperMCVersions()
    {
        try
        {
            var response = await _httpClient.GetStringAsync(PAPERMC_API);
            var paperData = JsonSerializer.Deserialize<PaperVersionResponse>(response);
            
            return paperData?.Versions?
                .Where(v => !v.Contains("snapshot") && !v.Contains("pre"))
                .OrderByDescending(Version.Parse)
                .Take(10)
                .ToList() ?? new List<string>();
        }
        catch (Exception ex)
        {
            _logger.Log($"Error retrieving PaperMC versions: {ex.Message}", LogEntry.LogLevel.Warning);
            return new List<string>();
        }
    }

    private async Task<List<string>> GetMojangVersions()
    {
        try
        {
            var response = await _httpClient.GetStringAsync(MOJANG_VERSION_MANIFEST);
            var mojangData = JsonSerializer.Deserialize<MojangVersionManifest>(response);
            
            return mojangData?.Versions?
                .Where(v => v.Type == "release")
                .OrderByDescending(v => v.ReleaseTime)
                .Take(10)
                .Select(v => v.Id)
                .ToList() ?? new List<string>();
        }
        catch (Exception ex)
        {
            _logger.Log($"Error retrieving Mojang versions: {ex.Message}", LogEntry.LogLevel.Error);
            return new List<string>();
        }
    }

    public async Task<string> DownloadServerJar(string version)
    {
        // Try PaperMC first
        try
        {
            return await DownloadPaperMCServer(version);
        }
        catch (Exception ex)
        {
            _logger.Log($"Failed to download PaperMC server: {ex.Message}. Trying vanilla server...", LogEntry.LogLevel.Warning);
        }

        // Fallback to vanilla server
        return await DownloadVanillaServer(version);
    }

    private async Task<string> DownloadPaperMCServer(string version)
    {
        var jarPath = Path.Combine(_versionsPath, $"paper-{version}.jar");
        
        if (File.Exists(jarPath))
        {
            _logger.Log($"PaperMC version {version} already downloaded at {jarPath}", LogEntry.LogLevel.Info);
            return jarPath;
        }

        // Get latest build number for the version
        var buildsResponse = await _httpClient.GetStringAsync($"{PAPERMC_API}/versions/{version}");
        var buildData = JsonSerializer.Deserialize<PaperBuildsResponse>(buildsResponse);
        var latestBuild = buildData?.Builds?.Max() ?? throw new Exception("No builds found");

        // Download the server jar
        var downloadUrl = $"{PAPERMC_API}/versions/{version}/builds/{latestBuild}/downloads/paper-{version}-{latestBuild}.jar";
        var jarBytes = await _httpClient.GetByteArrayAsync(downloadUrl);
        
        await File.WriteAllBytesAsync(jarPath, jarBytes);
        _logger.Log($"Successfully downloaded PaperMC version {version} (build {latestBuild}) to {jarPath}", LogEntry.LogLevel.Info);
        
        return jarPath;
    }

    private async Task<string> DownloadVanillaServer(string version)
    {
        var jarPath = Path.Combine(_versionsPath, $"minecraft_server.{version}.jar");
        
        if (File.Exists(jarPath))
        {
            _logger.Log($"Vanilla version {version} already downloaded at {jarPath}", LogEntry.LogLevel.Info);
            return jarPath;
        }

        // Get version manifest
        var manifestResponse = await _httpClient.GetStringAsync(MOJANG_VERSION_MANIFEST);
        var manifest = JsonSerializer.Deserialize<MojangVersionManifest>(manifestResponse);
        
        // Find the specific version
        var versionInfo = manifest?.Versions?.FirstOrDefault(v => v.Id == version) 
            ?? throw new Exception($"Version {version} not found in manifest");

        // Get version details
        var versionResponse = await _httpClient.GetStringAsync(versionInfo.Url);
        var versionData = JsonSerializer.Deserialize<MojangVersionData>(versionResponse);
        
        if (string.IsNullOrEmpty(versionData?.Downloads?.Server?.Url))
            throw new Exception($"No server download available for version {version}");

        // Download the server jar
        var jarBytes = await _httpClient.GetByteArrayAsync(versionData.Downloads.Server.Url);
        await File.WriteAllBytesAsync(jarPath, jarBytes);
        
        _logger.Log($"Successfully downloaded vanilla server version {version} to {jarPath}", LogEntry.LogLevel.Info);
        return jarPath;
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}