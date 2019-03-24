# import sys
# from darkflow.cli2 import createInstance, detectNumPpl
# from darkflow.detectionArgs import theArgs
# import cv2
# tfnet = createInstance(theArgs)


# import main
import logging
from flask import Flask
import firebase_admin
from firebase_admin import credentials,firestore
import requests


old_image = r"https://firebasestorage.googleapis.com/v0/b/studynow-f5337.appspot.com/o/libraries%2Fbaileuu%2Ffloors%2F1%2Fcamera_zones%2F1%2Fimage_0.png?alt=media&token=76068d4e-519c-41b8-9e45-6b776f8b0d30"
new_image = r"https://firebasestorage.googleapis.com/v0/b/studynow-f5337.appspot.com/o/libraries%2Fbaileuu%2Ffloors%2F1%2Fcamera_zones%2F1%2Fimage_1.png?alt=media&token=05b9aa1d-6437-4369-9909-4f56ec31acc1"

# def test_index():
#     main.app.testing = True
#     client = main.app.test_client()

#     r = client.get('/')
#     assert r.status_code == 200
#     assert 'Hello World' in r.data.decode('utf-8')

# test_index()

def initFirbase():
    cred = credentials.Certificate('./ServiceAccountKey.json')
    default_app = firebase_admin.initialize_app(cred)
    db = firestore.client()

    doc_ref = db.collection(u'libraries').document(u'baileuu').collection(u'floors').document(u'1').collection(u'camera_zones').document(u'1')
    doc = doc_ref.get()
    print(u'Document data: {}'.format(doc.to_dict()))
    photo_url = doc.to_dict()['capture_urls']['image_0.png']
    print(photo_url)

   

    img_data = requests.get(photo_url).content
    with open('test\\yeet\\newTestFile.jpg', 'wb') as handler:
        handler.write(img_data)

    path = 'test\\yeet\\newTestFile.jpg'
    print(detectNumPpl(tfnet, path=path))



initFirbase()


# old_image = https://firebasestorage.googleapis.com/v0/b/studynow-f5337.appspot.com/o/libraries%2Fbaileuu%2Ffloors%2F1%2Fcamera_zones%2F1%2Fimage_0.png?alt=media&token=76068d4e-519c-41b8-9e45-6b776f8b0d30

