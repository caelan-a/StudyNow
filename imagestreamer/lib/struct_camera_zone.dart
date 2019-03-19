class CameraZone {
  String libraryID;
  String floorID;
  String cameraZoneID;

  CameraZone({this.libraryID, this.floorID, this.cameraZoneID});

  void setCameraZone(libraryID, floorID, cameraZoneID) {
    this.libraryID = libraryID;
    this.floorID = floorID;
    this.cameraZoneID = cameraZoneID;
  }

  String getFirebasePath() {
    return "/libraries/" +
        libraryID +
        "/floors/" +
        floorID +
        "/camera_zone/" +
        cameraZoneID;
  }
}
