// Jackson Coxson
// heartbeat.c

#include "idevice.h"
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/_types/_u_int64_t.h>
#include <CoreFoundation/CoreFoundation.h>
#include <limits.h>

typedef void (^HeartbeatCompletionHandler)(int result, const char *message);

void startHeartbeat(HeartbeatCompletionHandler completion) {
    printf("DEBUG: Initializing logger...\n");
    idevice_init_logger(Debug, Disabled, NULL);
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(LOCKDOWN_PORT);
    if (inet_pton(AF_INET, "10.7.0.1", &addr.sin_addr) <= 0) {
        fprintf(stderr, "DEBUG: Error converting IP address.\n");
        return;
    }
    printf("DEBUG: Socket address created for IP 10.7.0.1 on port %d.\n", LOCKDOWN_PORT);
    
    printf("DEBUG: Searching the app bundle for pairing_file.plist...\n");
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
    
    printf("DEBUG: Reading pairing file...\n");
    IdevicePairingFile *pairing_file = NULL;
    IdeviceErrorCode err = idevice_pairing_file_read(pairingFilePath, &pairing_file);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "DEBUG: Failed to read pairing file: %d\n", err);
        completion(err, "Failed to read pairing file");
        return;
    }
    printf("DEBUG: Pairing file read successfully.\n");
    
    printf("DEBUG: Creating TCP provider...\n");
    TcpProviderHandle *provider = NULL;
    err = idevice_tcp_provider_new((struct sockaddr *)&addr, pairing_file,
                                   "ExampleProvider", &provider);
    if (err != IdeviceSuccess) {
        fprintf(stderr, "DEBUG: Failed to create TCP provider: %d\n", err);
        idevice_pairing_file_free(pairing_file);
        completion(err, "Failed to create TCP provider");
        return;
    }
    printf("DEBUG: TCP provider created successfully.\n");
    
    printf("DEBUG: Connecting to installation proxy...\n");
    HeartbeatClientHandle *client = NULL;
    err = heartbeat_connect_tcp(provider, &client);
    if (err != IdeviceSuccess) {
        completion(err, "Failed to connect to Heartbeat");
        fprintf(stderr, "DEBUG: Failed to connect to installation proxy: %d\n", err);
        return;
    }
    tcp_provider_free(provider);
    printf("DEBUG: Connected to installation proxy successfully.\n");
    
    completion(0, "Heartbeat Completed");
    
    u_int64_t current_interval = 15;
    while (1) {
        u_int64_t new_interval = 0;
        printf("DEBUG: Sending heartbeat with current interval: %llu seconds...\n", current_interval);
        err = heartbeat_get_marco(client, current_interval, &new_interval);
        if (err != IdeviceSuccess) {
            fprintf(stderr, "DEBUG: Failed to get marco: %d\n", err);
            heartbeat_client_free(client);
            return;
        }
        printf("DEBUG: Received new interval: %llu seconds.\n", new_interval);
        current_interval = new_interval + 5;
        
        printf("DEBUG: Sending polo reply...\n");
        err = heartbeat_send_polo(client);
        if (err != IdeviceSuccess) {
            fprintf(stderr, "DEBUG: Failed to send polo: %d\n", err);
            heartbeat_client_free(client);
            return;
        }
        printf("DEBUG: Polo reply sent successfully.\n");
    }
}
