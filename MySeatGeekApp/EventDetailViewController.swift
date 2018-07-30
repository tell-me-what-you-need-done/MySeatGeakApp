//
//  EventDetailViewController.swift
//  MySeatGeekApp
//
//  Created by Scott Bennett on 7/27/18.
//

import UIKit
import Kingfisher

class EventDetailViewController: UIViewController {

    //Where we store an event ID when the user marks one as a favorite
    let defaults = UserDefaults.standard

    @IBOutlet var LocationImage: UIImageView!
    @IBOutlet var EventDate: UILabel!
    @IBOutlet var EventLocation: UILabel!
    
    var locationImage: URL! //The URL for a picture of where the event will take place
    var eventDate: Date! //When the event will happen
    var eventLocation: String! //Where the event will happen
    var eventID: String! //The unique identifier for this event
    var favorite: Bool! //Did the user mark this event as a favorite or not
    
    let favoriteButton = UIButton(type: .custom)
    
    //Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //Notifies the view controller that its view is about to be added to a view hierarchy.
    override func viewWillAppear(_ animated: Bool) {
        LocationImage.kf.setImage(with: locationImage, placeholder: #imageLiteral(resourceName: "placeholder") , options: nil)
        
        let formatter = DateFormatter()
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.dateFormat = "EEE, d MMM yyyy h:mm a"
        EventDate.text = formatter.string(from: eventDate!)

        EventLocation.text = eventLocation
        
        setFavoriteImage()
    }

    //This method is called when the system determines that the amount of available memory is low.
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Set the favorite image or not depending on if the event is marked as a favorite or not
    func setFavoriteImage() {
        if favorite == true {
            favoriteButton.setImage(UIImage(named: "GoldStar"), for: .normal)
        }
        else {
            favoriteButton.setImage(UIImage(named: "EmptyStar"), for: .normal)
        }

        favoriteButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        favoriteButton.addTarget(self, action: #selector(toggleMarkFav), for: .touchUpInside)
        let item1 = UIBarButtonItem(customView: favoriteButton)
        self.navigationItem.setRightBarButtonItems([item1], animated: true)
    }
    
    //When the user taps the favorite button, toggle the image accordingly and set or remove the KV.
    @objc func toggleMarkFav() {
        if favorite == true {
            favorite = false
            favoriteButton.setImage(UIImage(named: "EmptyStar"), for: .normal)
            self.defaults.removeObject(forKey: eventID!)
        }
        else {
            favorite = true
            favoriteButton.setImage(UIImage(named: "GoldStar"), for: .normal)
            self.defaults.set(true, forKey: eventID!)
        }
        
        //Save the user defaults
        self.defaults.synchronize()
    }

}
