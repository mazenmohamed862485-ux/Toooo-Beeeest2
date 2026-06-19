package io.adaptant.labs.flutter_windowmanager;

  import android.app.Activity;
  import androidx.annotation.NonNull;
  import io.flutter.embedding.engine.plugins.FlutterPlugin;
  import io.flutter.embedding.engine.plugins.activity.ActivityAware;
  import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
  import io.flutter.plugin.common.MethodCall;
  import io.flutter.plugin.common.MethodChannel;
  import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
  import io.flutter.plugin.common.MethodChannel.Result;

  public class FlutterWindowManagerPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {
      private MethodChannel channel;
      private Activity activity;

      @Override
      public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
          channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_windowmanager");
          channel.setMethodCallHandler(this);
      }

      @Override
      public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
          channel.setMethodCallHandler(null);
          channel = null;
      }

      @Override
      public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
          activity = binding.getActivity();
      }

      @Override
      public void onDetachedFromActivityForConfigChanges() {}

      @Override
      public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
          activity = binding.getActivity();
      }

      @Override
      public void onDetachedFromActivity() {
          activity = null;
      }

      @Override
      public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
          if (activity == null) {
              result.error("NO_ACTIVITY", "Not attached to an activity", null);
              return;
          }
          Integer flags = call.argument("flags");
          if (flags == null) {
              result.error("INVALID_FLAGS", "flags argument is null", null);
              return;
          }
          final int flagsValue = flags;
          if (call.method.equals("addFlags")) {
              activity.runOnUiThread(() -> activity.getWindow().addFlags(flagsValue));
              result.success(true);
          } else if (call.method.equals("clearFlags")) {
              activity.runOnUiThread(() -> activity.getWindow().clearFlags(flagsValue));
              result.success(true);
          } else {
              result.notImplemented();
          }
      }
  }
  