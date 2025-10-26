//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <media_kit_libs_windows_audio/media_kit_libs_windows_audio_plugin_c_api.h>
#include <taglib_ffi_dart_libs/taglib_ffi_dart_libs_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  MediaKitLibsWindowsAudioPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("MediaKitLibsWindowsAudioPluginCApi"));
  TaglibFfiDartLibsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("TaglibFfiDartLibsPluginCApi"));
}
