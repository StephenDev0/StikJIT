//
//  jit.c
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

// Jackson Coxson

#include "idevice.h"
#include <arpa/inet.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>
#include <limits.h>
#include "helper.h"


ImageMounterHandle* getIMH(void){
    char *ip = "10.7.0.2";
    // Create the socket address
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(LOCKDOWN_PORT);
    if (inet_pton(AF_INET, ip, &addr.sin_addr) != 1) {
      fprintf(stderr, "Invalid IP address\n");
      return NULL;
    }
    char pairingFilePath[1024];
    CFURLRef url = CFCopyHomeDirectoryURL();
    if (url) {
        CFStringRef path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
        if (path) {
            CFStringGetCString(path, pairingFilePath, sizeof(pairingFilePath), kCFStringEncodingUTF8);
            strncat(pairingFilePath, "/Documents/pairingFile.plist", sizeof(pairingFilePath) - strlen(pairingFilePath) - 1);
            CFRelease(path);
        }
        CFRelease(url);
    }
    printf("Pairing file found at path: %s\n", pairingFilePath);
    // Read pairing file
    IdevicePairingFile *pairing_file = NULL;
    IdeviceErrorCode err =
        idevice_pairing_file_read(pairingFilePath, &pairing_file);
    if (err != IdeviceSuccess) {
      fprintf(stderr, "Failed to read pairing file: %d\n", err);
      return NULL;
    }

    // Create TCP provider
    TcpProviderHandle *provider = NULL;
    err = idevice_tcp_provider_new((struct sockaddr *)&addr, pairing_file,
                                   "ImageMounterTest", &provider);
    if (err != IdeviceSuccess) {
      fprintf(stderr, "Failed to create TCP provider: %d\n", err);
      idevice_pairing_file_free(pairing_file);
      return NULL;
    }

    // Connect to image mounter
    ImageMounterHandle *client = NULL;
    err = image_mounter_connect_tcp(provider, &client);
    if (err != IdeviceSuccess) {
      fprintf(stderr, "Failed to connect to image mounter: %d\n", err);
      tcp_provider_free(provider);
      return NULL;
    }
    tcp_provider_free(provider);
    return client;
}

int mount_lower_than_17(char* imagepath,char* signature_path){
    int ispassed = 0;
    printf("==Mounting Developer Disk image (17>) ==\n");
    ImageMounterHandle* client = getIMH();
    if (!client){
        return 1;
    }
    uint8_t *image_data = NULL;
    size_t image_len = 0;
    uint8_t *signature_data = NULL;
    size_t signature_len = 0;
    if (!read_file(imagepath,&image_data,&image_len)){
        printf("ERROR: Failed to read mounted image\n");
        
    }
    if (!read_file(signature_path,&signature_data,&signature_len)){
        free(image_data);
        ispassed = 1;
        printf("ERROR: Failed to read signature of mounted image\n");
        
    }
    image_mounter_mount_developer(client,image_data,image_len,signature_data,signature_len);
    printf("==Successfully mounted developer disk image==\n");
    if (ispassed == 0){
        free(image_data);
        free(signature_data);
    }
    return ispassed;
}

int mount_personalized(char* image_path,char* trustcache_path, char* manifest_path){
    char* imagetype = "Personalized";
    int ispassed = 0;
    printf("==Mounting Developer Disk image (Personalized)==\n");

    ImageMounterHandle* client = getIMH();
    if (!client){
        return 1;
    }
    uint8_t *trustcache_data = NULL;
    size_t trustcache_len = 0;
    uint8_t *manifest_data = NULL;
    size_t manifest_len = 0;
    uint8_t *image_data = NULL;
    size_t image_len = 0;

    if (!read_file(image_path,&image_data,&image_len)){
        printf("ERROR: Failed to read mounted image\n");
        
    }

    if (!read_file(trustcache_path,&trustcache_data,&trustcache_len)){
        free(image_data);

        ispassed = 1;
        printf("ERROR: Failed to read trustcache of mounted image\n");
        
    }
    if (!read_file(manifest_path,&manifest_data,&manifest_len)){
        free(trustcache_data);
        free(image_data);

        ispassed = 1;
        printf("ERROR: Failed to read manifest of mounted image\n");
        
    }

    image_mounter_upload_image(client,imagetype,image_data,image_len,manifest_data,manifest_len);
    image_mounter_mount_image(client,imagetype,manifest_data,manifest_len,trustcache_data,trustcache_len,NULL);
    printf("==Successfully mounted developer disk image==\n");
    if (ispassed == 0){
        free(trustcache_data);
        free(manifest_data);
        free(image_data);
    }
    return ispassed;
}

int unmount_lower_than_17(void){
    printf("==Unmounting Developer Disk image (17>) ==\n");
    ImageMounterHandle* client = getIMH();
    if (!client){
        return 1;
    }
    image_mounter_unmount_image(client,"/Developer");
    return 0;
}

int unmount_personalized(void){
    printf("==Unmounting Developer Disk image (Personalized) ==\n");
    ImageMounterHandle* client = getIMH();
    if (!client){
        return 1;
    }
    image_mounter_unmount_image(client,"/System/Developer");
    return 0;
}

int debug_app(const char *bundle_id) {
    // Initialize logger
    idevice_init_logger(Debug, Disabled, NULL);
    
    // Hardcode device IP
    const char *device_ip = "10.7.0.1";
    
    
    /*****************************************************************
     * Locate pairing file in app bundle
     *****************************************************************/
    char pairingFilePath[1024];
    CFURLRef url = CFCopyHomeDirectoryURL();
    if (url) {
        CFStringRef path = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
        if (path) {
            CFStringGetCString(path, pairingFilePath, sizeof(pairingFilePath), kCFStringEncodingUTF8);
            strncat(pairingFilePath, "/Documents/pairingFile.plist", sizeof(pairingFilePath) - strlen(pairingFilePath) - 1);
            CFRelease(path);
        }
        CFRelease(url);
    }
    printf("Pairing file found at path: %s\n", pairingFilePath);
    
    /*****************************************************************
     * CoreDeviceProxy Setup
     *****************************************************************/
    printf("=== Setting up CoreDeviceProxy ===\n");
    
    // Create socket address
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(LOCKDOWN_PORT);
    if (inet_pton(AF_INET, device_ip, &addr.sin_addr) != 1) {
        fprintf(stderr, "Invalid IP address\n");
        return 1;
    }
    
    // Read pairing file from the bundle
    IdevicePairingFile *pairing = NULL;
    IdeviceErrorCode err = idevice_pairing_file_read(pairingFilePath, &pairing);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to read pairing file: %d\n", err);
        return 1;
    }
    
    // Create TCP provider
    TcpProviderHandle *tcp_provider = NULL;
    err = idevice_tcp_provider_new((struct sockaddr *)&addr, pairing,
                                   "ProcessDebugTest", &tcp_provider);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to create TCP provider: %d\n", err);
        idevice_pairing_file_free(pairing);
        return 1;
    }
    
    // Connect to CoreDeviceProxy
    CoreDeviceProxyHandle *core_device = NULL;
    err = core_device_proxy_connect_tcp(tcp_provider, &core_device);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to connect to CoreDeviceProxy: %d\n", err);
        tcp_provider_free(tcp_provider);
        return 1;
    }
    tcp_provider_free(tcp_provider);
    
    // Get server RSD port
    uint16_t rsd_port;
    err = core_device_proxy_get_server_rsd_port(core_device, &rsd_port);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to get server RSD port: %d\n", err);
        core_device_proxy_free(core_device);
        return 1;
    }
    printf("Server RSD Port: %d\n", rsd_port);
    
    /*****************************************************************
     * Create TCP Tunnel Adapter
     *****************************************************************/
    printf("\n=== Creating TCP Tunnel Adapter ===\n");
    
    AdapterHandle *adapter = NULL;
    err = core_device_proxy_create_tcp_adapter(core_device, &adapter);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to create TCP adapter: %d\n", err);
        core_device_proxy_free(core_device);
        return 1;
    }
    
    // Connect to RSD port
    err = adapter_connect(adapter, rsd_port);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to connect to RSD port: %d\n", err);
        adapter_free(adapter);
        core_device_proxy_free(core_device);
        return 1;
    }
    printf("Successfully connected to RSD port\n");
    
    /*****************************************************************
     * XPC Device Setup
     *****************************************************************/
    printf("\n=== Setting up XPC Device ===\n");
    
    XPCDeviceAdapterHandle *xpc_device = NULL;
    err = xpc_device_new(adapter, &xpc_device);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to create XPC device: %d\n", err);
        adapter_free(adapter);
        core_device_proxy_free(core_device);
        return 1;
    }
    
    // Get DebugProxy service
    XPCServiceHandle *debug_service = NULL;
    err = xpc_device_get_service(xpc_device, "com.apple.internal.dt.remote.debugproxy", &debug_service);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to get debug proxy service: %d\n", err);
        return 1;
    }
    
    // Get ProcessControl service
    XPCServiceHandle *pc_service = NULL;
    err = xpc_device_get_service(xpc_device, "com.apple.instruments.dtservicehub", &pc_service);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to get process control service: %d\n", err);
        xpc_device_free(xpc_device);
        core_device_proxy_free(core_device);
        return 1;
    }
    
    /*****************************************************************
     * Process Control - Launch App
     *****************************************************************/
    printf("\n=== Launching App ===\n");
    
    // Get the adapter back from the XPC device
    AdapterHandle *pc_adapter = NULL;
    err = xpc_device_adapter_into_inner(xpc_device, &pc_adapter);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to extract adapter: %d\n", err);
        xpc_device_free(xpc_device);
        core_device_proxy_free(core_device);
        return 1;
    }
    
    // Connect to process control port
    err = adapter_connect(pc_adapter, pc_service->port);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to connect to process control port: %d\n", err);
        adapter_free(pc_adapter);
        xpc_service_free(pc_service);
        core_device_proxy_free(core_device);
        return 1;
    }
    printf("Successfully connected to process control port\n");
    
    // Create RemoteServerClient
    RemoteServerAdapterHandle *remote_server = NULL;
    err = remote_server_adapter_new(pc_adapter, &remote_server);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to create remote server: %d\n", err);
        adapter_free(pc_adapter);
        xpc_service_free(pc_service);
        core_device_proxy_free(core_device);
        return 1;
    }
    
    // Create ProcessControlClient
    ProcessControlAdapterHandle *process_control = NULL;
    err = process_control_new(remote_server, &process_control);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to create process control client: %d\n", err);
        remote_server_free(remote_server);
        xpc_service_free(pc_service);
        core_device_proxy_free(core_device);
        return 1;
    }
    
    // Launch application
    uint64_t pid;
    err = process_control_launch_app(process_control, bundle_id, NULL, 0, NULL, 0,
                                     true, false, &pid);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to launch app: %d\n", err);
        process_control_free(process_control);
        remote_server_free(remote_server);
        xpc_service_free(pc_service);
        core_device_proxy_free(core_device);
        return 1;
    }
    printf("Successfully launched app with PID: %" PRIu64 "\n", pid);
    
    /*****************************************************************
     * Debug Proxy - Attach to Process
     *****************************************************************/
    printf("\n=== Attaching Debugger ===\n");
    
    // Get the adapter back from the remote server
    AdapterHandle *debug_adapter = NULL;
    err = remote_server_adapter_into_inner(remote_server, &debug_adapter);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to extract adapter: %d\n", err);
        xpc_service_free(debug_service);
        process_control_free(process_control);
        remote_server_free(remote_server);
        xpc_service_free(pc_service);
        core_device_proxy_free(core_device);
        return 1;
    }
    
    // Connect to debug proxy port
    err = adapter_connect(debug_adapter, debug_service->port);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to connect to debug proxy port: %d\n", err);
        adapter_free(debug_adapter);
        xpc_service_free(debug_service);
        process_control_free(process_control);
        remote_server_free(remote_server);
        xpc_service_free(pc_service);
        core_device_proxy_free(core_device);
        return 1;
    }
    printf("Successfully connected to debug proxy port\n");
    
    // Create DebugProxyClient
    DebugProxyAdapterHandle *debug_proxy = NULL;
    err = debug_proxy_adapter_new(debug_adapter, &debug_proxy);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to create debug proxy client: %d\n", err);
        adapter_free(debug_adapter);
        xpc_service_free(debug_service);
        process_control_free(process_control);
        remote_server_free(remote_server);
        xpc_service_free(pc_service);
        core_device_proxy_free(core_device);
        return 1;
    }
    
    // Send vAttach command with PID in hex
    char attach_command[64];
    snprintf(attach_command, sizeof(attach_command), "vAttach;%" PRIx64, pid);
    
    DebugserverCommandHandle *attach_cmd = debugserver_command_new(attach_command, NULL, 0);
    if (attach_cmd == NULL) {
        fprintf(stderr, "Failed to create attach command\n");
        debug_proxy_free(debug_proxy);
        adapter_free(debug_adapter);
        xpc_service_free(debug_service);
        process_control_free(process_control);
        remote_server_free(remote_server);
        xpc_service_free(pc_service);
        core_device_proxy_free(core_device);
        return 1;
    }
    
    char *attach_response = NULL;
    err = debug_proxy_send_command(debug_proxy, attach_cmd, &attach_response);
    debugserver_command_free(attach_cmd);
    
    if (err != IdeviceSuccess) {
        fprintf(stderr, "Failed to attach to process: %d\n", err);
    } else if (attach_response != NULL) {
        printf("Attach response: %s\n", attach_response);
        idevice_string_free(attach_response);
    }
    
    // Send detach command
    DebugserverCommandHandle *detach_cmd = debugserver_command_new("D", NULL, 0);
    if (detach_cmd == NULL) {
        fprintf(stderr, "Failed to create detach command\n");
    } else {
        char *detach_response = NULL;
        err = debug_proxy_send_command(debug_proxy, detach_cmd, &detach_response);
        err = debug_proxy_send_command(debug_proxy, detach_cmd, &detach_response);
        err = debug_proxy_send_command(debug_proxy, detach_cmd, &detach_response);
        debugserver_command_free(detach_cmd);
        
        if (err != IdeviceSuccess) {
            fprintf(stderr, "Failed to detach from process: %d\n", err);
        } else if (detach_response != NULL) {
            printf("Detach response: %s\n", detach_response);
            idevice_string_free(detach_response);
        }
    }
    
    /*****************************************************************
     * Cleanup
     *****************************************************************/
    debug_proxy_free(debug_proxy);
    xpc_service_free(debug_service);
    
    printf("\nDebug session completed\n");
    return 0;
}
