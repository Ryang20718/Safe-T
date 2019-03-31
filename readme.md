# Safe-T

- Custom trained model built and trained on google cloud automl.

- Python predict generates a rating out of 1 based on it's prediction.

- Face recognition to allow users to unlock/lock their vehicles.

### Setup
- First export path to cred.json file 
e.g export GOOGLE_APPLICATION_CREDENTIALS='/Users/ryanyang/Desktop/Unlocked/cred.json'

- Second run python predict.py /Users/ryanyang/Desktop/photos/IMG_20190315_091346.jpg cs131-1552025416924 ICN6390988586782325408, but replace image model and project with your own

- Run with Realtime face detection


### Safe-T mobile

This mobile version implements an IOS App that provides the functionality of scanning locations in the greater LA area for dangerous activity. It uses the LA Crime database and scans the database for activities and classifies them into Class A, B, and C for high, medium, and low danger. Based on the number of crimes reported recently within a certain area of your current location, we provide markers for recent crimes in your area and their locations and also a warning based on what class of danger you are in in the current location.

Additionally, our app utilizes LA street data and google maps API to calculate road ridability for electric vehicles in order to ensure safety for riders and also provide them with the information that they will need to check whether the road they want to ride is safe or not from origin to destination.