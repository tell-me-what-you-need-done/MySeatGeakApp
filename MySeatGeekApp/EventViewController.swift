//
//  EventViewController.swift
//  MySeatGeekApp
//
//  Created by Scott Bennett on 7/27/18.
//

import UIKit
import Kingfisher

class EventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    //Where we store an event ID when the user marks one as a favorite
    let defaults = UserDefaults.standard
    
    //Our table view
    @IBOutlet var tableView: UITableView!
    
    //Our search controller that is placed in the table view header
    var searchController: UISearchController!
    
    //As the user enters characters in the search bar, this is used to store them
    var searchString: String!

    //Used to detect keystrokes in the search bar so we don't flood the server with requests
    lazy var timer = TheSearchTimer { [weak self] in self?.performSearch() }

    //Our event segue identifier
    let eventSegueIdentifier = "ShowEventDetailsSegue"
    
    //Our event details view
    let eventTableViewCellIdentifier = "EventTableViewCell"

    //The following structs are the pieces of data the seat geek json returns by a query API
    struct SeatGeekData: Codable {
        let events: [Event]
    }
    
    struct Event: Codable {
        let type: String? //event type... mlb, concert, show, etc
        let id: Int? //unique identifier for the event
        let datetime_local: Date? //the date and time of the event
        let title: String? //the title of the event
        let venue: Venue? //a collection of properties that describe the venue where the event takes place
        let performers: [Performers] //a collection of the band, team, group, etc that participate in the event
    }
    
    struct Venue: Codable {
        let display_location: String? //the arena, stadium, field, etc of where the event will take place
    }
    
    struct Performers: Codable {
        let image: URL? //image of the performer, field, band, group, team, etc
        let home_team: Bool? //this applies to team events, for example we want to show the field for the home team not the visitor
    }
    
    var seatGeekData: SeatGeekData?
    
    // MARK: - Date/Time formatters
    
    //Various date and time formatters to help format the different types returned by seat geek
    lazy var dateTimeZFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

    lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter.init()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - JSON Decoder
    
    //An object that decodes instances of a data type from JSON objects.
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = self.dateTimeZFormatter.date(from: dateString) {
                return date
            }
            
            if let date = self.dateTimeFormatter.date(from: dateString) {
                return date
            }

            if let date = self.dateFormatter.date(from: dateString) {
                return date
            }
            
            return Date()
        }

        return decoder
    }()

    // MARK: - View controller delegates
    
    //Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        configureSearchController()

        definesPresentationContext = true;
    }
    
    //Notifies the view controller that its view is about to be added to a view hierarchy.
    override func viewWillAppear(_ animated: Bool) {
        let selectedRowIndexPath = self.tableView.indexPathForSelectedRow //get the selected row first
        super.viewWillAppear(animated) //clears selection
        if (selectedRowIndexPath != nil) {
            //refresh the cell in case the favorite mark was changed
            self.tableView.reloadRows(at: [selectedRowIndexPath!], with: UITableViewRowAnimation.none)
        }
    }
    
    //This method is called when the system determines that the amount of available memory is low.
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UITextFieldDelegate Methods

    //Tells the data source to return the number of sections in a given table view.
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    //Tells the data source to return the number of rows in a given section of a table view.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let events = self.seatGeekData else {
            return 0
        }

        return events.events.count
    }
    
    //Asks the data source for a cell to insert in a particular location of the table view.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:EventTableViewCell = tableView.dequeueReusableCell(withIdentifier: eventTableViewCellIdentifier) as! EventTableViewCell
        
        let row = indexPath.row
        
        //Has this row a favorite, if so, show the favorite image
        if isFavorite(id: (seatGeekData?.events[row].id)!) {
            let image = UIImage(named: "GoldStar")
            cell.favorite.image = image
        }
        else {
            cell.favorite.image = nil
        }

        let locationImage = getLocationImage(row)
        
        if locationImage == nil {
            let image = UIImage(named: "placeholder")!
            cell.locationImage.image = image
        }
        else {
            cell.locationImage.kf.setImage(with: locationImage)
        }

        cell.eventTitle.text = seatGeekData?.events[row].title
        
        cell.eventLocation.text = seatGeekData?.events[row].venue?.display_location
        
        let formatter = DateFormatter()
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.dateFormat = "EEE, d MMM yyyy h:mm a"
        let dateString = formatter.string(from: (seatGeekData?.events[row].datetime_local)!)
        cell.eventDate.text = dateString
        
        return cell
    }
    
    // MARK: - UITableViewDelegate Methods

    //Add a swipe action to the cell so the user can mark or unmark a favorite
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let cell = tableView.cellForRow(at: indexPath) as! EventTableViewCell
        // Write action code for the mark/unmark favorite
        let MarkAsFavorite =
            UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                let id = self.seatGeekData?.events[indexPath.row].id?.toString()
                if self.isFavorite(id: (self.seatGeekData?.events[indexPath.row].id)!) {
                    cell.favorite.image = nil
                    self.defaults.removeObject(forKey: id!)
                }
                else {
                    let image = UIImage(named: "GoldStar")
                    cell.favorite.image = image
                    self.defaults.set(true, forKey: id!)
                }
                
                //Save the user defaults
                self.defaults.synchronize()
                
                success(true)
        })

        MarkAsFavorite.backgroundColor = .blue
        
        //TODO: Find a better way to set the swipe action title text
        if self.isFavorite(id: (self.seatGeekData?.events[indexPath.row].id)!) {
            MarkAsFavorite.title = NSLocalizedString("Unmark favorite", comment: "Unmark favorite")
        }
        else {
            MarkAsFavorite.title = NSLocalizedString("Mark favorite", comment: "Mark favorite")
        }

        return UISwipeActionsConfiguration(actions: [MarkAsFavorite])
    }
    
    // MARK: - Navigation

    //Notifies the view controller that a segue is about to be performed.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == eventSegueIdentifier,
            let destination = segue.destination as? EventDetailViewController,
            let row = tableView.indexPathForSelectedRow?.row
        {
            //Remove the word 'Back' from the navigation bar, leaving only the less than symbol
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            
            //Setup the variables in the event details VC
            destination.eventID = (seatGeekData?.events[row].id?.toString())!
            destination.favorite = isFavorite(id: (seatGeekData?.events[row].id)!)
            destination.navigationItem.title = (seatGeekData?.events[row].title)!
            destination.locationImage = getLocationImage(row)
            destination.eventDate = seatGeekData?.events[row].datetime_local
            destination.eventLocation = seatGeekData?.events[row].venue?.display_location
            
            searchController.searchBar.resignFirstResponder()
        }
    }
    
    //MARK: - Search update delegate
    
    //Called when the search bar becomes the first responder or when the user makes changes inside the search bar.
    func updateSearchResults(for searchController: UISearchController){
        searchString = searchController.searchBar.text
        tableView.reloadData()
    }
    
    //MARK: - Search bar delegate and timer
    
    //Tells the delegate when the user begins editing the search text.
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        tableView.reloadData()
    }
    
    //Tells the delegate that the cancel button was tapped.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        seatGeekData = nil
        tableView.reloadData()
    }
    
    //Tells the delegate that the user changed the search text.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        timer.activate()
    }
    
    //Tells the delegate that the search button was tapped.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
    
    //Take the search string and call the server and retrieve the results and uses a timer to not hammer
    //the server with each keystroke
    func performSearch() {
        timer.cancel()
        let encodedSearchString = searchString?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        getSeatGeekData(encodedSearchString!)
    }

    //MARK: - Misc support routines
    
    //Takes in a string and appends to the server query then processes the JSON results
    func getSeatGeekData(_ searchString: String) {
        let url = URL(string: "https://api.seatgeek.com/2/events?client_id=MTIxNTA2NjV8MTUzMDcwMDkxNy4xOQ&q=" + searchString)
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            guard let data = data else {
                print("Error: \(String(describing: error))")
                return
            }
            
            let seatGeekData = try! self.decoder.decode(SeatGeekData.self, from: data)
            self.seatGeekData = seatGeekData

            OperationQueue.main.addOperation({
                self.tableView.reloadData()
            })
        }
        
        task.resume()
    }

    //Set up some initial search controller properties
    func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("Search here...", comment: "Search here...")
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.hidesNavigationBarDuringPresentation = false

        tableView.tableHeaderView = searchController.searchBar
    }
    
    //When the seatgeek json is processed, some events have only one performer, however in some cases there are at least
    //two performers, such as two team sports like baseball or football, etc. In these cases the home_home is set which means
    //we need the location url for the home team to display in the cell/details view. Kind of strange IMO, but that's how the data
    //comes back.
    //TODO: Investigate json and how the performers and event types differ for better location image determination.
    func getLocationImage(_ row: Int) -> URL? {
        var locationImage: URL!
        let performers = seatGeekData?.events[row].performers
        if seatGeekData?.events[row].type == "mlb" || seatGeekData?.events[row].type == "minor_league_baseball"{
            for (value) in performers! {
                let home_team = value.home_team
                locationImage = value.image
                
                if home_team == true {
                    break
                }
            }
        }
        else {
            locationImage = performers![0].image ?? nil
        }
        
        return locationImage
    }
    
    //Takes the id and checks user defaults to see if it's set or not
    func isFavorite(id: Int) -> Bool {
        if defaults.bool(forKey: id.toString()) {
            return true
        }
        else {
            return false
        }
    }

}

//Just a little helper to get the string representation of an integer
extension Int
{
    func toString() -> String
    {
        let myString = String(self)
        return myString
    }
}
