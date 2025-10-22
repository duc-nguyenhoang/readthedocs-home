=====
Audio
=====
Booting Sequence
================
1. Init process: `/system/core/init/init.cpp <https://cs.android.com/android/platform/superproject/+/android-16.0.0_r2:system/core/init/init.cpp>`_

Init process loads the init scripts from /system/etc/init directory

.. code-block:: cpp

    static void LoadBootScripts(ActionManager& action_manager, ServiceList& service_list) {
        Parser parser = CreateParser(action_manager, service_list);

        std::string bootscript = GetProperty("ro.boot.init_rc", "");
        if (bootscript.empty()) {
            parser.ParseConfig("/system/etc/init/hw/init.rc");
            if (!parser.ParseConfig("/system/etc/init")) {
                late_import_paths.emplace_back("/system/etc/init");
            }
            // late_import is available only in Q and earlier release. As we don't
            // have system_ext in those versions, skip late_import for system_ext.
            parser.ParseConfig("/system_ext/etc/init");
            if (!parser.ParseConfig("/vendor/etc/init")) {
                late_import_paths.emplace_back("/vendor/etc/init");
            }
            if (!parser.ParseConfig("/odm/etc/init")) {
                late_import_paths.emplace_back("/odm/etc/init");
            }
            if (!parser.ParseConfig("/product/etc/init")) {
                late_import_paths.emplace_back("/product/etc/init");
            }
        } else {
            parser.ParseConfig(bootscript);
        }
    }

2. audioserver, mediaserver scripts

    - `frameworks/av/media/audioserver/audioserver.rc <https://cs.android.com/android/platform/superproject/+/android-16.0.0_r2:frameworks/av/media/audioserver/audioserver.rc>`_

    code-block :: text

        service audioserver /system/bin/audioserver
            class core
            user audioserver
            # media gid needed for /dev/fm (radio) and for /data/misc/media (tee)
            group audio camera drmrpc media mediadrm net_bt net_bt_admin net_bw_acct wakelock
            capabilities BLOCK_SUSPEND

    - `frameworks/av/media/mediaserver/mediaserver.rc <https://cs.android.com/android/platform/superproject/+/android-16.0.0_r2:frameworks/av/media/mediaserver/mediaserver.rc>`_

    code-block :: text

        on property:init.svc.media=*
            setprop init.svc.mediadrm ${init.svc.media}

        service media /system/bin/mediaserver
            class main
            user media
            group audio camera inet net_bt net_bt_admin net_bw_acct drmrpc mediadrm
            ioprio rt 4
            task_profiles ProcessCapacityHigh HighPerformance

3. server
audioserver - main_audioserver.cpp
-AudioFlinger instantiate
const auto af = sp<AudioFlinger>::make();
-AudioPolicy instantiate
const auto aps = sp<AudioPolicyService>::make();

Adding AudioFlinger and AudioPolicy to ServiceManager.
    sp<IServiceManager> sm = defaultServiceManager();
    sm->addService(String16(IAudioFlinger::DEFAULT_SERVICE_NAME), afAdapter,
            false /* allowIsolated */, IServiceManager::DUMP_FLAG_PRIORITY_DEFAULT);
    sm->addService(String16(AudioPolicyService::getServiceName()), aps,
            false /* allowIsolated */, IServiceManager::DUMP_FLAG_PRIORITY_DEFAULT);

mediaserver - main_mediaserver.cpp
MediaPlayerService::instantiate();
ResourceManagerService::instantiate();
