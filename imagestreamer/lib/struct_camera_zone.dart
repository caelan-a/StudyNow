class CameraZone {
  String libraryID;
  String floorID;
  String cameraZoneID;
  int numCapturesPerInterval;
  int timeInterval; // s

  CameraZone(
      {this.libraryID,
      this.floorID,
      this.cameraZoneID,
      this.numCapturesPerInterval,
      this.timeInterval});

  void setCameraZone(
      libraryID, floorID, cameraZoneID, numCapturesPerInterval, timeInterval) {
    this.libraryID = libraryID;
    this.floorID = floorID;
    this.cameraZoneID = cameraZoneID;
    this.numCapturesPerInterval = int.parse(numCapturesPerInterval);
    this.timeInterval = int.parse(timeInterval);
  }

  String getFirebasePath() {
    return "/libraries/" +
        libraryID +
        "/floors/" +
        floorID +
        "/camera_zones/" +
        cameraZoneID;
  }
}
