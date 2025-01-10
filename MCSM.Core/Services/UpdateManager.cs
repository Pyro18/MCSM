using MCSM.Core.Models;
using MCSM.Core.Models.PaperAPI;
using MCSM.Core.Models.MojangAPI;
using MCSM.Core.Utils;
using System.Text.Json;

namespace MCSM.Core.Services;

/// <summary>
/// Manages server updates and downloads for both PaperMC and Vanilla Minecraft servers.
/// Implements IDisposable pattern for proper resource management.
/// </summary>
public class UpdateManager : IDisposable
{
    private readonly Logger _logger;
    private static readonly HttpClient _httpClient;
    private readonly string _versionsPath;
    private readonly PathManager _pathManager;

    private bool _isDisposed;

    private const string MOJANG_VERSION_MANIFEST = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json";
    private const string PAPERMC_API_BASE = "https://api.papermc.io/v2/projects/paper";
    
    
    
    #region Constructor and Static Constructor

    static UpdateManager()
    {
        _httpClient = new HttpClient
        {
            Timeout = TimeSpan.FromSeconds(30)
        };
        
        // Configurazione headers di default
        _httpClient.DefaultRequestHeaders.Add("User-Agent", "MCSM/1.0");
        _httpClient.DefaultRequestHeaders.Accept.Add(
            new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
    }

    public UpdateManager()
    {
        _pathManager = new PathManager();
        _logger = new Logger();
        _versionsPath = Path.Combine(Path.GetTempPath(), "MCSM_Downloads");
        
        if (!Directory.Exists(_versionsPath))
        {
            Directory.CreateDirectory(_versionsPath);
        }

        System.Net.ServicePointManager.SecurityProtocol = 
            System.Net.SecurityProtocolType.Tls12 | 
            System.Net.SecurityProtocolType.Tls13;
    }

    #endregion

    #region Public Methods

    /// <summary>
    /// Gets available server versions based on the selected server type.
    /// </summary>
    /// <param name="isPaperMC">If true, fetches PaperMC versions, otherwise fetches Vanilla versions</param>
    /// <returns>A list of available version strings</returns>
    public async Task<List<string>> GetAvailableVersions(bool isPaperMC = true)
    {
        ThrowIfDisposed();
        
        try
        {
            return isPaperMC ? 
                await GetPaperMCVersions() : 
                await GetMojangVersions();
        }
        catch (Exception ex)
        {
            _logger.Log($"Error retrieving versions: {ex}", LogEntry.LogLevel.Error);
            throw;
        }
    }

    /// <summary>
    /// Downloads the server JAR file for the specified version.
    /// </summary>
    /// <param name="version">The version to download</param>
    /// <param name="isPaperMC">If true, downloads PaperMC, otherwise downloads Vanilla</param>
    /// <returns>The path to the downloaded JAR file</returns>
    public async Task<string> DownloadServerJar(ServerInfo serverInfo)
    {
        ThrowIfDisposed();

        try
        {
            var serverDir = _pathManager.GetServerDirectory(serverInfo.Name);
        
            // Create server directory
            if (!Directory.Exists(serverDir))
            {
                Directory.CreateDirectory(serverDir);
                _logger.Log($"Created server directory: {serverDir}", LogEntry.LogLevel.Info);
            }

            if (serverInfo.IsPaperMC)
            {
                return await DownloadPaperMCServer(serverInfo);
            }
            return await DownloadVanillaServer(serverInfo);
        }
        catch (Exception ex)
        {
            _logger.Log($"Error downloading server: {ex}", LogEntry.LogLevel.Error);
            throw;
        }
    }

    /// <summary>
    /// Verifies if a specific version is valid and available.
    /// </summary>
    public async Task<bool> IsVersionValid(string version, bool isPaperMC = true)
    {
        ThrowIfDisposed();
        
        var versions = await GetAvailableVersions(isPaperMC);
        return versions.Contains(version);
    }

    #endregion

    #region Private Methods

    private async Task<List<string>> GetPaperMCVersions()
    {
        try
        {
            var versionsUrl = $"{PAPERMC_API_BASE}";
            _logger.Log($"Fetching PaperMC versions from: {versionsUrl}", LogEntry.LogLevel.Debug);

            using var response = await _httpClient.GetAsync(versionsUrl);
            response.EnsureSuccessStatusCode();
        
            var jsonContent = await response.Content.ReadAsStringAsync();
            _logger.Log($"Raw API Response: {jsonContent}", LogEntry.LogLevel.Debug);
        
            var projectData = JsonSerializer.Deserialize<PaperVersionResponse>(jsonContent);

            if (projectData?.Versions == null || !projectData.Versions.Any())
            {
                throw new Exception("No versions found for PaperMC.");
            }
            
            var comparer = new MinecraftVersionComparer();
            var sortedVersions = projectData.Versions
                .OrderBy(v => v, comparer)
                .ToList();

            _logger.Log($"Successfully fetched {sortedVersions.Count} PaperMC versions", LogEntry.LogLevel.Info);
            return sortedVersions;
        }
        catch (HttpRequestException ex)
        {
            _logger.Log($"Network error fetching PaperMC versions: {ex.Message}", LogEntry.LogLevel.Error);
            throw;
        }
        catch (JsonException ex)
        {
            _logger.Log($"JSON parsing error: {ex.Message}\nResponse content: {ex}", LogEntry.LogLevel.Error);
            throw;
        }
        catch (Exception ex)
        {
            _logger.Log($"Error fetching PaperMC versions: {ex.Message}", LogEntry.LogLevel.Error);
            throw;
        }
    }

    private async Task<List<string>> GetMojangVersions()
    {
        try
        {
            _logger.Log($"Requesting Mojang versions from: {MOJANG_VERSION_MANIFEST}", LogEntry.LogLevel.Debug);
            var response = await _httpClient.GetStringAsync(MOJANG_VERSION_MANIFEST);
            
            _logger.Log("Raw Mojang response received, parsing...", LogEntry.LogLevel.Debug);
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            
            var mojangData = JsonSerializer.Deserialize<MojangVersionManifest>(response, options);
            
            if (mojangData?.Versions == null || !mojangData.Versions.Any())
            {
                _logger.Log("No versions found in Mojang response", LogEntry.LogLevel.Warning);
                return new List<string>();
            }

            // Filtra solo le versioni release e ordina per data di rilascio
            var versions = mojangData.Versions
                .Where(v => v.Type.Equals("release", StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(v => v.ReleaseTime)
                .Select(v => v.Id)
                .ToList();

            _logger.Log($"Successfully fetched {versions.Count} Mojang release versions", LogEntry.LogLevel.Info);
            _logger.Log($"Available versions: {string.Join(", ", versions.Take(5))}", LogEntry.LogLevel.Debug);
            
            return versions;
        }
        catch (HttpRequestException ex)
        {
            _logger.Log($"Network error fetching Mojang versions: {ex.Message}", LogEntry.LogLevel.Error);
            throw new Exception("Failed to connect to Mojang servers. Please check your internet connection.", ex);
        }
        catch (JsonException ex)
        {
            _logger.Log($"Error parsing Mojang version manifest: {ex.Message}", LogEntry.LogLevel.Error);
            throw new Exception("Failed to parse Mojang version data", ex);
        }
        catch (Exception ex)
        {
            _logger.Log($"Unexpected error fetching Mojang versions: {ex.Message}", LogEntry.LogLevel.Error);
            throw;
        }
    }

    private async Task<string> DownloadPaperMCServer(ServerInfo serverInfo)
    {
        try
        {
            // Get builds for version
            var buildsUrl = $"{PAPERMC_API_BASE}/versions/{serverInfo.Version}/builds";
            _logger.Log($"Fetching builds from: {buildsUrl}", LogEntry.LogLevel.Debug);
            
            var buildsResponse = await _httpClient.GetStringAsync(buildsUrl);
            var buildsData = JsonSerializer.Deserialize<BuildsResponse>(buildsResponse);

            if (buildsData?.Builds == null || !buildsData.Builds.Any())
            {
                _logger.Log($"No builds found for version {serverInfo.Version}", LogEntry.LogLevel.Warning);
                throw new Exception($"No builds available for version {serverInfo.Version}");
            }

            // Get latest stable build
            var latestBuild = buildsData.Builds
                .Where(b => b.Channel == "default" && b.Downloads.ContainsKey("application"))
                .OrderByDescending(b => b.Build)
                .FirstOrDefault();
                
            if (latestBuild == null)
            {
                _logger.Log($"No stable builds found for version {serverInfo.Version}", LogEntry.LogLevel.Warning);
                throw new Exception($"No stable builds available for version {serverInfo.Version}. This version might be too new or not released yet.");
            }

            var buildNumber = latestBuild.Build;
            var downloadFileName = latestBuild.Downloads["application"].Name;
            
            // Get the jar path with build number
            var jarPath = _pathManager.GetServerJarPath(serverInfo.Name, serverInfo.Version, true, buildNumber);
            
            // Check if this exact build already exists
            if (File.Exists(jarPath))
            {
                _logger.Log($"Build {buildNumber} already exists at {jarPath}", LogEntry.LogLevel.Info);
                return jarPath;
            }

            // Download the jar
            var downloadUrl = $"{PAPERMC_API_BASE}/versions/{serverInfo.Version}/builds/{buildNumber}/downloads/{downloadFileName}";
            _logger.Log($"Downloading from: {downloadUrl}", LogEntry.LogLevel.Debug);

            var jarBytes = await _httpClient.GetByteArrayAsync(downloadUrl);
            await File.WriteAllBytesAsync(jarPath, jarBytes);

            _logger.Log($"Successfully downloaded PaperMC version {serverInfo.Version} (build {buildNumber})", LogEntry.LogLevel.Info);
            
            // Clean up old builds
            CleanupOldBuilds(Path.GetDirectoryName(jarPath), serverInfo.Version);
            
            return jarPath;
        }
        catch (HttpRequestException ex)
        {
            _logger.Log($"Network error downloading PaperMC server: {ex.Message}", LogEntry.LogLevel.Error);
            throw new Exception($"Failed to download server: {ex.Message}", ex);
        }
        catch (Exception ex)
        {                       
            _logger.Log($"Error downloading PaperMC server: {ex}", LogEntry.LogLevel.Error);
            throw;
        }
    }

    private async Task<string> DownloadVanillaServer(ServerInfo serverInfo)
    {
        var jarPath = _pathManager.GetServerJarPath(serverInfo.Name, serverInfo.Version, false);
        
        if (File.Exists(jarPath))
        {
            _logger.Log($"Vanilla version {serverInfo.Version} already exists at {jarPath}", LogEntry.LogLevel.Info);
            return jarPath;
        }

        try
        {
            // Step 1: Get version manifest
            _logger.Log("Fetching Mojang version manifest...", LogEntry.LogLevel.Debug);
            var manifestResponse = await _httpClient.GetStringAsync(MOJANG_VERSION_MANIFEST);
            var manifest = JsonSerializer.Deserialize<MojangVersionManifest>(manifestResponse);
            
            // Step 2: Find the specific version
            var versionInfo = manifest?.Versions?.FirstOrDefault(v => v.Id == serverInfo.Version) 
                ?? throw new Exception($"Version {serverInfo.Version} not found in manifest");

            // Step 3: Get version specific details using the URL from the manifest
            _logger.Log($"Fetching version details from: {versionInfo.Url}", LogEntry.LogLevel.Debug);
            var versionResponse = await _httpClient.GetStringAsync(versionInfo.Url);
            var versionData = JsonSerializer.Deserialize<MojangVersionData>(versionResponse);
            
            if (versionData?.Downloads?.Server?.Url == null)
            {
                throw new Exception($"No server download found for version {serverInfo.Version}");
            }

            // Step 4: Download the server jar
            var downloadUrl = versionData.Downloads.Server.Url;
            _logger.Log($"Downloading server jar from: {downloadUrl}", LogEntry.LogLevel.Info);
            
            var jarBytes = await _httpClient.GetByteArrayAsync(downloadUrl);
            await File.WriteAllBytesAsync(jarPath, jarBytes);
            
            _logger.Log($"Successfully downloaded vanilla server version {serverInfo.Version} to {jarPath}", LogEntry.LogLevel.Info);
            return jarPath;
        }
        catch (HttpRequestException ex)
        {
            _logger.Log($"Network error downloading vanilla server: {ex.Message}", LogEntry.LogLevel.Error);
            if (File.Exists(jarPath)) 
            {
                try { File.Delete(jarPath); } catch { /* ignore cleanup errors */ }
            }
            throw new Exception($"Failed to download server: {ex.Message}", ex);
        }
        catch (Exception ex)
        {
            _logger.Log($"Error downloading vanilla server: {ex.Message}", LogEntry.LogLevel.Error);
            if (File.Exists(jarPath))
            {
                try { File.Delete(jarPath); } catch { /* ignore cleanup errors */ }
            }
            throw;
        }
    }
    
    
    private void CleanupOldBuilds(string directory, string version)
    {
        try
        {
            var files = Directory.GetFiles(directory, $"paper-{version}-*.jar")
                .OrderByDescending(f => _pathManager.GetBuildNumberFromJar(f))
                .Skip(1); // Keep the latest build
        
            foreach (var file in files)
            {
                try
                {
                    File.Delete(file);
                    _logger.Log($"Deleted old build: {Path.GetFileName(file)}", LogEntry.LogLevel.Info);
                }
                catch (Exception ex)
                {
                    _logger.Log($"Error deleting old build {file}: {ex.Message}", LogEntry.LogLevel.Warning);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.Log($"Error during cleanup: {ex.Message}", LogEntry.LogLevel.Warning);
        }
    }
    
    private void ThrowIfDisposed()
    {
        if (_isDisposed)
        {
            throw new ObjectDisposedException(nameof(UpdateManager));
        }
    }

    #endregion
    
    

    #region IDisposable Implementation

    protected virtual void Dispose(bool disposing)
    {
        if (!_isDisposed)
        {
            if (disposing)
            {
                // HttpClient è statico, quindi non lo disponiamo qui
                _isDisposed = true;
            }
        }
    }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    #endregion
}