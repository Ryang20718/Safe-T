import cv2
import sys
from PIL import Image
import io
import predict #load in predict.py
import json

frame_skip = 500

cascPath = "haarcascade_frontalface_default.xml"
faceCascade = cv2.CascadeClassifier(cascPath)

video_capture = cv2.VideoCapture(0)
loop = True
cur_frame = 0
success = 0

while loop:
    
    # Capture frame-by-frame
    ret, frame = video_capture.read()

    if cur_frame % frame_skip == 0: # only analyze every n frames
        pil_img = Image.fromarray(frame) # convert opencv frame (with type()==numpy) into PIL Image
        stream = io.BytesIO()
        pil_img.save(stream, format='JPEG') # convert PIL Image to Bytes
        bin_img = stream.getvalue()
        
        response = predict.get_prediction(bin_img)
        for i in response.payload:
            print i.display_name
            if(i.classification.score > 0.3 or i.display_name == "ryan"):
                # success so unlock bluetooth
                print "Successfully unlocked"
                success += 1
                if success >= 4: loop = False
        
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        faces = faceCascade.detectMultiScale(
            gray,
            scaleFactor=1.1,
            minNeighbors=5,
            minSize=(30, 30),
            flags=cv2.CASCADE_SCALE_IMAGE
        )

        # Draw a rectangle around the faces
        for (x, y, w, h) in faces:
            cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)

        # Display the resulting frame
        cv2.imshow('Video', frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

# When everything is done, release the capture
video_capture.release()
cv2.destroyAllWindows()