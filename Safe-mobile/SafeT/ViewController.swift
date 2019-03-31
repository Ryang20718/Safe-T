import Alamofire
import SwiftyJSON
import UIKit
import MapKit
import CoreLocation
import CSV
import Foundation

var message_plus = ""
var score = 1.0

func getDistanceFromLatLonInKm(lat1: Double,lon1: Double,lat2: Double,lon2: Double) -> Double{
    let R = 6371.0
    let latDif = lat2-lat1
    let longDif = lon2-lon1
    let dLat = deg2rad(deg: latDif)
    let dLon = deg2rad(deg: longDif)
    let a =
        sin(dLat/2) * sin(dLat/2) +
            cos(deg2rad(deg: lat1)) * cos(deg2rad(deg: lat2)) *
            sin(dLon/2) * sin(dLon/2)
    
    let c = 2 * atan2(sqrt(a), sqrt(1-a));
    let d = R * c; // Distance in km
    return d;
}

func deg2rad(deg: Double) -> Double {
    return deg * (3.14/180)
}
class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    let locationManager = CLLocationManager()
    var currentLocation:CLLocation?
    @IBOutlet weak var mapView: MKMapView!
    
    var classANums = 0
    var classBNums = 0
    var classCNums = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectLatitude.delegate = self
        selectLongitude.delegate = self
        self.mapView.showsUserLocation = true;
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        mapView.userTrackingMode = .follow
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func removeAnnotations(){
        mapView.removeAnnotations(mapView.annotations)
    }
    @IBAction func showAlert(){
        let locValue:CLLocationCoordinate2D = locationManager.location!.coordinate
        
        let ownLat = 34.075326
        let ownLong = -118.444893
        let myLocationTest = CLLocation(latitude: ownLat, longitude: ownLong)
        let region = MKCoordinateRegionMakeWithDistance(myLocationTest.coordinate, 2000, 2000)
        self.mapView.setRegion(region, animated: true)
        //START
        let lat = String(ownLat)
        let long = String(ownLong)
        
        let urlSTR = "https://maps.googleapis.com/maps/api/geocode/json?latlng=" + lat + "," + long + "&key=AIzaSyBO8RppEC_eIk5jKhW541jD1k7i8MUMb_4"
        let url = URL(string: urlSTR)
        URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                let posts = json["results"] as? [[String: Any]] ?? []
                if let name = (posts[0])["address_components"] {
                    if let array = name as? [[String: Any]] {
                        let taskArray = array.flatMap { $0["short_name"] as? String }
                        let road_name = taskArray[1].uppercased()
                        
                        let url2 = "https://data.lacity.org/resource/yjxu-2kqq.json?st_name=" + road_name
                        if let url3 = url2.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                            Alamofire.request(url3).responseJSON { response in
                                if let json = response.result.value{
                                    let newJSON = JSON(json)
                                    let roadNum = "\(newJSON[0]["pci"])"

                                    let distURL = "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=34.070349,-118.446470&destinations=" + lat + "," + long + "&key=AIzaSyBO8RppEC_eIk5jKhW541jD1k7i8MUMb_4"
                                    Alamofire.request(distURL).responseJSON { response in
                                        if let json = response.result.value{
                                            let newJSON = JSON(json)
                                            let dist = "\(newJSON["rows"][0]["elements"][0]["distance"]["text"])".components(separatedBy: " ")
                                            
                                            score = 1.0
                                            var dist_score = 1.0
                                            
                                            message_plus = ""
                                            message_plus += "From " + taskArray[1] + " to UCLA\n"
                                            
                                            if (roadNum != "") {
                                                let road_score = (roadNum as NSString).doubleValue
                                                if (road_score < 30) {
                                                    message_plus += "Road too bumpy!\n"
                                                }
                                                message_plus += "Road quality rated " + String(road_score) + "/100\n"
                                                score = score * road_score
                                            }
                                            if (dist[1] == "ft") {
                                                dist_score = 1.2 - (((dist[0] as NSString).doubleValue) / 25000)
                                            }
                                            if (dist[1] == "mi") {
                                                dist_score = 1.2 - (((dist[0] as NSString).doubleValue) / 5)
                                            }
                                            dist_score = min(dist_score,1.0)
                                            dist_score = max(dist_score,0.0)
                                            score *= dist_score
                                            if (dist_score > 0) {
                                                message_plus += String(dist[0]) + " mile trip\n"
                                            }
                                            else {
                                                message_plus += "Trip too far! " + String(dist[0]) + " miles away!\n"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } catch let error as NSError {
                print(error)
            }
        }).resume()
        
        
        
        //END
        let classA = [110, 230, 251]
        let classB = [624, 236, 626]
        let classC = [510, 310, 210, 341, 330]
        let classD = [886, 930]
        let stream = InputStream(fileAtPath: "/Users/kevinzhang/CS117-SafeT/Crime_Data_from_2010_to_Present.csv")!
        let csv = try! CSVReader(stream: stream)
        var locationA:CLLocationCoordinate2D
        
        var numAPointers = 0;
        var numBPointers = 0;
        var numCPointers = 0;
        var placeA = true;
        var placeB = true;
        var placeC = true;
        classANums = 0
        classBNums = 0
        classCNums = 0
        var crimeSurveyed = 0
        while let row = csv.next() {
            var array = row[3].components(separatedBy: ", ")
            if array.count == 2 {
                var arr1 = array[0].components(separatedBy: "(")
                var arr2 = array[1].components(separatedBy: ")")
                let lat = (arr1[1] as NSString).doubleValue
                let long = (arr2[0] as NSString).doubleValue
                let d = getDistanceFromLatLonInKm(lat1: lat, lon1: long, lat2: ownLat, lon2: ownLong)
                
                if d < 2 {
                    //print(lat, long)
                    let crimeCode = (row[1] as NSString).integerValue
                    var data = row[0].components(separatedBy: "/");
                    var month = (data[0] as NSString).integerValue
                    let year = (data[2] as NSString).integerValue
                    let calendar = NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)
                    
                    let currentYearInt = (calendar?.component(NSCalendar.Unit.year, from: Date()))!
                    
                    if(classA.contains(crimeCode) && ((currentYearInt - 2000 - year) <= 10)){
                        classANums = classANums + 1;
                        if(d<1 && placeA){
                            let annotation = MKPointAnnotation()
                            annotation.title = "Class A"
                            annotation.subtitle = "High Threat"
                            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            mapView.addAnnotation(annotation)
                            numAPointers = numAPointers + 1
                            if(numAPointers >= 5){
                                placeA = false
                            }
                        }
                        //                        print("ClassANums: ")
                        //                        print(classANums)
                    }
                    if(classB.contains(crimeCode) && ((currentYearInt - 2000 - year) <= 10)){
                        classBNums = classBNums + 1;
                        if(d<1 && placeB){
                            let annotation = MKPointAnnotation()
                            annotation.title = "Class B"
                            annotation.subtitle = "Medium Threat"
                            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            mapView.addAnnotation(annotation)
                            numBPointers = numBPointers + 1
                            if(numAPointers >= 5){
                                placeB = false
                            }
                        }
                    }
                    if(classC.contains(crimeCode) && ((currentYearInt - 2000 - year) <= 10)){
                        classCNums =  classCNums + 1;
                        if(d<1 && placeC){
                            let annotation = MKPointAnnotation()
                            annotation.title = "Class C"
                            annotation.subtitle = "Low Threat"
                            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            mapView.addAnnotation(annotation)
                            numCPointers = numCPointers + 1
                            if(numCPointers >= 5){
                                placeC = false
                            }
                        }
                    }
                }
            }
            crimeSurveyed = crimeSurveyed+1
            if(crimeSurveyed > 5000){
                break
            }
        }
        var danger = 0;
        if(classANums > 50){
            danger = danger + 10
        }
        if(classBNums > 500){
            danger = danger + 5
        }
        if(classCNums > 500){
            danger = danger + 1
        }
        
        if(danger >= 10){
            let alert = UIAlertController(title: "High Danger Area!", message: message_plus + "Danger level: Murder, Aggravated Assult, Etc.\nSafe Travel Score: " + String(score * 0), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Acknowledge", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else if(danger >= 5){
            let alert = UIAlertController(title: "Medium Danger Area!", message: message_plus + "Danger level: Theft, Assult, Etc.\nSafe Travel Score: " + String(score * 0.4), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Acknowledge", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else if(danger >= 1){
            let alert = UIAlertController(title: "Low Risk Area!", message: message_plus + "Danger level: Vandalism, Verbal Threats, Etc.\nSafe Travel Score: " + String(score * 0.8), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Acknowledge", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else{
            let alert = UIAlertController(title: "Crime Free Zone", message: message_plus + "Danger Level: Safe\nSafe Travel Score: " + String(score * 1), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Acknowledge", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [AnyObject]!) { // Centers the map to the user location
        print("in locationManager")
        let location = locations.last as! CLLocation
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        currentLocation = locations[locations.count-1] as! CLLocation
        let curLoc = currentLocation as! CLLocation
        
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        if let location = locations.last{
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: true)
        }
        defer { currentLocation = locations.last as! CLLocation }

        if currentLocation == nil {
            if let userLocation = locations.last {
                let viewRegion = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 2000, 2000)
                mapView.setRegion(viewRegion, animated: false)
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectLongitude.resignFirstResponder()
        selectLatitude.resignFirstResponder()
    }
    @IBOutlet weak var selectLatitude: UITextField!
    
    @IBOutlet weak var selectLongitude: UITextField!

    @IBAction func checkCoordinates(_ sender: Any) {
        let latitude = (selectLatitude.text as! NSString).doubleValue
        let longitude = (selectLongitude.text as! NSString).doubleValue
        mapView.userTrackingMode = .none
        let myLocationTest = CLLocation(latitude: latitude, longitude: longitude)
        let center = CLLocationCoordinate2D(latitude: myLocationTest.coordinate.latitude, longitude: myLocationTest.coordinate.longitude)
        
        let lat = String(latitude)
        let long = String(longitude)
        
        let urlSTR = "https://maps.googleapis.com/maps/api/geocode/json?latlng=" + lat + "," + long + "&key=AIzaSyBO8RppEC_eIk5jKhW541jD1k7i8MUMb_4"
        let url = URL(string: urlSTR)
        URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                let posts = json["results"] as? [[String: Any]] ?? []
                if let name = (posts[0])["address_components"] {
                    if let array = name as? [[String: Any]] {
                        let taskArray = array.flatMap { $0["short_name"] as? String }
                        let road_name = taskArray[1].uppercased()
                        
                        let url2 = "https://data.lacity.org/resource/yjxu-2kqq.json?st_name=" + road_name
                        if let url3 = url2.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                            print(url3)
                            Alamofire.request(url3).responseJSON { response in
                                if let json = response.result.value{
                                    let newJSON = JSON(json)
                                    let roadNum = "\(newJSON[0]["pci"])"
                                    
                                    let distURL = "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=34.069933,-118.451254&destinations=" + lat + "," + long + "&key=AIzaSyBO8RppEC_eIk5jKhW541jD1k7i8MUMb_4"
                                    Alamofire.request(distURL).responseJSON { response in
                                        if let json = response.result.value{
                                            let newJSON = JSON(json)
                                            let dist = "\(newJSON["rows"][0]["elements"][0]["distance"]["text"])".components(separatedBy: " ")
                                            
                                            score = 1.0
                                            var dist_score = 1.0
                                            
                                            message_plus = ""
                                            message_plus += "From " + taskArray[1] + " to UCLA\n"
                                            
                                            if (roadNum != "") {
                                                let road_score = (roadNum as NSString).doubleValue
                                                if (road_score < 30) {
                                                    message_plus += "Road too bumpy!\n"
                                                }
                                                message_plus += "Road quality rated " + String(road_score) + "/100\n"
                                                score = score * road_score
                                            }
                                            if (dist[1] == "ft") {
                                                dist_score = 1.2 - (((dist[0] as NSString).doubleValue) / 25000)
                                            }
                                            if (dist[1] == "mi") {
                                                dist_score = 1.2 - (((dist[0] as NSString).doubleValue) / 5)
                                            }
                                            dist_score = min(dist_score,1.0)
                                            dist_score = max(dist_score,0.0)
                                            score *= dist_score
                                            if (dist_score > 0) {
                                                message_plus += String(dist[0]) + " mile trip\n"
                                            }
                                            else {
                                                message_plus += "Trip too far! " + String(dist[0]) + " miles away!\n"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } catch let error as NSError {
                print(error)
            }
        }).resume()
        
        
        let region = MKCoordinateRegionMakeWithDistance(myLocationTest.coordinate, 2000, 2000)
        self.mapView.setRegion(region, animated: true)
        let classA = [110, 230, 251]
        let classB = [624, 236, 626]
        let classC = [510, 310, 210, 341, 330]
        let classD = [886, 930]
        let stream = InputStream(fileAtPath: "/Users/kevinzhang/CS117-SafeT/Crime_Data_from_2010_to_Present.csv")!
        let csv = try! CSVReader(stream: stream)
        var locationA:CLLocationCoordinate2D
        
        var numAPointers = 0;
        var numBPointers = 0;
        var numCPointers = 0;
        var placeA = true;
        var placeB = true;
        var placeC = true;
        
        classANums = 0
        classBNums = 0
        classCNums = 0
        var crimeSurveyed = 0
        while let row = csv.next() {
            var array = row[3].components(separatedBy: ", ")
            if array.count == 2 {
                var arr1 = array[0].components(separatedBy: "(")
                var arr2 = array[1].components(separatedBy: ")")
                let lat = (arr1[1] as NSString).doubleValue
                let long = (arr2[0] as NSString).doubleValue
                let d = getDistanceFromLatLonInKm(lat1: lat, lon1: long, lat2: latitude, lon2: longitude)
                if d < 2 {
                    var crimeCode = (row[1] as NSString).integerValue
                    var data = row[0].components(separatedBy: "/");
                    var month = (data[0] as NSString).integerValue
                    var year = (data[2] as NSString).integerValue
                    let calendar = NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)
                    let currentYearInt = (calendar?.component(NSCalendar.Unit.year, from: Date()))!
                    
                    if(classA.contains(crimeCode) && ((currentYearInt - 2000 - year) <= 10)){
                        classANums = classANums + 1;
                        if(d<1 && placeA){
                            let annotation = MKPointAnnotation()
                            annotation.title = "Class A"
                            annotation.subtitle = "High Threat"
                            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            mapView.addAnnotation(annotation)
                            numAPointers = numAPointers + 1
                            if(numAPointers >= 5){
                                placeA = false
                            }
                        }
                    }
                    if(classB.contains(crimeCode) && ((currentYearInt - 2000 - year) <= 10)){
                        classBNums = classBNums + 1;
                        if(d<1 && placeB){
                            let annotation = MKPointAnnotation()
                            annotation.title = "Class B"
                            annotation.subtitle = "Medium Threat"
                            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            mapView.addAnnotation(annotation)
                            numBPointers = numBPointers + 1
                            if(numAPointers >= 5){
                                placeB = false
                            }
                        }
                    }
                    if(classC.contains(crimeCode) && ((currentYearInt - 2000 - year) <= 10)){
                        classCNums =  classCNums + 1;
                        if(d<1 && placeC){
                            let annotation = MKPointAnnotation()
                            annotation.title = "Class C"
                            annotation.subtitle = "Low Threat"
                            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                            mapView.addAnnotation(annotation)
                            numCPointers = numCPointers + 1
                            if(numCPointers >= 5){
                                placeC = false
                            }
                        }
                    }
                }
            }
            crimeSurveyed = crimeSurveyed+1
            if(crimeSurveyed > 5000){
                break
            }
        }
        var danger = 0;
        if(classANums > 50){
            danger = danger + 10
        }
        if(classBNums > 500){
            danger = danger + 5
        }
        if(classCNums > 500){
            danger = danger + 1
        }
        
        if(danger >= 10){
            let alert = UIAlertController(title: "High Danger Area!", message: message_plus + "Danger level: Murder, Aggravated Assult, Etc.\nSafe Travel Score: " + String(score * 0), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Acknowledge", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else if(danger >= 5){
            let alert = UIAlertController(title: "Medium Danger Area!", message: message_plus + "Danger level: Theft, Assult, Etc.\nSafe Travel Score: " + String(score * 0.4), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Acknowledge", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else if(danger >= 1){
            let alert = UIAlertController(title: "Low Risk Area!", message: message_plus + "Danger level: Vandalism, Verbal Threats, Etc.\nSafe Travel Score: " + String(score * 0.8), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Acknowledge", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else{
            let alert = UIAlertController(title: "Crime Free Zone", message: message_plus + "Danger Level: Safe\nSafe Travel Score: " + String(score * 1), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Acknowledge", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
