namespace MCSM.Core.Utils;

public class MinecraftVersionComparer : IComparer<string>
{
    public int Compare(string versionA, string versionB)
    {
        if (string.IsNullOrEmpty(versionA) && string.IsNullOrEmpty(versionB)) return 0;
        if (string.IsNullOrEmpty(versionA)) return -1;
        if (string.IsNullOrEmpty(versionB)) return 1;

        var partsA = versionA.Split('.');
        var partsB = versionB.Split('.');

        int length = Math.Max(partsA.Length, partsB.Length);

        for (int i = 0; i < length; i++)
        {
            int numA = i < partsA.Length && int.TryParse(partsA[i], out int a) ? a : 0;
            int numB = i < partsB.Length && int.TryParse(partsB[i], out int b) ? b : 0;

            if (numA != numB)
            {
                return numB.CompareTo(numA); // Ordine decrescente
            }
        }

        return 0;
    }
}