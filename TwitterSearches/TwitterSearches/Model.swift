//  Model.swift
//  TwitterSearches
import Foundation

// delegate protocol
// notify controller when data changes
protocol ModelDelegate {
    func modelDataChanged()
}

// manages the saved searches
class Model {
    // keys for NSUserDefaults
    private let pairsKey = "TwitterSearchesKVPairs"
    private let tagsKey = "TwitterSearchesKeyOrder"
    
    private var searches: [String: String] = [:] // stores tag query pairs
    private var tags: [String] = [] // stores tags in user-specified order
    
    private let delegate: ModelDelegate
    
    // initializes the model
    init(delegate: ModelDelegate) {
        self.delegate = delegate
        
        // get NSUserDefault object
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        // get dictionary of app's tag-query pairs
        if let pairs = userDefaults.dictionaryForKey(pairsKey) {
            self.searches = pairs as [String : String]
        }
        
        // get array with app's tag order
        if let tags = userDefaults.arrayForKey(tagsKey) {
            self.tags = tags as [String]
        }
        
        // register to iCloud change notifications
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "updateSearches:",
            name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.defaultStore())
    }
    
    // called by viewcontroller to synchronize model after it's created
    func synchronize() {
        NSUbiquitousKeyValueStore.defaultStore().synchronize()
    }
}