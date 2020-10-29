//
//  MapVC.swift
//  PixelCity
//
//  Created by Mahesh on 28/10/20.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate{

    //  Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    
    var spinner : UIActivityIndicatorView?
    var progressLabel : UILabel?
    
    var collectionView : UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()
    
    var locationManager = CLLocationManager()
    let autorizationStatus = CLLocationManager.authorizationStatus()
    
    let regionRadius : Double = 1000
    var screenSize = UIScreen.main.bounds
    
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    var imageIdArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        mapView.showsUserLocation = true
        configureLocationServices()
        addDoubleTap()
     
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width:75, height: 75)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300), collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = .white
        collectionView?.isPagingEnabled = true
        
        registerForPreviewing(with: self, sourceView: collectionView!)
        
        pullUpView.addSubview(collectionView!)
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(MapVC.dropPin(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown(_:)))
        swipe.direction = .down
        self.pullUpView.addGestureRecognizer(swipe)
    }
    
    @objc func animateViewDown(_ sender : UIGestureRecognizer) {
        cancelAllSessions()
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.style = .large
        spinner?.color = .darkGray
        spinner?.startAnimating()
        collectionView!.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel() {
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: (screenSize.width / 2) - 150, y: 175, width: 300, height: 40)
        progressLabel?.font = UIFont(name: "Avenir Next", size: 18)
        progressLabel?.textColor = .darkGray
        progressLabel?.textAlignment = .center
        progressLabel?.text = "12/40 Photos Loaded"
        collectionView!.addSubview(progressLabel!)
    }
    
    func removeProgressLabel() {
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
    }
    
    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if autorizationStatus == .authorizedAlways || autorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
    func retriveUrls(forAnnotation annotation: DroppablePin, handler: @escaping (_ status : Bool) -> ()) {
        
        
        Alamofire.request(flickrUrl(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 100)).responseJSON { (response) in
//            print(response)
//            handler(true)
            
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            guard let photosDict = json["photos"] as? Dictionary<String, AnyObject> else { return }
            
            guard let photoDictArray = photosDict["photo"] as? [Dictionary<String, AnyObject>] else { return }
            
            for photo in photoDictArray {
                
                guard let farm = photo["farm"] else { return }
                guard let server = photo["server"] else { return }
                guard let id = photo["id"] else { return }
                guard let secret = photo["secret"] else { return }
                
                let photoUrl = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
                self.imageUrlArray.append(photoUrl)
                self.imageIdArray.append(id as! String)
            }
            handler(true)
        }
    }
    
    func retriveImage(handler: @escaping (_ status : Bool) -> Void) {
        
        
        for url in imageUrlArray {
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLabel?.text = "\(self.imageArray.count)/40 images downloaded"
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
            }
        }
    }
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            
            sessionDataTask.forEach({$0.cancel()})
            downloadData.forEach({$0.cancel()})
//            for session in sessionDataTask {
//
//            }
        }
    }
}

extension MapVC : MKMapViewDelegate {
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension MapVC : CLLocationManagerDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = UIColor(named: "headerColor")
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    func configureLocationServices() {
        if autorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            centerMapOnUserLocation()
            return
        }
    }
    
    @objc func dropPin(_ sender : UITapGestureRecognizer) {
        
        removePin()
        removeSpinner()
        removeProgressLabel()
        cancelAllSessions()
        
        imageIdArray = []
        imageUrlArray = []
        imageArray = []
        
        collectionView?.reloadData()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLabel()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        print(flickrUrl(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 40))
        
        
        let coordinateRegion = MKCoordinateRegion(center: touchCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        retriveUrls(forAnnotation: annotation) { (finished) in
            if finished {
                self.retriveImage { (finish) in
                    if finish {
                        self.removeSpinner()
                        self.removeProgressLabel()
                        self.collectionView?.reloadData()
                    }
                }
            }
        }
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("locationManagerDidChangeAuthorization")
        centerMapOnUserLocation()
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
    {
        
    }
}
extension MapVC : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell {
            cell.configureCell(image: imageArray[indexPath.row])
            return cell
        }
        return PhotoCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVc = storyboard?.instantiateViewController(identifier: "PopVc") as? PopVc else { return }
        
        
        popVc.initData(withImageId: imageIdArray[indexPath.row], forImage: imageArray[indexPath.row])
        present(popVc, animated: true, completion: nil)
    }
    
}
extension MapVC : UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        print("preview 1")
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        
        guard let popVc = storyboard?.instantiateViewController(identifier: "PopVc") as? PopVc else { return nil }
        
        popVc.initData(withImageId: imageIdArray[indexPath.row], forImage: imageArray[indexPath.row])
        
        previewingContext.sourceRect = cell.contentView.frame
        
        return popVc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        print("show viewcontroller to commit")
        show(viewControllerToCommit, sender: self)
//        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
}
