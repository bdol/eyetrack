import socket
import pygame
import sys
import time
import numpy as np

def parseData(data):
    toks = data.split(':')
    lxtoks = toks[1].split('=')
    lx = float(lxtoks[1])
    lytoks = toks[2].split('=')
    ly = float(lytoks[1])
    return (lx, ly)

def calibrate(client):
    numPointsForCalib = 50
    calibPoints = [[640, 400], [100, 100], [1200, 200], [50, 800], [1000, 750],
            [200, 400], [800, 300]]
    recordedPoints = []

    Xx = np.array([])
    Yx = np.array([])
    Xy = np.array([])
    Yy = np.array([])
    for p in calibPoints:
        numPoints = numPointsForCalib
        screen.fill(black)
        pygame.draw.circle(screen, white, (int(p[0]), int(p[1])), 10, 10)
        pygame.draw.circle(screen, red, (int(p[0]), int(p[1])), 3, 3)
        pygame.display.update()

        points = []
        time.sleep(3)

        while numPoints > 0:
            data = client.recv(2048)
            lx, ly = parseData(data)
            if int(lx) == 0 or int(ly) == 0:
                continue

            Xx = np.append(Xx, lx)
            Xy = np.append(Xy, ly)
            Yx = np.append(Yx, p[0])
            Yy = np.append(Yy, p[1])

            points.append([lx, ly])
            numPoints -= 1

        recordedPoints.append(points)

    X = np.vstack([Xx, Xy, np.ones(len(Xx))]).T
    Y = np.vstack([Yx, Yy]).T
    S = np.linalg.lstsq(X, Y)[0]

    # DEBUG: write points to file
    f = open('xdata.txt', 'w')
    for p in calibPoints:
        f.write(str(p[0])+'\t')
    f.write('\n')
    for i in range(0, numPointsForCalib):
        for j in range(0, len(calibPoints)):
            f.write(str(recordedPoints[j][i][0])+'\t')
        f.write('\n')
    f.close()
    f = open('ydata.txt', 'w')
    for p in calibPoints:
        f.write(str(p[1])+'\t')
    f.write('\n')
    for i in range(0, numPointsForCalib):
        for j in range(0, len(calibPoints)):
            f.write(str(recordedPoints[j][i][1])+'\t')
        f.write('\n')
    f.close()

    return S

# START OF MAIN
# Initialize socket
host = ''
port = 6975
backlog = 5
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((host, port))
s.listen(backlog)

# Initialize pygame drawing surface
size = width, height = 1280, 800
black = 0, 0, 0
white = 255, 255, 255
red = 255, 0, 0
green = 0, 255, 0
screen = pygame.display.set_mode(size, pygame.FULLSCREEN)

print "Waiting for connection..."
connected = False
calibrated = False
client, address = s.accept()

while 1:
    for event in pygame.event.get():
        if event.type == pygame.QUIT: 
            sys.exit()

    data = client.recv(2048)
    if not connected:
        print "Connected!"
        connected = True

    if not calibrated:
        S = calibrate(client)
        calibrated = True
    else:
        lx, ly = parseData(data)
        screen.fill(black)
        pygame.draw.circle(screen, white, (int(lx*S[0, 0]+ly*S[1, 0] + S[2, 0]),
            int(lx*S[0, 1]+ly*S[1, 1]+S[2, 1])), 10, 3)
        pygame.draw.circle(screen, red, (int(lx*S[0, 0]+ly*S[1, 0] + S[2, 0]),
            int(lx*S[0, 1]+ly*S[1, 1]+S[2, 1])), 50, 3)
        pygame.draw.circle(screen, green, (int(lx*S[0, 0]+ly*S[1, 0] + S[2, 0]),
            int(lx*S[0, 1]+ly*S[1, 1]+S[2, 1])), 100, 3)
        pygame.display.update()

client.close()
