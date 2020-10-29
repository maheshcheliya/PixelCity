//
//  Constants.swift
//  PixelCity
//
//  Created by Mahesh on 28/10/20.
//

import Foundation

let API_KEY = "b8d824114157599d500788a85cec879d"
//let URL_IMAGE_INFO =

func imageInfoUrl(forApiKey key : String, id : String) -> String {
    return "https://www.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=\(key)&photo_id=\(id)&format=json&nojsoncallback=1"
}

func flickrUrl(forApiKey key : String, withAnnotation anootation : DroppablePin, andNumberOfPhotos number : Int) -> String {
    let url = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(anootation.coordinate.latitude)&lon=\(anootation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    return url
}

//

