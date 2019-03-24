import google.cloud.storage
import datetime

# this code downloads photos from the database section of firebase
# storage_client = google.cloud.storage.Client.from_service_account_json("./ServiceAccountKey.json")
# bucket = storage_client.get_bucket('studynow-f5337.appspot.com')
# # d = 'image_baileuu_1_1.jpg'
# filename = r"C:\Users\Benjamin_de_worsop\Desktop\yolo-object-detection\studyNow\StudyNow\analyser\test\yeet\newTestFile.jpg"
# d.download_to_filename(filename)

# d = 'path/name'
# d = bucket.blob(d)
# d.upload_from_string('{"hello":"mun"}')



# This code pushes and pulls data in a text format to the storage section of the firebase
# import logging
# from flask import Flask
# import firebase_admin
# from firebase_admin import credentials,firestore
# from firebase import firebase

# cred = credentials.Certificate('./ServiceAccountKey.json')
# firebase = firebase.FirebaseApplication('https://studynow-f5337.firebaseio.com', None)
# result = firebase.get('path/', "name")



# import json
# from firebase import firebase
# from firebase import jsonutil

# firebase = firebase.FirebaseApplication('https://studynow-f5337.firebaseio.com', authentication=None)

# def log_user(response):
#     with open('/tmp/users/%s.json' % response.keys()[0], 'w') as users_file:
#         users_file.write(json.dumps(response, cls=jsonutil.JSONEncoder))

# firebase.get_async('/users', None, {'print': 'pretty'}, callback=log_user)




# This code makes a "realtime database" request
# import pyrebase
# import requests

# config = {
#   "apiKey": "AIzaSyBP4CW7R0XBLIKLRGcEzIo6zckwlYvgdTc",
#   "authDomain": "studynow-f5337.firebaseapp.com",
#   "databaseURL": "https://studynow-f5337.firebaseio.com",
#   "storageBucket": "studynow-f5337.appspot.com",
#   "serviceAccount": "ServiceAccountKey.json"
# }

# firebase = pyrebase.initialize_app(config)
# db = firebase.database()

# # collections = db.child("libraries").get()
# # print(collections.key())
# data = {"name": "Mortimer 'Morty' Smith"}
# db.child("libraries").push(data)

# This talks to the right thing (cloud firestore) but not sure what the get request object is 
# import firebase_admin
# from firebase_admin import credentials,firestore
# cred = credentials.Certificate('./ServiceAccountKey.json')
# default_app = firebase_admin.initialize_app(cred)
# db = firestore.client()

# doc_ref = db.collection(u'libraries').document(u'baileuu')
# info = doc_ref.get()

#This code creates a listener that listens to the realtime database (not the cloud firestore)
# # Import database module.
# from firebase_admin import db
# from firebase_admin import credentials
# import firebase_admin

# cred = credentials.Certificate('./ServiceAccountKey.json')
# default_app = firebase_admin.initialize_app(cred)

# # Get a database reference to our posts
# ref = db.reference(path=r'/', app=default_app, url=r"https://studynow-f5337.firebaseio.com/")

# # Read the data at the posts reference (this is a blocking operation)
# print(ref.get())

print("ay okay")