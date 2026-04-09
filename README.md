# VoyagerLogger

VoyagerLogger is a lightweight Swift logging package for Apple platforms. It provides a small `LogDestination` protocol, convenience APIs for the common log levels, and an `AppLogger` composite logger that can fan out the same message to multiple destinations.

The package includes built-in destinations for Unified Logging with `OSLog`, rolling file logging for persisted diagnostics, a null destination for no-op behavior, and a spy destination for tests. It also ships with `LogFileExporter`, which can collect generated `.log` files and export them as a merged file or zip archive for sharing and support workflows.
