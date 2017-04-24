//
//  ViewController.swift
//  ADCountryPicker
//
//  Created by Amila on 21/4/17.
//  Copyright © 2017 Amila Diman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var countryCodeLabel: UILabel!
    @IBOutlet weak var countryCallingCodeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openPickerAction(_ sender: AnyObject) {
        
        let picker = ADCountryPicker { (name, code) -> () in
            print(code)
        }
        
        // delegate
        picker.delegate = self

        // Display calling codes
        picker.showCallingCodes = true

        // or closure
        picker.didSelectCountryClosure = { name, code in
            _ = picker.navigationController?.popToRootViewController(animated: true)
            print(code)
        }
        
        
//        Use this below code to present the picker
        
//        let pickerNavigationController = UINavigationController(rootViewController: picker)
//        self.present(pickerNavigationController, animated: true, completion: nil)

        
        navigationController?.pushViewController(picker, animated: true)
    }
}

extension ViewController: ADCountryPickerDelegate {
    
    func countryPicker(_ picker: ADCountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String) {
        _ = picker.navigationController?.popToRootViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
        countryNameLabel.text = name
        countryCodeLabel.text = code
        countryCallingCodeLabel.text = dialCode
    }
    
    func countryPicker(_ picker: ADCountryPicker, didSelectCountryWithName name: String, code: String) {
//        _ = picker.navigationController?.popToRootViewController(animated: true)
//        self.dismiss(animated: true, completion: nil)
//        label.text = "Selected Country: \(name) \(code) \(dialCode)"
    }
}

