from .defaults import argHandler #Import the default arguments
import os
from .net.build import TFNet
import cv2

def detectNumPpl(tfnet, path=None, image=None):
    if path:
        image = cv2.imread(path, 1)
    tfnet.update_image(image)
    return tfnet.getNumPPl()



# print(cliHandler(theArgs, image))

# tfnet.update_image(image)
# print(tfnet.getNumPPl())

def createInstance(args):
    FLAGS = argHandler()
    FLAGS.setDefaults()
    FLAGS.parseArgs(args)

    # make sure all necessary dirs exist
    def _get_dir(dirs):
        for d in dirs:
            this = os.path.abspath(os.path.join(os.path.curdir, d))
            if not os.path.exists(this): os.makedirs(this)
    
    requiredDirectories = [FLAGS.imgdir, FLAGS.binary, FLAGS.backup, os.path.join(FLAGS.imgdir,'out')]
    if FLAGS.summary:
        requiredDirectories.append(FLAGS.summary)

    _get_dir(requiredDirectories)

    # fix FLAGS.load to appropriate type
    try: FLAGS.load = int(FLAGS.load)
    except: pass

    tfnet = TFNet(FLAGS)


    # tfnet.predict()
    # tfnet.update_image(image)

    # return tfnet.getNumPPl()
    return tfnet