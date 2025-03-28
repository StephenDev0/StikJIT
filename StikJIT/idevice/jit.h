//
//  jit.h
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

// jit.h
#ifndef JIT_H
#define JIT_H
#include "idevice.h"


int mount_lower_than_17(char* imagepath,char* signature_path);
int mount_personalized(char* imagetype,char* trustcache_path, char* manifest_path);
int unmount_lower_than_17(void);
int unmount_personalized(void);


typedef void (^LogFuncC)(const char* message, ...);
int debug_app(TcpProviderHandle* provider, const char *bundle_id, LogFuncC logger);


#endif /* JIT_H */
