#include <socket/Socket.h>

Socket::Socket() {
}

void set_nonblock(int socket) {
    int flags;
    flags = fcntl(socket,F_GETFL,0);
    if (flags != -1) {
        fcntl(socket, F_SETFL, flags | O_NONBLOCK);
    } else {
        std::cerr << "Error setting socket to non-blocking" << std::endl;
        exit(1);
    }
}

void* listenThreadFunc(void* noarg) {
    run = true;

    // Set the timeout so we don't block indefinitely
    struct timeval tv;
    tv.tv_sec = 0.05;
    tv.tv_usec = 500000;

    fd_set master, read_fds;
    socklen_t addrlen;
    int newfd;
    struct sockaddr_storage remoteaddr;
    int nbytes;
    char buf[256];

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        std::cerr << "Error opening socket" << std::endl;
    }

    bzero((char *) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(PORT_NO);

    if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0) {
        std::cerr << "Error binding socket" << std::endl;
    }

    listen(sockfd,5);

    // Add the socket to the master FD set
    FD_SET(sockfd, &master);
    int fd_max = sockfd;

    while (run) {
        read_fds = master;
        if (select(fd_max+1, &read_fds, NULL, NULL, &tv) == -1) {
            std::cerr << "Error in select" << std::endl;
            exit(1);
        }

        for(int i = 0; i <= fd_max; i++) {
            if (FD_ISSET(i, &read_fds)) {
                if (i == sockfd) {
                    addrlen = sizeof remoteaddr;
                    newfd = accept(sockfd, (struct sockaddr *)&remoteaddr, &addrlen);
                 
                    if (newfd == -1) {
                        std::cerr << "Error on accept" << std::endl;
                    } else {
                        FD_SET(newfd, &master); // add to master set
                        if (newfd > fd_max) {    // keep track of the max
                            fd_max = newfd;
                        }
                    }
                } else {
                    if ((nbytes = recv(i, buf, sizeof buf, 0)) <= 0) {
                        if (nbytes == 0) {
                            // Connection closed
                        } else {
                            std::cerr << "Error on recv" << std::endl;
                        }
                        close(i); // bye!
                        FD_CLR(i, &master); 

                    } else {
                        if (extRecvCb != NULL) {
                            extRecvCb(buf);
                        }
                    }
                }
            }
        }
    }

    close(sockfd);

    return 0;
}

int Socket::startServer(void (*cb)(char* buf)) {
    extRecvCb = cb;
    pthread_create(&serverThread, NULL, listenThreadFunc, NULL);
    
    return 0;
}

int Socket::stopServer() {
    run = false;
    pthread_join(serverThread, NULL);

    return 0;
}

int Socket::startClient(std::string hostname) {
    struct hostent *server;

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        std::cerr << "Client: error opening socket" << std::endl;
    }

    server = gethostbyname(hostname.c_str());
    if (server == NULL) {
        fprintf(stderr,"ERROR, no such host\n");
        exit(0);
    }

    bzero((char *) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    bcopy((char *)server->h_addr, 
         (char *)&serv_addr.sin_addr.s_addr,
         server->h_length);
    serv_addr.sin_port = htons(PORT_NO);
    if (connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0) {
        std::cerr << "Client: error connecting." << std::endl;
    }


    return 0;
}

int Socket::clientSendMessage(std::string message) {
    write(sockfd, message.c_str(), message.length());

    return 0;
}

int Socket::stopClient() {
    close(sockfd);

    return 0;
}

Socket::~Socket() {
    close(sockfd);
}

