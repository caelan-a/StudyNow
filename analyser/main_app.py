import logging
from flask import Flask
import firebase_admin
from firebase_admin import credentials,firestore

app = Flask(__name__)

@app.route('/')
def setFirebaseField():
    cred = credentials.Certificate('./ServiceAccountKey.json')
    default_app = firebase_admin.initialize_app(cred)
    db = firestore.client()

    doc_ref = db.collection(u'libraries').document(u'baileuu')
    doc_ref.update({
        u'chairs_present': 41,
        u'people_present': 21,
    })
    print("Successfully written")

    try:
        doc = doc_ref.get()
        print(u'Document data: {}'.format(doc.to_dict()))
    except firebase_admin.cloud.exceptions.NotFound:
        print(u'No such document!')

    return 'Firebase successfully updated'

# @app.route('/')
# def hello():
#     """Return a friendly HTTP greeting."""
#     return 'Hello World!'


@app.errorhandler(500)
def server_error(e):
    logging.exception('An error occurred during a request.')
    return """
    An internal error occurred: <pre>{}</pre>
    See logs for full stacktrace.
    """.format(e), 500


if __name__ == '__main__':
    # This is used when running locally. Gunicorn is used to run the
    # application on Google App Engine. See entrypoint in app.yaml.
    app.run(host='127.0.0.1', port=8080, debug=True)
# [END gae_flex_quickstart]