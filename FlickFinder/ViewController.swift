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

let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}

extension ViewController {
    func dismissAnyVisibleKeyboards() {
        if stringTextField.isFirstResponder() || latitudeTextField.isFirstResponder() || longitudeTextField.isFirstResponder() {
            self.view.endEditing(true)
        }
    }
}

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var stringTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    
    @IBOutlet weak var defaultLabel: UILabel!
    @IBOutlet weak var imageLabel: UILabel!
    
    var tapRecognizer: UITapGestureRecognizer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.stringTextField.delegate = self
        tapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        tapRecognizer?.numberOfTapsRequired = 1
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addKeyboardDismissRecognizer()
        self.subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.removeKeyboardDismissRecognizer()
        self.unsubscribeFromKeyboardNotifications()
    }

    // Although it looks like we are using gesture recognizers this time around,
    // using the return key to search would be convenient. ()
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        stringTextField.resignFirstResponder()
        self.searchByString(self)
        return true
    }
    
    func addKeyboardDismissRecognizer() {
        self.view.addGestureRecognizer(tapRecognizer!)
    }
    
    func removeKeyboardDismissRecognizer() {
        self.view.removeGestureRecognizer(tapRecognizer!)
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if self.imageView.image != nil {
            self.defaultLabel.alpha = 0.0
        }
        
        self.view.frame.origin.y = -getKeyboardHeight(notification)/2
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if self.imageView.image == nil {
            self.defaultLabel.alpha = 1.0
        }
        self.view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    @IBAction func searchByString(sender: AnyObject) {
        
        self.latitudeTextField.text = ""
        self.longitudeTextField.text = ""
        
        self.dismissAnyVisibleKeyboards()
        
        if !self.stringTextField.text.isEmpty && self.stringTextField.text != "" {
            // old searc was hard coded for "baby asian elephant"
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "text": self.stringTextField.text,
                "safe_search": SAFE_SEARCH,
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK
            ]
            
            getImageFromFlickrBySearch(methodArguments)
        } else {
            self.imageLabel.text = "Please enter a word or phrase."
        }
    }
    
    @IBAction func searchByLatAndLong(sender: AnyObject) {
        
        self.stringTextField.text = ""
        
        self.dismissAnyVisibleKeyboards()
        
        if !self.latitudeTextField.text.isEmpty && !self.longitudeTextField.text.isEmpty {
            if validLatitude() && validLongitude() {
                self.imageLabel.text = "Searching..."
                let methodArguments = [
                    "method": METHOD_NAME,
                    "api_key": API_KEY,
                    "bbox": createBoundingBoxString(),
                    "safe_search": SAFE_SEARCH,
                    "extras": EXTRAS,
                    "format": DATA_FORMAT,
                    "nojsoncallback": NO_JSON_CALLBACK
                ]
                getImageFromFlickrBySearch(methodArguments)
            } else {
                if !validLatitude() && !validLongitude() {
                    self.imageLabel.text = "Lat/Long Invalid.\nLat should be [-90, 90].\nLong should be [-180, 180]"
                } else if !validLatitude() {
                    self.imageLabel.text = "Lat Invalid.\nLat should be [-90, 90]."
                } else {
                    self.imageLabel.text = "Long Invalid.\nLong should be [-180, 180]."
                }
            }
        } else {
            if self.latitudeTextField.text.isEmpty && self.longitudeTextField.text.isEmpty {
                self.imageLabel.text = "Lat & Long are Empty."
            } else if self.latitudeTextField.text.isEmpty {
                self.imageLabel.text = "Lat is Empty."
            } else {
                self.imageLabel.text = "Long is Empty."
            }
        }
    }
    
    func validLatitude() -> Bool {
        if let latitude : Double? = self.latitudeTextField.text.toDouble() {
            if latitude < LAT_MIN || latitude > LAT_MAX {
                return false
            }
        } else {
            return false
        }
        return true
    }
    
    func validLongitude() -> Bool {
        if let longitude: Double? = self.longitudeTextField.text.toDouble() {
            if longitude < LON_MIN || longitude > LON_MAX {
                return false
            }
        } else {
            return false
        }
        return true
    }
    
    func getLatLongString() -> String {
        let latitude = (self.latitudeTextField.text as NSString).doubleValue
        let longitude = (self.longitudeTextField.text as NSString).doubleValue
        
        return "\(latitude),\(longitude)"
    }
    
    // No longer using this
    func checkStringSearch() -> String {
        if let searchText = self.stringTextField.text {
            if searchText == "" || searchText.isEmpty {
                self.imageLabel.text = "Please enter a word or phrase."
            }
            return searchText
        } else {
            self.imageLabel.text = "Please enter a word or phrase."
            return ""
        }
    }
    
    func createBoundingBoxString() -> String {
        let latitude = (self.latitudeTextField.text as NSString).doubleValue
        let longitude = (self.longitudeTextField.text as NSString).doubleValue
        
        let bottom_left_long = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_long = min(longitude + BOUNDING_BOX_HALF_WIDTH, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_long),\(bottom_left_lat),\(top_right_long),\(top_right_lat)"
    }
    
    func getImageFromFlickrBySearch(methodArguments: [String:AnyObject]) {
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    if let totalPages = photosDictionary["pages"] as? Int {
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage)
                    } else {
                        println("Can't find key 'pages' in \(photosDictionary)")
                    }
                } else {
                    println("Can't find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
    }
    
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int) {
        
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
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
                // println(parsedResult)
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    //println(photosDictionary)
                    
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
                            let imageURL = NSURL(string: imageURLString!)
                            
                            if let imageData = NSData(contentsOfURL: imageURL!) {
                                //do all updates on main thread
                                dispatch_async(dispatch_get_main_queue(), {
                                    //make these updates minimal!!!
                                    self.defaultLabel.alpha = 0.0
                                    self.imageView.image = UIImage(data: imageData)
                                    
                                    if methodArguments["bbox"] != nil {
                                        self.imageLabel.text = "\(self.getLatLongString()) \(photoTitle)"
                                    } else {
                                        self.imageLabel.text = photoTitle
                                    }
                                })
                            } else {
                                println("Image does not exist at \(imageURL)")
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

