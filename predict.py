import os
import sys

from google.cloud import automl_v1beta1
from google.cloud.automl_v1beta1.proto import service_pb2

#print('Credendtials from environ: {}'.format(
    #os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')))



# project id cs131-1552025416924 
# model id ICN6390988586782325408
def get_prediction(content):
  prediction_client = automl_v1beta1.PredictionServiceClient()

  name = 'projects/{}/locations/us-central1/models/{}'.format("cs131-1552025416924" , "ICN4441192999165309033")
  payload = {'image': {'image_bytes': content }}
  params = {}
  request = prediction_client.predict(name, payload, params)
  return request  # waits till request is returned

if __name__ == '__main__':
  file_path = sys.argv[1]
  project_id = sys.argv[2]
  model_id = sys.argv[3]

  with open(file_path, 'rb') as ff:
    content = ff.read()

  print get_prediction(content, project_id,  model_id)