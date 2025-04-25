//
//  Strings.swift
//  Events
//
//  Created by Luka Lešić on 23.03.25.
//

import Foundation

struct Strings {
    // Tab bar
    struct TabBarStrings {
        static let tabBarEvents = "Events"
        static let tabBarDaysSince = "Days Since"
        static let tabBarBirthdays = "Birthdays"
    }
    
    //Reusable Strings
    struct GeneralStrings {
        static let cancel = "Cancel"
        static let events = "Events"
        static let options = "Options"
        static let edit = "Edit"
        static let pickerDisplayMode = "Display Mode"
        static let description = "Description"

    }

    //Countdown List View
    struct EventListViewStrings {
        static let todaysEvents = "Today's Events"
        static let upcomingEvents = "Upcoming Events"
        static let pastEvents = "Past Events"
        static let deletePastEventsConfirmationTitle = "Are you sure you want to delete all past events?"
        static let deleteAllPastEventsButton = "Delete All Past Events"
        static let addNewEvent = "Add new Event"
        static let emptyListHint = "When you add a new countdown, it will appear here."
        static let noEvents = "No events"
        static let hidePastEvents = "Hide past events"
        static let showPastEvents = "Show past events"
    }
    
    // Countdown Form
    struct EventFormStrings {
        static let newTitle = "New Countdown"
        static let editTitle = "Edit Countdown"
        static let cancel = "Cancel"
        static let save = "Save"
        static let delete = "Delete Countdown"
        static let deleteConfirmTitle = "Are you sure you want to delete this event?"
        static let deleteConfirm = "Delete"
        static let basicsSection = "Basics"
        static let name = "Name"
        static let description = "Description"
        static let emoji = "Emoji"
        static let defaultEmoji = "📅"
        static let priorityColorSection = "Priority & Color"
        static let priority = "Priority"
        static let color = "Color"
        static let dateSection = "Countdown Date"
        static let selectDate = "Select date"
        static let repeatSection = "Repeat"
        static let repeatEvery = "Repeat Every"
        static let photoSection = "Photo"
        static let pickPhoto = "Pick a Photo"
    }
    
    struct EventDetailViewStrings {
        static let eventDetails = "Event Details"
        static let addDescription = "Tap to add a description."
        static let priority = "Priority:"
    }
}
