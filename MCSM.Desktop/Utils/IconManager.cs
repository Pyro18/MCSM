using System.Drawing;
using MCSM.Core.Models;

namespace MCSM.Desktop.Utils;

public static class IconManager
{
    public static Bitmap GetServerIcon(ServerStatus status)
    {
        return status switch
        {
            ServerStatus.Running => CreateServerRunningIcon(),
            ServerStatus.Crashed => CreateServerCrashedIcon(),
            _ => CreateServerStoppedIcon()
        };
    }

    private static Bitmap CreateServerRunningIcon()
    {
        return CreateColoredCircleIcon(Color.Green);
    }

    private static Bitmap CreateServerStoppedIcon()
    {
        return CreateColoredCircleIcon(Color.Gray);
    }

    private static Bitmap CreateServerCrashedIcon()
    {
        return CreateColoredCircleIcon(Color.Red);
    }

    private static Bitmap CreateColoredCircleIcon(Color color)
    {
        var bitmap = new Bitmap(16, 16);
        using (var g = Graphics.FromImage(bitmap))
        {
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            using (var brush = new SolidBrush(color))
            {
                g.FillEllipse(brush, 2, 2, 12, 12);
            }
            using (var pen = new Pen(Color.FromArgb(100, Color.Black), 1))
            {
                g.DrawEllipse(pen, 2, 2, 12, 12);
            }
        }
        return bitmap;
    }
}