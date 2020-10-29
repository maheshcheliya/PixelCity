//
//  PopVc.swift
//  PixelCity
//
//  Created by Mahesh on 29/10/20.
//

import UIKit
import MapKit
import Alamofire

class PopVc: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descLbl: UILabel!
    @IBOutlet weak var popImgView: UIImageView!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var passedImage : UIImage?
    var imageId : String?
    
    func initData(withImageId id : String, forImage image : UIImage) {
        self.imageId = id
        self.passedImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popImgView.image = self.passedImage
        addDoubleTap()
        
        guard let imgId = imageId else { return }
        
        retriveImageInfo(id: imgId)
    }
    
    func setMapViewRegion(latitude: Double, longitude : Double) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 200 * 2.0, longitudinalMeters: 200 * 2.0)
        let annotation = DroppablePin(coordinate: coordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    func retriveImageInfo(id : String) {
        
        Alamofire.request(imageInfoUrl(forApiKey: API_KEY, id: id)).responseJSON { (response) in
            guard response.result.error == nil else { return }
            
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            guard let photoDict = json["photo"] as? Dictionary<String, AnyObject> else { return }
            
//            get title from photo dictionary
            guard let titleDict = photoDict["title"] as? Dictionary<String, AnyObject> else { return }
            guard let titleStr = titleDict["_content"] as? String else { return }
            
//            get description photo dictionary
            guard let descDict = photoDict["description"] as? Dictionary<String, AnyObject> else { return }
            guard let desc = descDict["_content"] as? String else { return }
            
//            get dates from photo dictionary
            guard let datesDict = photoDict["dates"] as? Dictionary<String, AnyObject> else { return }
            guard let posted = datesDict["posted"] as? String else { return }
            
            let postedDate = self.getFormattedDate(timestamp: Double(posted)!)
            
//            get location coordinate from photo dictionary
            
            guard let locationDict = photoDict["location"] as? Dictionary<String, AnyObject> else { return }
            
            let lat = locationDict["latitude"] as? String
            let long = locationDict["longitude"] as? String
            
            
            self.titleLbl.text = titleStr
            self.descLbl.attributedText = desc.htmlToAttributedString!
            self.dateLbl.text = "Posted: \(postedDate)"
            self.setMapViewRegion(latitude: Double(lat!)!, longitude:Double(long!)!)
        }
    }
    
    func getFormattedDate(timestamp : Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT") //Set timezone that you want
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "MMMM dd, yyyy h:mm a" //Specify your format that you want
        let strDate = dateFormatter.string(from: date)
        return strDate
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenWasDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        self.view.addGestureRecognizer(doubleTap)
    }
    
    @objc func screenWasDoubleTapped() {
        dismiss(animated: true, completion: nil)
    }
}
extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {

            let text = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
            
            return text
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
