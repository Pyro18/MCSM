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
    private const string PAPERMC_API_BASE = "https://api.papermc.io/v2/projects/paper";

    public UpdateManager()
    {
        _logger = new Logger();
        _versionsPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "versions");
        _httpClient = new HttpClient();
        _httpClient.DefaultRequestHeaders.Add("User-Agent", "MCSM/1.0");
        
        if (!Directory.Exists(_versionsPath))
            Directory.CreateDirectory(_versionsPath);
    }

    private async Task<string> DownloadPaperMCServer(string version)
    {
        var jarPath = Path.Combine(_versionsPath, $"paper-{version}.jar");
        
        if (File.Exists(jarPath))
        {
            _logger.Log($"PaperMC version {version} already downloaded at {jarPath}", LogEntry.LogLevel.Info);
            return jarPath;
        }

        try
        {
            var buildsUrl = $"{PAPERMC_API_BASE}/versions/{version}/builds";
            _logger.Log($"Fetching builds from: {buildsUrl}", LogEntry.LogLevel.Debug);
            
            var buildsResponse = await _httpClient.GetStringAsync(buildsUrl);
            _logger.Log($"Builds response: {buildsResponse}", LogEntry.LogLevel.Debug);
            
            var buildData = JsonSerializer.Deserialize<BuildsResponse>(buildsResponse);
            
            if (buildData?.Builds == null || !buildData.Builds.Any())
            {
                throw new Exception($"No builds found for version {version}");
            }
            
            var latestBuild = buildData.Builds
                .Where(b => b.Channel == "default" && b.Downloads.ContainsKey("application"))
                .OrderByDescending(b => b.Build)
                .FirstOrDefault() 
                ?? throw new Exception($"No suitable builds found for version {version}");
            
            var buildNumber = latestBuild.Build;
            var downloadFileName = $"paper-{version}-{buildNumber}.jar";
            var downloadUrl = $"{PAPERMC_API_BASE}/versions/{version}/builds/{buildNumber}/downloads/{downloadFileName}";

            _logger.Log($"Downloading from: {downloadUrl}", LogEntry.LogLevel.Debug);
            
            var response = await _httpClient.GetAsync(downloadUrl);
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                throw new Exception($"Download failed ({response.StatusCode}): {error}");
            }

            var jarBytes = await response.Content.ReadAsByteArrayAsync();
            await File.WriteAllBytesAsync(jarPath, jarBytes);
            
            _logger.Log($"Successfully downloaded PaperMC version {version} (build {buildNumber})", LogEntry.LogLevel.Info);
            return jarPath;
        }
        catch (Exception ex)
        {
            _logger.Log($"Error downloading PaperMC server: {ex}", LogEntry.LogLevel.Error);
            throw;
        }
    }

    public async Task<List<string>> GetAvailableVersions(bool isPaperMC = true)
    {
        try
        {
            if (isPaperMC)
            {
                var response = await _httpClient.GetStringAsync(PAPERMC_API_BASE);
                _logger.Log($"PaperMC API Response: {response}", LogEntry.LogLevel.Debug);
                
                var paperData = JsonSerializer.Deserialize<ProjectResponse>(response);
                
                if (paperData?.Versions == null || !paperData.Versions.Any())
                {
                    _logger.Log("No versions found in PaperMC response", LogEntry.LogLevel.Warning);
                    return new List<string>();
                }

                return paperData.Versions
                    .Where(v => !v.Contains("pre"))
                    .OrderByDescending(Version.Parse)
                    .ToList();
            }
            else
            {
                return await GetMojangVersions();
            }
        }
        catch (Exception ex)
        {
            _logger.Log($"Error retrieving versions: {ex}", LogEntry.LogLevel.Error);
            throw;
        }
    }


    private async Task<List<string>> GetPaperMCVersions()
    {
        try
        {
            var response = await _httpClient.GetStringAsync(PAPERMC_API_BASE);
            _logger.Log($"PaperMC API Response: {response}", LogEntry.LogLevel.Debug);
        
            var projectData = JsonSerializer.Deserialize<ProjectResponse>(response);
        
            if (projectData?.Versions == null || !projectData.Versions.Any())
            {
                _logger.Log("No versions found in PaperMC response", LogEntry.LogLevel.Warning);
                return new List<string>();
            }

            var versions = projectData.Versions
                .Where(v => !v.Contains("pre") && !v.Contains("snapshot"))
                .OrderByDescending(v => Version.Parse(v))
                .ToList();

            _logger.Log($"Found {versions.Count} available PaperMC versions", LogEntry.LogLevel.Info);
            return versions;
        }
        catch (HttpRequestException ex)
        {
            _logger.Log($"HTTP error fetching PaperMC versions: {ex.Message}", LogEntry.LogLevel.Error);
            throw new Exception("Failed to retrieve PaperMC versions. Check your internet connection.", ex);
        }
        catch (JsonException ex)
        {
            _logger.Log($"Error parsing PaperMC response: {ex.Message}", LogEntry.LogLevel.Error);
            throw new Exception("Failed to parse PaperMC version information.", ex);
        }
        catch (Exception ex)
        {
            _logger.Log($"Unexpected error fetching PaperMC versions: {ex}", LogEntry.LogLevel.Error);
            throw new Exception("An unexpected error occurred while retrieving PaperMC versions.", ex);
        }
    }


    private async Task<List<string>> GetMojangVersions()
    {
        try
        {
            _logger.Log($"Richiesta a: {MOJANG_VERSION_MANIFEST}", LogEntry.LogLevel.Debug);
            using var request = new HttpRequestMessage(HttpMethod.Get, MOJANG_VERSION_MANIFEST);
            using var response = await _httpClient.SendAsync(request);
            
            _logger.Log($"Stato risposta Mojang: {response.StatusCode}", LogEntry.LogLevel.Debug);
            response.EnsureSuccessStatusCode();
            
            var content = await response.Content.ReadAsStringAsync();
            _logger.Log($"Contenuto risposta Mojang: {content}", LogEntry.LogLevel.Debug);
            
            var mojangData = JsonSerializer.Deserialize<MojangVersionManifest>(content);
            
            if (mojangData?.Versions == null || !mojangData.Versions.Any())
            {
                _logger.Log("Nessuna versione trovata nella risposta Mojang", LogEntry.LogLevel.Warning);
                return new List<string>();
            }

            var versions = mojangData.Versions
                .Where(v => v.Type == "release")
                .OrderByDescending(v => v.ReleaseTime)
                .Take(10)
                .Select(v => v.Id)
                .ToList();

            _logger.Log($"Versioni Mojang filtrate: {string.Join(", ", versions)}", LogEntry.LogLevel.Info);
            return versions;
        }
        catch (Exception ex)
        {
            _logger.Log($"Errore nel recupero versioni Mojang: {ex}", LogEntry.LogLevel.Error);
            throw;
        }
    }

    public async Task<string> DownloadServerJar(string version, bool isPaperMC = true)
    {
        if (isPaperMC)
        {
            try
            {
                return await DownloadPaperMCServer(version);
            }
            catch (Exception ex)
            {
                _logger.Log($"Failed to download PaperMC server: {ex.Message}. Trying vanilla server...", LogEntry.LogLevel.Warning);
            }
        }

        return await DownloadVanillaServer(version);
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