using MCSM.Core.Models;
using MCSM.Core.Services;
using MCSM.Desktop.Utils;

namespace MCSM.Desktop.Controls;

public class ServerListControl : UserControl
{
    private readonly ServerListManager _serverListManager;
    private readonly ListView _serverListView;
    private readonly ImageList _imageList;
    
    public event EventHandler<ServerInfo> OnServerSelected;
    
    public ServerListControl(ServerListManager serverListManager)
    {
        _serverListManager = serverListManager;
        
        // Initialize ImageList
        _imageList = new ImageList
        {
            ColorDepth = ColorDepth.Depth32Bit,
            ImageSize = new Size(16, 16)
        };
        _imageList.Images.Add("running", IconManager.GetServerIcon(ServerStatus.Running));
        _imageList.Images.Add("stopped", IconManager.GetServerIcon(ServerStatus.Stopped));
        _imageList.Images.Add("crashed", IconManager.GetServerIcon(ServerStatus.Crashed));
        
        // Initialize ListView
        _serverListView = new ListView
        {
            Dock = DockStyle.Fill,
            View = View.Details,
            FullRowSelect = true,
            GridLines = true,
            SmallImageList = _imageList,
            MultiSelect = false
        };
        
        _serverListView.Columns.Add("Name", 150);
        _serverListView.Columns.Add("Version", 100);
        _serverListView.Columns.Add("Type", 80);
        _serverListView.Columns.Add("Status", 80);
        _serverListView.Columns.Add("Last Started", 120);
        
        _serverListView.SelectedIndexChanged += ServerListView_SelectedIndexChanged;
        
        // Add context menu
        var contextMenu = new ContextMenuStrip();
        var startItem = contextMenu.Items.Add("Start Server", null, async (s, e) => await StartSelectedServer());
        var stopItem = contextMenu.Items.Add("Stop Server", null, async (s, e) => await StopSelectedServer());
        contextMenu.Items.Add("-");
        var deleteItem = contextMenu.Items.Add("Delete Server", null, async (s, e) => await DeleteSelectedServer());
        
        // Enable/disable context menu items based on server status
        contextMenu.Opening += (s, e) =>
        {
            if (_serverListView.SelectedItems.Count > 0 && 
                _serverListView.SelectedItems[0].Tag is ServerInfo server)
            {
                bool isRunning = server.Status == ServerStatus.Running;
                startItem.Enabled = !isRunning;
                stopItem.Enabled = isRunning;
                deleteItem.Enabled = !isRunning;
            }
            else
            {
                e.Cancel = true;
            }
        };
        
        _serverListView.ContextMenuStrip = contextMenu;
        
        // Subscribe to server list events
        _serverListManager.OnServerAdded += (s, server) => RefreshServerList();
        _serverListManager.OnServerRemoved += (s, server) => RefreshServerList();
        _serverListManager.OnServerStatusChanged += (s, server) => RefreshServerList();
        
        Controls.Add(_serverListView);
        RefreshServerList();
    }
    
    private void RefreshServerList()
    {
        if (InvokeRequired)
        {
            Invoke(RefreshServerList);
            return;
        }
        
        var selectedServer = _serverListView.SelectedItems.Count > 0 ? 
            (_serverListView.SelectedItems[0].Tag as ServerInfo)?.Id : null;
        
        _serverListView.BeginUpdate();
        _serverListView.Items.Clear();
        
        var servers = _serverListManager.GetServers();
        foreach (var server in servers)
        {
            var item = new ListViewItem(server.Name);
            item.SubItems.Add(server.Version);
            item.SubItems.Add(server.IsPaperMC ? "PaperMC" : "Vanilla");
            item.SubItems.Add(server.Status.ToString());
            item.SubItems.Add(server.LastStarted > DateTime.MinValue ? 
                server.LastStarted.ToString("g") : "Never");
            
            item.ImageKey = server.Status switch
            {
                ServerStatus.Running => "running",
                ServerStatus.Crashed => "crashed",
                _ => "stopped"
            };
            
            item.Tag = server;
            _serverListView.Items.Add(item);
            
            // Restore selection
            if (server.Id == selectedServer)
            {
                item.Selected = true;
            }
        }
        
        _serverListView.EndUpdate();
        
        // If no items are selected but we have servers, select the first one
        if (_serverListView.SelectedItems.Count == 0 && _serverListView.Items.Count > 0)
        {
            _serverListView.Items[0].Selected = true;
        }
    }
    
    private void ServerListView_SelectedIndexChanged(object sender, EventArgs e)
    {
        if (_serverListView.SelectedItems.Count > 0 && 
            _serverListView.SelectedItems[0].Tag is ServerInfo server)
        {
            OnServerSelected?.Invoke(this, server);
        }
    }
    
    private async Task StartSelectedServer()
    {
        if (_serverListView.SelectedItems.Count > 0 && 
            _serverListView.SelectedItems[0].Tag is ServerInfo server)
        {
            try
            {
                Cursor = Cursors.WaitCursor;
                await _serverListManager.StartServer(server.Id);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Error starting server: {ex.Message}",
                    "Error",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
            finally
            {
                Cursor = Cursors.Default;
            }
        }
    }
    
    private async Task StopSelectedServer()
    {
        if (_serverListView.SelectedItems.Count > 0 && 
            _serverListView.SelectedItems[0].Tag is ServerInfo server)
        {
            try
            {
                Cursor = Cursors.WaitCursor;
                await _serverListManager.StopServer(server.Id);
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    $"Error stopping server: {ex.Message}",
                    "Error",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
            finally
            {
                Cursor = Cursors.Default;
            }
        }
    }
    
    private async Task DeleteSelectedServer()
    {
        if (_serverListView.SelectedItems.Count > 0 && 
            _serverListView.SelectedItems[0].Tag is ServerInfo server)
        {
            var result = MessageBox.Show(
                $"Are you sure you want to delete the server '{server.Name}'?\nThis will delete all server files.",
                "Confirm Delete",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning);
                
            if (result == DialogResult.Yes)
            {
                try
                {
                    Cursor = Cursors.WaitCursor;
                    await _serverListManager.DeleteServer(server.Id);
                }
                catch (Exception ex)
                {
                    MessageBox.Show(
                        $"Error deleting server: {ex.Message}",
                        "Error",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error);
                }
                finally
                {
                    Cursor = Cursors.Default;
                }
            }
        }
    }
    
    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _imageList?.Dispose();
        }
        base.Dispose(disposing);
    }
}