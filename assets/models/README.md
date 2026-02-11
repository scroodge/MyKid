# Face recognition model (optional)

The app uses ML Kit face detection with geometric landmark embeddings by default. For higher accuracy, you can add a TensorFlow Lite face recognition model (e.g. MobileFaceNet, ArcFace).

1. Obtain a `.tflite` model that:
   - Takes 112x112 or 160x160 RGB face crop as input
   - Outputs a 128-dimensional embedding

2. Place the model file as `face_recognition.tflite` in this directory.

3. The `FaceRecognitionService` can be extended to load and use the model when available.
