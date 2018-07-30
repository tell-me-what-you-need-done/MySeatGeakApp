# MySeatGeakApp
This is an example iOS application written in Swift. The application is quite simple and yet it demostrates a number of iOS API's and techniques.

The basic code flow goes like this...

1) Initialize the main table view controller. The user is presented with an empty view and a search bar in the header space at the top of the view controller.

2) The user taps the Search bar and the soft keyboard appears allowing the user to enter text.

3) As the user enters text, the search controller is building the search string and issuing a REST call to SeatGeek.com. SeatGeek.com is a website for searching for upcoming events, like concerts, sporting event, band, etc. It includes details about the venue where the event will be held along with details about the performers, etc.

4) SeatGeek.com will respond with JSON objects that are then parsed by the view controller. The parsing creates a list of the events, venues, and performers based on the search string.

5) Once the processing is complete, the user is presented with the results of the search against the SeatGeek REST API.

6) The user can scroll through the list of events or tap a row to get more details about the event.

7) Once the user locates an event of interest, the user can swipe left on the row to mark the event as a favorite or the user can tap the row and display the details about the event and tap the star in the upper right corner to mark it as a favorite.
