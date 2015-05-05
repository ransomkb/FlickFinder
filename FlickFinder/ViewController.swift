//
//  ViewController.swift
//  FlickFinder
//
//  Created by Ransom Barber on 5/4/15.
//  Copyright (c) 2015 Hart Book. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var stringTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    
    @IBOutlet weak var imageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func searchByString(sender: UIButton) {
        
    }
    
    @IBAction func searchByLatAndLong(sender: UIButton) {
        
    }
}

