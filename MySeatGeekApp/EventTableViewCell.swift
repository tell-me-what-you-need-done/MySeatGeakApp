//
//  EventTableViewCell:.swift
//  MySeatGeekApp
//
//  Created by Scott Bennett on 7/27/18.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    @IBOutlet var locationImage: UIImageView! //The URL for a picture of where the event will take place
    @IBOutlet var eventTitle: UILabel! //The title or name of the event
    @IBOutlet var eventDate: UILabel! //When the event will happen
    @IBOutlet var eventLocation: UILabel! //Where the event will happen
    @IBOutlet var favorite: UIImageView! //Did the user mark this event as a favorite or not
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
