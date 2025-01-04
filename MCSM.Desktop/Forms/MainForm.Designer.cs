using System.ComponentModel;
using System.Windows.Forms;

namespace MCSM.Desktop.Forms;

partial class MainForm
{
    /// <summary>
    /// Required designer variable.
    /// </summary>
    private IContainer components = null;

    /// <summary>
    /// Clean up any resources being used.
    /// </summary>
    /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
    protected override void Dispose(bool disposing)
    {
        if (disposing && (components != null))
        {
            components.Dispose();
        }

        base.Dispose(disposing);
    }

    #region Windows Form Designer generated code

    /// <summary>
    /// Required method for Designer support - do not modify
    /// the contents of this method with the code editor.
    /// </summary>
    private void InitializeComponent()
    {
        components = new Container();
        
        // Configurazione base del form
        AutoScaleMode = AutoScaleMode.Font;
        ClientSize = new System.Drawing.Size(1024, 768);
        MinimumSize = new System.Drawing.Size(800, 600);
        Text = "MCSM - Minecraft Server Manager";
        StartPosition = FormStartPosition.CenterScreen;
        
        // Stile del form
        FormBorderStyle = FormBorderStyle.Sizable;
        MaximizeBox = true;
        MinimizeBox = true;
        ShowIcon = true;
        
        // Menu principale e pannelli verranno aggiunti qui
        
        // Forza il ridisegno dei controlli
        PerformLayout();
    }

    #endregion
}