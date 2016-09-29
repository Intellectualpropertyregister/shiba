var currentMap;
var historyMap;

$(document).ready(function(){
    if (typeof google != 'undefined'){
        google.maps.event.addDomListener(window, 'load', function() {
            initializeMap(41.883799, -87.63163);
            rest_get_method("api/v1/map/tips",{},displayTips)
            rest_get_method("api/v1/map/visualize_current",
              {
                city_name : "Chicago", 
                map_name: "currentMap"
              },
              displayGrid)
            rest_get_method("api/v1/map/visualize_current",
              {
                city_name : "Chicago", 
                map_name: "historyMap"
              },
              displayGrid)
        });
    }
});

function displayTips(result){
  console.log(result.length)
  for(var i = 0; i < result.length; i ++){
    var tip = result[i];
    var marker = new google.maps.Marker({
      position: new google.maps.LatLng(tip.latitude, tip.longitude),
      map: currentMap,
      title: tip.description
    });
  }
};

function displayGrid(result){
  var report = result.report
  var target_map

  if(result.map == "currentMap"){
    target_map = currentMap
  }
  else if (result.map == "historyMap"){
    target_map = historyMap
  }

  for(var i = 0; i < report.length; i ++){
    for(var j = 0; j < report[i].length; j ++){
      var grid = report[i][j];
      var rectangle = new google.maps.Rectangle({
        strokeColor: result.map == "currentMap" ? grid.color_code : grid.history_color_code,
        strokeOpacity: 0.8,
        strokeWeight: 2,
        fillColor: result.map == "currentMap" ? grid.color_code : grid.history_color_code,
        fillOpacity: 0.35,
        map: target_map,
        bounds: new google.maps.LatLngBounds(
          new google.maps.LatLng(grid.btm_right_lat, grid.top_left_lng),
          new google.maps.LatLng(grid.top_left_lat, grid.btm_right_lng)
          )
      });
    }
  }
};


function initializeMap(latitude, longitude){

  google.maps.Map.prototype.markers = new Array();
  google.maps.Map.prototype.getMarkers = function(){
    return this.markers
  };

  google.maps.Map.prototype.clearMarkers = function(){
    for(var i = 0; i < this.markers.length; i++){
      this.markers[i].setMap(null);
    }
    this.markers = new Array();
  };

  google.maps.Map.prototype.rectangles = new Array();
    google.maps.Map.prototype.getRectangles = function() {
        return this.rectangles
    };

  google.maps.Map.prototype.clearRectangles = function() {
        for(var i=0; i<this.rectangles.length; i++){
            this.rectangles[i].setMap(null);
        }
        this.rectangles = new Array();
    };

  google.maps.Marker.prototype._setMap = google.maps.Marker.prototype.setMap;
  google.maps.Marker.prototype.setMap = function(map){
    if(map){
      map.markers[map.markers.length] = this;
    }
    this._setMap(map);
  };

  var mapProperties = {
    center: new google.maps.LatLng(latitude,longitude),
    zoom: 10,
    scrollwheel: false,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  };

  currentMap = new google.maps.Map(document.getElementById('current-canvas'), mapProperties);
  historyMap = new google.maps.Map(document.getElementById('history-canvas'), mapProperties);

};

function enableScrollWheelOnMap() {
    this.setOptions({
        scrollwheel: true
    });
}
