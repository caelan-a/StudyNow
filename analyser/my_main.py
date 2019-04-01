import logging
import firebase_admin
from firebase_admin import credentials, firestore
import requests
import os
import errno

import sys
from darkflow.cli2 import createInstance, detectNumPpl
from darkflow.detectionArgs import theArgs
import cv2

import datetime
import time 

tfnet = createInstance(theArgs)


lib_floor_zone = []
imgDir = 'imagesToScan'
timeDelay = 10

#login to firebase and make a new file for every possible photo

def init():
    cred = credentials.Certificate('./ServiceAccountKey.json')
    default_app = firebase_admin.initialize_app(cred)
    db = firestore.client()

    baseLibs = db.collection(u'libraries')
    for i, lib_doc in enumerate(baseLibs.get()):
        floors = baseLibs.document(lib_doc.id).collection(u'floors')

        for j, floor_doc in enumerate(floors.get()):
            zones = floors.document(floor_doc.id).collection('camera_zones')

            for k, zone_doc in enumerate(zones.get()):
                # print(zone_doc.to_dict())

                #Make list of image files in case they dont exist
                localPath = imgDir + '/' + lib_doc.id + '/' + \
                    floor_doc.id + '/' + zone_doc.id + '/' 
                localPathLogs = localPath + 'Logs' + '/'
                if not os.path.exists(os.path.dirname(localPath)):
                    try:
                        os.makedirs(os.path.dirname(localPath))
                    except OSError as exc:  # Guard against race condition
                        if exc.errno != errno.EEXIST:
                            raise

                if not os.path.exists(os.path.dirname(localPathLogs)):
                    try:
                        os.makedirs(os.path.dirname(localPathLogs))
                    except OSError as exc:  # Guard against race condition
                        if exc.errno != errno.EEXIST:
                            raise
    return db


# go through firbase directories and download the photos
# process the photos using darkflow
# log the files and information locally
# upload the information to the server

db = init()
counter = 0

while True:
    counter += 1
    baseLibs = db.collection(u'libraries')
    for i, lib_doc in enumerate(baseLibs.get()):
        floors = baseLibs.document(lib_doc.id).collection(u'floors')

        for j, floor_doc in enumerate(floors.get()):
            zones = floors.document(floor_doc.id).collection('camera_zones')

            for k, zone_doc in enumerate(zones.get()):
                #setup
                localPath = imgDir + '/' + lib_doc.id + '/' + floor_doc.id + '/' + zone_doc.id + '/' 
                logFileNum = str(counter)

                #organise the path directories
                tempPhotoPath = localPath + 'imgFile1.png'
                logPhotoPath = localPath + 'Logs/' + logFileNum + '.png'
                logTxtPath = localPath + '/Logs/logFile.txt'

                try:
                    #download photo data
                    photo_url = zone_doc.to_dict()['capture_urls']['image_0.png']
                    img_data = requests.get(photo_url).content
                    print("found photo")

                    #write photo to the temp file
                    with open(tempPhotoPath, 'wb') as handler:
                        handler.write(img_data)
                        print("we got it")
                    
                    #analyze data 
                    numPpl = detectNumPpl(tfnet, path=tempPhotoPath)

                    #update firebase
                    info = zone_doc.to_dict()
                    info['people_present'] = numPpl
                    zones.document(zone_doc.id).set(info)
                    # print(info) 
                
                    #write photo to the logs file
                    with open(logPhotoPath, 'wb') as handler:
                        handler.write(img_data)
                        print("we got it")

                    #write text to the txt logs file
                    with open(logTxtPath, 'a') as handler:
                        handler.write("file name {}, detected {} people, at {} \n".format(logFileNum, numPpl, datetime.datetime.now()))
                        print("we got it")


                except:
                    print("Failed to write to {}".format(localPath))

    # wait till the next time increment to read again
    time.sleep(timeDelay - (datetime.datetime.now().second % timeDelay))


