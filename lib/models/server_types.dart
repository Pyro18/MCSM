enum ServerType {
  vanilla,
  paper,
  forge,
  fabric,
  spigot,
  bukkit;

  String get displayName {
    switch (this) {
      case ServerType.vanilla:
        return 'Vanilla';
      case ServerType.paper:
        return 'Paper';
      case ServerType.forge:
        return 'Forge';
      case ServerType.fabric:
        return 'Fabric';
      case ServerType.spigot:
        return 'Spigot';
      case ServerType.bukkit:
        return 'Bukkit';
    }
  }
}

enum ServerStatus {
  stopped,
  starting,
  running,
  stopping,
  error;

  String get displayName {
    switch (this) {
      case ServerStatus.stopped:
        return 'Stopped';
      case ServerStatus.starting:
        return 'Starting';
      case ServerStatus.running:
        return 'Running';
      case ServerStatus.stopping:
        return 'Stopping';
      case ServerStatus.error:
        return 'Error';
    }
  }

  bool get isRunning => this == ServerStatus.running;
  bool get isStopped => this == ServerStatus.stopped;
  bool get isTransitioning => 
    this == ServerStatus.starting || this == ServerStatus.stopping;
  bool get hasError => this == ServerStatus.error;
}