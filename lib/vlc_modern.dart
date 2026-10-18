library vlc_modern;

export 'src/ffi/vlc_bindings.dart';
export 'src/controller/vlc_player_controller.dart';

// Theme & Design Tokens (Phase 2)
export 'theme/vlc_colors.dart';
export 'theme/vlc_geometry.dart';
export 'theme/vlc_typography.dart';
export 'theme/vlc_icons.dart';
export 'theme/vlc_theme.dart';

// UI Shell (Phase 2)
export 'ui/shell/app_shell.dart';
export 'ui/shell/top_player_bar.dart';
export 'ui/shell/osd_notification_layer.dart';

// UI Controls (Phase 2)
export 'ui/controls/volume_control.dart';
export 'ui/controls/bottom_transport_row.dart';
export 'ui/controls/thick_seek_bar.dart';

// Phase 3 Models & Popups & Drawer
export 'models/subtitle_models.dart';
export 'models/audio_models.dart';
export 'models/queue_models.dart';
export 'ui/popups/subtitle_quick_popup.dart';
export 'ui/popups/add_subtitles_modal.dart';
export 'ui/popups/audio_quick_popup.dart';
export 'ui/drawer/queue_drawer.dart';
