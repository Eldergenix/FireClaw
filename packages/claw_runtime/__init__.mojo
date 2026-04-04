# claw_runtime/ — Package init exporting all public symbols

# Core data models
from .models import (
    Subsystem,
    PortingModule,
    PermissionDenial,
    UsageSummary,
    PortingBacklog,
    new_porting_module,
    new_usage_summary,
    new_porting_backlog,
)

# Config and session
from .config import load_config, RuntimeConfig
from .prompt import discover_claw_files, assemble_system_prompt
from .session import create_session, Session, save_session

# Permissions and context
from .permissions import ToolPermissionContext
from .context import PortContext, build_port_context, render_context
from .history import HistoryLog
from .transcript import TranscriptStore, new_transcript
from .session_store import StoredSession

# Query engine
from .query_engine import (
    QueryEnginePort,
    QueryEngineConfig,
    TurnResult,
    StreamEvent,
    default_query_engine_config,
    from_workspace,
    submit_message,
    stream_submit_message,
    render_summary,
    flush_transcript,
    persist_session,
)

# Runtime
from .port_runtime import (
    PortRuntime,
    RuntimeSession,
    RoutedMatch,
)

# Command and tool registries
from .command_registry import (
    get_commands,
    get_command,
    find_commands,
    execute_command,
    command_names,
    built_in_command_names,
    build_command_backlog,
    render_command_index,
    load_command_snapshot,
    CommandExecution,
)
from .tool_registry import (
    get_tools,
    get_tool,
    find_tools,
    execute_tool,
    tool_names,
    build_tool_backlog,
    render_tool_index,
    load_tool_snapshot,
    ToolExecution,
)

# Setup and init
from .setup import (
    PrefetchResult,
    DeferredInitResult,
    WorkspaceSetup,
    SetupReport,
    start_mdm_raw_read,
    start_keychain_prefetch,
    start_project_scan,
    run_setup,
    build_system_init_message,
)

# Port manifest and parity
from .port_manifest import PortManifest, build_port_manifest
from .parity_audit import ParityAuditResult, run_parity_audit

# Execution registry
from .execution_registry import (
    ExecutionRegistry,
    MirroredCommand,
    MirroredTool,
    build_execution_registry,
)

# Cost tracking
from .cost_tracker import CostTracker, new_cost_tracker

# Misc utilities
from .misc import (
    QueryRequest,
    QueryResponse,
    ToolDefinition,
    default_tool_definitions,
    PortingTask,
    default_tasks,
    render_markdown_panel,
    DialogLauncher,
    default_dialog_launchers,
    bulletize,
    build_repl_banner,
    ProjectOnboardingState,
    new_project_onboarding_state,
)

# Graph and pool
from .bootstrap_graph import BootstrapGraph, build_bootstrap_graph
from .command_graph import CommandGraph, build_command_graph
from .tool_pool import ToolPool, assemble_tool_pool

# Mode simulations
from .direct_modes import DirectModeReport, run_direct_connect, run_deep_link
from .remote_runtime import (
    RuntimeModeReport,
    run_remote_mode,
    run_ssh_mode,
    run_teleport_mode,
)

# Background task support
from .background_tasks import (
    BackgroundTask,
    TaskManager,
    TaskResult,
    new_task_manager,
    format_task_list,
    format_task_detail,
)

# Structured IO and remote transport (Phase 5.1)
from .structured_io import (
    StructuredMessage,
    StructuredIOHandler,
    MessageBuffer,
    encode_message,
    decode_message,
    new_structured_handler,
)
from .remote_io import (
    RemoteSession,
    StdioTransport,
    FileTransport,
    TransportConfig,
    create_stdio_transport,
    create_file_transport,
    new_remote_session,
)

# Analytics integration (Phase 5.3)
from .analytics import (
    AnalyticsEvent,
    AnalyticsConfig,
    AnalyticsClient,
    default_analytics_config,
    disabled_analytics_config,
    new_analytics_client,
    format_analytics_report,
)

# Settings sync (Phase 5.4)
from .settings_sync import (
    SettingsEntry,
    SettingsStore,
    SyncResult,
    SettingsDiff,
    new_settings_store,
    default_settings,
    format_settings_table,
    format_sync_report,
)

# Team memory integration (Phase 5.6)
from .team_memory import (
    MemoryEntry,
    TeamMemoryStore,
    new_team_memory,
    format_memory_list,
    format_memory_detail,
    memory_categories,
    format_memory_context,
)
