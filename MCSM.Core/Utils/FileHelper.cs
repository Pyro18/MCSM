using System.Diagnostics;

namespace MCSM.Core.Utils;

public class FileHelper
{
    public async Task<string> ReadAllTextSafeAsync(string path)
    {
        if (!File.Exists(path))
            throw new FileNotFoundException($"File non trovato: {path}");

        using var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        using var sr = new StreamReader(fs);
        return await sr.ReadToEndAsync();
    }

    public async Task WriteAllTextSafeAsync(string path, string content)
    {
        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
            Directory.CreateDirectory(directory);

        using var fs = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None);
        using var sw = new StreamWriter(fs);
        await sw.WriteAsync(content);
    }

    public bool IsValidJavaInstallation(string javaPath)
    {
        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = javaPath,
                Arguments = "-version",
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(startInfo);
            var output = process?.StandardError.ReadToEnd();
            return output?.Contains("java version") ?? false;
        }
        catch
        {
            return false;
        }
    }

    public string GetJavaPath()
    {
        var javaHome = Environment.GetEnvironmentVariable("JAVA_HOME");
        if (!string.IsNullOrEmpty(javaHome))
        {
            var javaPath = Path.Combine(javaHome, "bin", "java.exe");
            if (File.Exists(javaPath))
                return javaPath;
        }

        return "java";
    }
}