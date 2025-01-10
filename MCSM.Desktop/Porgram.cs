using System.Net;
using MCSM.Desktop.Forms;

namespace MCSM.Desktop;

static class Program
{
    [STAThread]
    static void Main()
    {
        // Configure TLS 1.2
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls13;
        
        ApplicationConfiguration.Initialize();
        Application.Run(new MainForm());
    }
}