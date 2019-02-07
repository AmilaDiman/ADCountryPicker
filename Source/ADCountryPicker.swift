//
//  ADCountryPicker.swift
//  ADCountryPicker
//
//  Created by Ibrahim, Mustafa on 1/24/16.
//  Copyright © 2016 Mustafa Ibrahim. All rights reserved.
//

import UIKit

struct Section {
    var countries: [ADCountry] = []
    mutating func addCountry(_ country: ADCountry) {
        countries.append(country)
    }
}

@objc public protocol ADCountryPickerDelegate: class {
    @objc optional func countryPicker(_ picker: ADCountryPicker,
                       didSelectCountryWithName name: String,
                       code: String)
    func countryPicker(_ picker: ADCountryPicker,
                                      didSelectCountryWithName name: String,
                                      code: String,
                                      dialCode: String)
}

open class ADCountryPicker: UITableViewController {
    
    private var customCountriesCode: [String]?
    
    fileprivate lazy var CallingCodes = { () -> [[String: String]] in
        let resourceBundle = Bundle(for: ADCountryPicker.classForCoder())
        guard let path = resourceBundle.path(forResource: "CallingCodes", ofType: "plist") else { return [] }
        return NSArray(contentsOfFile: path) as! [[String: String]]
    }()
    fileprivate var searchController: UISearchController!
    fileprivate var filteredList = [ADCountry]()
    fileprivate var unsortedCountries : [ADCountry] {
        let locale = Locale.current
        var unsortedCountries = [ADCountry]()
        let countriesCodes = customCountriesCode == nil ? Locale.isoRegionCodes : customCountriesCode!
        
        for countryCode in countriesCodes {
            let displayName = (locale as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: countryCode)
            let countryData = CallingCodes.filter { $0["code"] == countryCode }
            let country: ADCountry
            
            if countryData.count > 0, let dialCode = countryData[0]["dial_code"] {
                country = ADCountry(name: displayName!, code: countryCode, dialCode: dialCode)
            } else {
                country = ADCountry(name: displayName!, code: countryCode)
            }
            unsortedCountries.append(country)
        }
        
        return unsortedCountries
    }
    
    fileprivate var _sections: [Section]?
    fileprivate var sections: [Section] {
        
        if _sections != nil {
            return _sections!
        }
        
        let countries: [ADCountry] = unsortedCountries.map { country in
            let country = ADCountry(name: country.name, code: country.code, dialCode: country.dialCode)
            country.section = collation.section(for: country, collationStringSelector: #selector(getter: ADCountry.name))
            return country
        }
        
        // create empty sections
        var sections = [Section]()
        for _ in 0..<self.collation.sectionIndexTitles.count {
            sections.append(Section())
        }
        
        
        // put each country in a section
        for country in countries {
            sections[country.section!].addCountry(country)
        }
        
        // sort each section
        for section in sections {
            var s = section
            s.countries = collation.sortedArray(from: section.countries, collationStringSelector: #selector(getter: ADCountry.name)) as! [ADCountry]
        }
        
        // Adds current location
        var countryCode = (Locale.current as NSLocale).object(forKey: .countryCode) as? String ?? self.defaultCountryCode
        if self.forceDefaultCountryCode {
            countryCode = self.defaultCountryCode
        }
        
        sections.insert(Section(), at: 0)
        let locale = Locale.current
        let displayName = (locale as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: countryCode)
        let countryData = CallingCodes.filter { $0["code"] == countryCode }
        let country: ADCountry
        
        if countryData.count > 0, let dialCode = countryData[0]["dial_code"] {
            country = ADCountry(name: displayName!, code: countryCode, dialCode: dialCode)
        } else {
            country = ADCountry(name: displayName!, code: countryCode)
        }
        country.section = 0
        sections[0].addCountry(country)
        
        
        _sections = sections
        
        return _sections!
    }
    
    fileprivate let collation = UILocalizedIndexedCollation.current()
        as UILocalizedIndexedCollation
    open weak var delegate: ADCountryPickerDelegate?
    
    /// Closure which returns country name and ISO code
    open var didSelectCountryClosure: ((String, String) -> ())?
    
    /// Closure which returns country name, ISO code, calling codes
    open var didSelectCountryWithCallingCodeClosure: ((String, String, String) -> ())?
    
    /// Flag to indicate if calling codes should be shown next to the country name. Defaults to false.
    open var showCallingCodes = false
    
    /// Flag to indicate whether country flags should be shown on the picker. Defaults to true
    open var showFlags = true
    
    /// The nav bar title to show on picker view
    open var pickerTitle = "Select a Country"
    
    /// The default current location, if region cannot be determined. Defaults to US
    open var defaultCountryCode = "US"
    
    /// Flag to indicate whether the defaultCountryCode should be used even if region can be deteremined. Defaults to false
    open var forceDefaultCountryCode = false
    
    // The text color of the alphabet scrollbar. Defaults to black
    open var alphabetScrollBarTintColor = UIColor.black
    
    /// The background color of the alphabet scrollar. Default to clear color
    open var alphabetScrollBarBackgroundColor = UIColor.clear
    
    // The tint color of the close icon in presented pickers. Defaults to black
    open var closeButtonTintColor = UIColor.black
    
    /// The font of the country name list
    open var font = UIFont(name: "Helvetica Neue", size: 15)
    
    /// The height of the flags shown. Default to 40px
    open var flagHeight = 40
    
    /// Flag to indicate if the navigation bar should be hidden when search becomes active. Defaults to true
    open var hidesNavigationBarWhenPresentingSearch = true
    
    /// The background color of the searchbar. Defaults to lightGray
    open var searchBarBackgroundColor = UIColor.lightGray
    
    convenience public init(completionHandler: @escaping ((String, String) -> ())) {
        self.init()
        self.didSelectCountryClosure = completionHandler
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = pickerTitle
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        createSearchBar()
        tableView.reloadData()
        
        definesPresentationContext = true
        
        if self.presentingViewController != nil {
            
            let bundle = "assets.bundle/"
            let closeButton = UIBarButtonItem(image: UIImage(named: bundle + "close_icon" + ".png",
                                                             in: Bundle(for: ADCountryPicker.self),
                                                             compatibleWith: nil),
                                              style: .plain,
                                              target: self,
                                              action: #selector(self.dismissView))
            closeButton.tintColor = closeButtonTintColor
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.leftBarButtonItem = closeButton
        }
        
        tableView.sectionIndexColor = alphabetScrollBarTintColor
        tableView.sectionIndexBackgroundColor = alphabetScrollBarBackgroundColor
        tableView.separatorColor = UIColor(red: (222)/(255.0),
                                           green: (222)/(255.0),
                                           blue: (222)/(255.0),
                                           alpha: 1)
    }
    
    // MARK: Methods
    
    @objc private func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func createSearchBar() {
        if self.tableView.tableHeaderView == nil {
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = self.hidesNavigationBarWhenPresentingSearch
            searchController.searchBar.searchBarStyle = .prominent
            searchController.searchBar.barTintColor = self.searchBarBackgroundColor
            searchController.searchBar.showsCancelButton = false
            tableView.tableHeaderView = searchController.searchBar
        }
    }
    
    fileprivate func filter(_ searchText: String) -> [ADCountry] {
        filteredList.removeAll()
        
        sections.forEach { (section) -> () in
            section.countries.forEach({ (country) -> () in
                if country.name.count >= searchText.count {
                    let result = country.name.compare(searchText, options: [.caseInsensitive, .diacriticInsensitive],
                                                      range: searchText.startIndex ..< searchText.endIndex)
                    if result == .orderedSame {
                        filteredList.append(country)
                    }
                }
            })
        }
        
        return filteredList
    }
    
    fileprivate func getCountry(_ code: String) -> [ADCountry] {
        filteredList.removeAll()
        
        sections.forEach { (section) -> () in
            section.countries.forEach({ (country) -> () in
                if country.code.count >= code.count {
                    let result = country.code.compare(code, options: [.caseInsensitive, .diacriticInsensitive],
                                                      range: code.startIndex ..< code.endIndex)
                    if result == .orderedSame {
                        filteredList.append(country)
                    }
                }
            })
        }
        
        return filteredList
    }
    
    
    // MARK: - Public method
    
    /// Returns the country flag for the given country code
    ///
    /// - Parameter countryCode: ISO code of country to get flag for
    /// - Returns: the UIImage for given country code if it exists
    public func getFlag(countryCode: String) -> UIImage? {
        let countries = self.getCountry(countryCode)
        
        if countries.count == 1 {
            let bundle = "assets.bundle/"
            return UIImage(named: bundle + countries.first!.code.uppercased() + ".png",
                           in: Bundle(for: ADCountryPicker.self), compatibleWith: nil)
        }
        else {
            return nil
        }
    }
    
    /// Returns the country dial code for the given country code
    ///
    /// - Parameter countryCode: ISO code of country to get dialing code for
    /// - Returns: the dial code for given country code if it exists
    public func getDialCode(countryCode: String) -> String? {
        let countries = self.getCountry(countryCode)
        
        if countries.count == 1 {
            return countries.first?.dialCode
        }
        else {
            return nil
        }
    }
    
    /// Returns the country name for the given country code
    ///
    /// - Parameter countryCode: ISO code of country to get dialing code for
    /// - Returns: the country name for given country code if it exists
    public func getCountryName(countryCode: String) -> String? {
        let countries = self.getCountry(countryCode)
        
        if countries.count == 1 {
            return countries.first?.name
        }
        else {
            return nil
        }
    }
}

// MARK: - Table view data source

extension ADCountryPicker {
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.searchBar.text!.count > 0 {
            return 1
        }
        return sections.count
    }
    
    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if CGFloat(self.flagHeight) < CGFloat(tableView.rowHeight) {
            return CGFloat(max(self.flagHeight, 25))
        }
        
        return max(tableView.rowHeight, CGFloat(self.flagHeight))
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.searchBar.text!.count > 0 {
            return filteredList.count
        }
        return sections[section].countries.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var tempCell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        
        if tempCell == nil {
            tempCell = UITableViewCell(style: .default, reuseIdentifier: "UITableViewCell")
        }
        
        let cell: UITableViewCell! = tempCell
        
        let country: ADCountry!
        if searchController.searchBar.text!.count > 0 {
            country = filteredList[(indexPath as NSIndexPath).row]
        } else {
            country = sections[(indexPath as NSIndexPath).section].countries[(indexPath as NSIndexPath).row]
            
        }
        
        cell.textLabel?.font = self.font
        
        if showCallingCodes {
            cell.textLabel?.text = country.name + " (" + country.dialCode! + ")"
        } else {
            cell.textLabel?.text = country.name
        }
        
        let bundle = "assets.bundle/"
        
        if self.showFlags == true {
            let image = UIImage(named: bundle + country.code.uppercased() + ".png", in: Bundle(for: ADCountryPicker.self), compatibleWith: nil)
            if (image != nil) {
                cell.imageView?.image = image?.fitImage(size: CGSize(width:self.flagHeight, height:flagHeight))
            }
            else {
                cell.imageView?.image = UIImage.init(color: .lightGray,
                                                     size: CGSize(width:CGFloat(flagHeight), height:CGFloat(flagHeight)/CGFloat(1.5)))?.fitImage(size: CGSize(width:CGFloat(self.flagHeight), height:CGFloat(flagHeight)/CGFloat(1.5)))
            }
        }
        
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !sections[section].countries.isEmpty {
            if searchController.searchBar.text!.count > 0 {
                if let name = filteredList.first?.name {
                    let index = name.index(name.startIndex, offsetBy: 0)
                    return String(describing: name[index])
                }
                
                return ""
            }
            
            if section == 0 {
                return "Current Location"
            }
            
            return self.collation.sectionTitles[section-1] as String
            
            
        }
        
        return ""
    }
    
    override open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 50
        }
        else {
            return 26
        }
    }
    
    override open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return collation.sectionIndexTitles
    }
    
    override open func tableView(_ tableView: UITableView,
                                 sectionForSectionIndexTitle title: String,
                                 at index: Int)
        -> Int {
            return collation.section(forSectionIndexTitle: index+1)
    }
}

// MARK: - Table view delegate

extension ADCountryPicker {
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country: ADCountry!
        if searchController.searchBar.text!.count > 0 {
            country = filteredList[(indexPath as NSIndexPath).row]
        } else {
            country = sections[(indexPath as NSIndexPath).section].countries[(indexPath as NSIndexPath).row]
        }
        delegate?.countryPicker?(self, didSelectCountryWithName: country.name, code: country.code)
        delegate?.countryPicker(self, didSelectCountryWithName: country.name, code: country.code, dialCode: country.dialCode)
        didSelectCountryClosure?(country.name, country.code)
        didSelectCountryWithCallingCodeClosure?(country.name, country.code, country.dialCode)
    }
}

// MARK: - UISearchDisplayDelegate

extension ADCountryPicker: UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {
        _ = filter(searchController.searchBar.text!)
        
        if self.hidesNavigationBarWhenPresentingSearch == false {
            searchController.searchBar.showsCancelButton = false
        }
        tableView.reloadData()
    }
}

// MARK: - UIImage extensions

extension UIImage {
    func fitImage(size: CGSize) -> UIImage? {
        let widthRatio = size.width / self.size.width
        let heightRatio = size.height / self.size.height
        let ratio = min(widthRatio, heightRatio)
        
        let imageWidth = self.size.width * ratio
        let imageHeight = self.size.height * ratio
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width:imageWidth, height:imageHeight), false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
