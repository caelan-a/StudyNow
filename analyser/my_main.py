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
tfnet = createInstance(theArgs)


lib_floor_zone = []
imgDir = 'imagesToScan'

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
                filePath = imgDir + '/' + lib_doc.id + '/' + \
                    floor_doc.id + '/' + zone_doc.id + '/' + 'imgFile1.png'
                if not os.path.exists(os.path.dirname(filePath)):
                    try:
                        os.makedirs(os.path.dirname(filePath))
                    except OSError as exc:  # Guard against race condition
                        if exc.errno != errno.EEXIST:
                            raise
    return db

# make a list of photos to download

# download the photos

# process the photos using darkflow

# upload the information to the server

db = init()

while True:

    baseLibs = db.collection(u'libraries')
    for i, lib_doc in enumerate(baseLibs.get()):
        floors = baseLibs.document(lib_doc.id).collection(u'floors')

        for j, floor_doc in enumerate(floors.get()):
            zones = floors.document(floor_doc.id).collection('camera_zones')

            for k, zone_doc in enumerate(zones.get()):
                filePath = imgDir + '/' + lib_doc.id + '/' + floor_doc.id + '/' + zone_doc.id + '/' + 'imgFile1.png'
                try:
                    photo_url = zone_doc.to_dict()['capture_urls']['image_0.png']
                    img_data = requests.get(photo_url).content
                    print("found photo")
                    with open(filePath, 'wb') as handler:
                        print("we got it")
                        handler.write(img_data)

                    numPpl = detectNumPpl(tfnet, path=filePath)
                    info = zone_doc.to_dict()
                    info['people_present'] = numPpl

                    zones.document(zone_doc.id).set(info)
                    print(info) 

                except:
                    print("no image files in {}".format(filePath))


