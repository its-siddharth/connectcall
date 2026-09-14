import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/call_model.dart';

/// Wraps all ZegoCloud SDK initialisation.
///
/// Call [ZegoService.init] once after login and [ZegoService.uninit] on logout.
/// The signalling plugin gives push-style incoming-call notifications between
/// two real devices without a custom server.
class ZegoService {
  ZegoService._();
  static final ZegoService instance = ZegoService._();

  bool _initialised = false;
  bool get isInitialised => _initialised;

  /// True when the developer has supplied real Zego credentials.
  static bool get isConfigured =>
      AppConstants.zegoAppId != 0 && AppConstants.zegoAppSign.isNotEmpty;

  // ── Initialise ─────────────────────────────────────────────────────────────

  /// Must be called after a successful login.
  Future<void> init({
    required UserModel user,
    required BuildContext context,
  }) async {
    if (!isConfigured) return;
    if (_initialised) return;

    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: AppConstants.zegoAppId,
      userID: user.id,
      userName: user.name,
      // The signalling plugin handles WebRTC signalling between devices
      plugins: [ZegoUIKitSignalingPlugin()],
      requireConfig: (ZegoCallInvitationData data) {
        final isVideo = data.type == ZegoCallInvitationType.videoCall;
        final config = isVideo
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
        config.bottomMenuBar = ZegoCallBottomMenuBarConfig(
          buttons: isVideo
              ? [
                  ZegoCallMenuBarButtonName.toggleMicrophoneButton,
                  ZegoCallMenuBarButtonName.hangUpButton,
                  ZegoCallMenuBarButtonName.toggleCameraButton,
                  ZegoCallMenuBarButtonName.switchCameraButton,
                  ZegoCallMenuBarButtonName.switchAudioOutputButton,
                ]
              : [
                  ZegoCallMenuBarButtonName.toggleMicrophoneButton,
                  ZegoCallMenuBarButtonName.hangUpButton,
                  ZegoCallMenuBarButtonName.switchAudioOutputButton,
                ],
        );
        return config;
      },
      notificationConfig: ZegoCallInvitationNotificationConfig(
        androidNotificationConfig: ZegoCallAndroidNotificationConfig(
          callChannel: ZegoCallAndroidNotificationChannelConfig(
            channelID: 'ConnectCall',
            channelName: 'Incoming Calls',
          ),
        ),
      ),
    );

    _initialised = true;
  }

  // ── Uninitialise ────────────────────────────────────────────────────────────

  Future<void> uninit() async {
    if (!isConfigured) return;
    if (!_initialised) return;
    await ZegoUIKitPrebuiltCallInvitationService().uninit();
    _initialised = false;
  }

  // ── Build Zego call widgets ─────────────────────────────────────────────────

  /// Audio-only 1-to-1 call widget.
  static Widget buildAudioCall({
    required CallModel call,
    required UserModel currentUser,
    required VoidCallback onCallEnd,
  }) {
    return ZegoUIKitPrebuiltCall(
      appID: AppConstants.zegoAppId,
      appSign: AppConstants.zegoAppSign,
      userID: currentUser.id,
      userName: currentUser.name,
      callID: call.id,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()
        ..audioVideoView = ZegoCallAudioVideoViewConfig(
          showSoundWavesInAudioMode: true,
        )
        ..bottomMenuBar = ZegoCallBottomMenuBarConfig(
          buttons: [
            ZegoCallMenuBarButtonName.toggleMicrophoneButton,
            ZegoCallMenuBarButtonName.hangUpButton,
            ZegoCallMenuBarButtonName.switchAudioOutputButton,
          ],
        ),
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (event, defaultAction) {
          onCallEnd();
          defaultAction.call();
        },
      ),
    );
  }

  /// Video 1-to-1 call widget.
  static Widget buildVideoCall({
    required CallModel call,
    required UserModel currentUser,
    required VoidCallback onCallEnd,
  }) {
    return ZegoUIKitPrebuiltCall(
      appID: AppConstants.zegoAppId,
      appSign: AppConstants.zegoAppSign,
      userID: currentUser.id,
      userName: currentUser.name,
      callID: call.id,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        ..bottomMenuBar = ZegoCallBottomMenuBarConfig(
          buttons: [
            ZegoCallMenuBarButtonName.toggleMicrophoneButton,
            ZegoCallMenuBarButtonName.toggleCameraButton,
            ZegoCallMenuBarButtonName.switchCameraButton,
            ZegoCallMenuBarButtonName.hangUpButton,
            ZegoCallMenuBarButtonName.switchAudioOutputButton,
          ],
        ),
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (event, defaultAction) {
          onCallEnd();
          defaultAction.call();
        },
      ),
    );
  }
}
