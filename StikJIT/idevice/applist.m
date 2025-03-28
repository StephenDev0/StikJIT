//
//  applist.c
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

#include "idevice.h"
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include "applist.h"

NSDictionary<NSString*, NSString*>* list_installed_apps(TcpProviderHandle* provider, NSString** error) {
    IdeviceErrorCode err = IdeviceSuccess;

    InstallationProxyClientHandle *client = NULL;
    err = installation_proxy_connect_tcp(provider, &client);
    if (err != IdeviceSuccess) {
        *error = @"Failed to connect to installation proxy";
        return nil;
    }

    void *apps = NULL;
    size_t apps_len = 0;
    err = installation_proxy_get_apps(client, NULL, NULL, 0, &apps, &apps_len);
    if (err != IdeviceSuccess) {
        installation_proxy_client_free(client);
        *error = @"Failed to get apps";
        return nil;
    }

    plist_t *app_list = (plist_t *)apps;
    
    NSMutableDictionary<NSString*, NSString*>* ans = [[NSMutableDictionary alloc] init];
    
    for (size_t i = 0; i < apps_len; i++) {
        plist_t app = app_list[i];
        // Check if the app has an "Entitlements" dictionary.
        plist_t entitlements = plist_dict_get_item(app, "Entitlements");
        if (entitlements) {
            // Look for the "get-task-allow" key.
            plist_t taskAllowNode = plist_dict_get_item(entitlements, "get-task-allow");
            if (taskAllowNode) {
                uint8_t isAllowed = 0;
                plist_get_bool_val(taskAllowNode, &isAllowed);
                if (isAllowed) {
                    // Retrieve the bundle identifier if the entitlement is true.
                    plist_t bundle_id_node = plist_dict_get_item(app, "CFBundleIdentifier");
                    if (bundle_id_node) {
                        char *bundle_id = NULL;
                        plist_get_string_val(bundle_id_node, &bundle_id);

                        // Skip if bundle ID is empty
                        if (bundle_id == NULL || strlen(bundle_id) == 0) {
                            free(bundle_id);
                            continue;
                        }

                        // Retrieve the app name
                        plist_t app_name_node = plist_dict_get_item(app, "CFBundleName");
                        char *app_name = NULL;
                        if (app_name_node) {
                            plist_get_string_val(app_name_node, &app_name);
                        } else {
                            app_name = strdup("Unknown");
                        }

                        ans[[NSString stringWithCString:bundle_id encoding:NSASCIIStringEncoding]] = [NSString stringWithCString:app_name encoding:NSASCIIStringEncoding];

                        free(bundle_id);
                        free(app_name);
                    }
                }
            }
        }
    }


    installation_proxy_client_free(client);

    return ans;
}
