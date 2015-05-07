//
//  ViewController.swift
//  FlickFinder
//
//  Created by Ransom Barber on 5/4/15.
//  Copyright (c) 2015 Hart Book. All rights reserved.
//

import UIKit

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "35c8d5a00d63b2ba2caf97759109cabf"
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var stringTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    
    @IBOutlet weak var defaultLabel: UILabel!
    @IBOutlet weak var imageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.stringTextField.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        stringTextField.resignFirstResponder()
        return true
    }
    
    @IBAction func searchByString(sender: UIButton) {
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "text": "baby asian elephant",
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        getImageFromFlickrBySearch(methodArguments)
    }
    
    @IBAction func searchByLatAndLong(sender: UIButton) {
        println("Will implement this function in a later step ...")
    }
    
    func getImageFromFlickrBySearch(methodArguments: [String : AnyObject]) {
        let session = NSURLSession.sharedSession()
        
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            // all in closure, back thread
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                println(parsedResult)
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    println(photosDictionary)
                    
                    var totalPhotosValue = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosValue = (totalPhotos as NSString).integerValue
                    }
                    
                    if totalPhotosValue > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String:AnyObject]] {
                            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                            let randomPhotoDictionary = photosArray[randomPhotoIndex] as [String:AnyObject]
                            
                            let photoTitle = randomPhotoDictionary["title"] as? String
                            let imageURLString = randomPhotoDictionary["url_m"] as? String
                            println(imageURLString)
                            let url = NSURL(string: imageURLString!)
                            
                            
                            if let imageData = NSData(contentsOfURL: url!) {
                                //do all updates on main thread
                                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                                    //make these updates minimal!!!
                                    self.defaultLabel.alpha = 0.0
                                    self.imageView.image = UIImage(data: imageData)
                                    self.imageLabel.text = photoTitle
                                })
                            } else {
                                println("Image does not exist at \(url)")
                            }
                        } else {
                            println("Can't find key 'photo' in \(photosDictionary)")
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.imageLabel.text = "Sorry, but we could not find that flick."
                            self.imageView.image = nil
                            self.defaultLabel.alpha = 1.0
                        })
                    }
                    //MyOriginal version
//                    if let photoArray = photosDictionary.valueForKey("photo") as? NSArray {
//                        let photoCount = photoArray.count
//                        if photoCount == 0 {
//                            self.imageLabel.text = "Sorry! We got no photos."
//                        } else {
//                            println("We found \(photoCount) photos.")
//                            self.imageLabel.text = "We found \(photoCount) photos."
//                            
//                            // Wrap the random UInt32 in Int for array.
//                            let randomNumber = Int(arc4random_uniform(UInt32(photoCount)))
//                            println("Random Photo Number is \(randomNumber)")
//                            let randomPhoto = photoArray[randomNumber] as? NSDictionary
//                            println(randomPhoto)
//                            let urlString = randomPhoto?.valueForKey("url_m") as! String
//                            println("URL: \(urlString)")
//                        }
//                    }
                } else {
                    println("Can't find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        
        for (key, value) in parameters {
            let stringValue: String = value as! String
            
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            let requestSnippet = key + "=" + "\(escapedValue!)"
            //println(requestSnippet)
            urlVars += [requestSnippet]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
}

