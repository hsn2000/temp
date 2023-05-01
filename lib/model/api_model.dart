class api {
  final String detector_backend;
  final num distance;
  final img facial_areas;
  final String model;
  final String similarity_metric;
  final num threshold;
  final num time;
  final String verified;
    

  const api({
    required this.detector_backend,
    required this.distance,
    required this.facial_areas,
    required this.model,
    required this.similarity_metric,
    required this.threshold,
    required this.time,
    required this.verified,
  });

  factory api.fromJson(Map<String, dynamic> json) {
    return api(
      detector_backend: json['detector_backend'],
      distance: json['distance'],
      facial_areas: img.fromJson(json['facial_areas']),
      model:json['model'],
      similarity_metric: json['similarity_metric'],
      threshold:json['threshold'],
      time:json['time'],
      verified:json['verified'],
    );
  }
}

class img {
  final vls img1;
  final vls img2;

  const img({
    required this.img1,
    required this.img2,
  });
  factory img.fromJson(Map<String, dynamic> json) {
    return img(
      img1: vls.fromJson(json['img1']),
      img2: vls.fromJson(json['img2']),
    );
  }
}

class vls {
  final num h;
  final num w;
  final num x;
  final num y;

  const vls({
    required this.h,
    required this.w,
    required this.x,
    required this.y,
  });

  factory vls.fromJson(Map<String, dynamic> json) {
    return vls(
      h: json['h'],
      w: json['w'],
      x: json['x'],
      y: json['y'],
    );
  }
}
