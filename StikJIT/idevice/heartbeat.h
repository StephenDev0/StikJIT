//
//  heartbeat.h
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

// heartbeat.h
#ifndef HEARTBEAT_H
#define HEARTBEAT_H

typedef void (^HeartbeatCompletionHandler)(int result, const char *message);

void startHeartbeat(HeartbeatCompletionHandler completion);

#endif /* HEARTBEAT_H */
