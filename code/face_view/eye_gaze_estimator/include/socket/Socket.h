#ifndef __SOCKET__
#define __SOCKET__

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 
#include <fcntl.h>
#include <iostream>
#include <pthread.h>

#define PORT_NO 6975

class Socket
{
public:
    Socket();
    ~Socket();
    int startServer(void (*cb)(char* buf));
    int stopServer();

    int startClient(std::string);
    int clientSendMessage(std::string);
    int stopClient();

private:
    pthread_t serverThread;
};

static volatile bool run;
static pthread_t listenThread;
static bool isServer;
static int sockfd, newsockfd, pid;
static struct sockaddr_in serv_addr, cli_addr;

static void (*extRecvCb)(char* buf);

#endif

