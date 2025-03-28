//
//  jit.h
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

// jit.h
#ifndef JIT_H
#define JIT_H

int mount_lower_than_17(char* imagepath,char* signature_path);
int mount_personalized(char* imagetype,char* trustcache_path, char* manifest_path);
int unmount_lower_than_17(void);
int unmount_personalized(void);
int debug_app(const char *bundle_id);

#endif /* JIT_H */
