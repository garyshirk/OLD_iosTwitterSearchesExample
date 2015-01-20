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
    
    // return the tag at a specified index
    func tagAtIndex(index: Int) -> String {
        return tags[index]
    }
    
    // return query for a given tag
    func queryForTag(tag: String) -> String? {
        return searches[tag]
    }
    
    // return the query String for the tag at an index
    func queryForTagAtIndex(index: Int) -> String? {
        return searches[tags[index]]
    }
    
    // number of tags
    var count: Int {
        return tags.count
    }
    
    // delete tag from tags array and tag-query dictionary,
    // from user defaults and iCloud key-value pairs
    func deleteSearchAtIndex(index: Int) {
        searches.removeValueForKey(tags[index])
        let removeTag = tags.removeAtIndex(index)
        updateUserDefaults(updateTags: true, updateSearches: true)
        
        // remove search from iCloud
        let keyValueStore = NSUbiquitousKeyValueStore.defaultStore()
        keyValueStore.removeObjectForKey(removeTag);
    }
    
    // reorder tags array
    func moveTagAtIndex(oldIndex: Int, toDestinationIndex newIndex: Int) {
        let temp = tags.removeAtIndex(oldIndex)
        tags.insert(temp, atIndex:newIndex);
        updateUserDefaults(updateTags: true, updateSearches: false)
    }
    
    // update local and iCloud user defaults
    func updateUserDefaults(# updateTags: Bool, updateSearches: Bool) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if updateTags {
            userDefaults.setObject(tags, forKey: tagsKey)
        }
        
        if updateSearches {
            userDefaults.setObject(searches, forKey: pairsKey)
        }
        
        userDefaults.synchronize()
    }
    
    // update searches when iCloud changes occur
    @objc func updateSearches(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            // check reason for change
            if let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as NSNumber? {
                
                // if changes occurred on another device
                if reason.integerValue == NSUbiquitousKeyValueStoreServerChange ||
                    reason.integerValue == NSUbiquitousKeyValueStoreInitialSyncChange {
                        performUpdates(userInfo)
                }
            }
        }
    }
    
    func performUpdates(userInfo: [NSObject : AnyObject?]) {
        // get changed keys NSArray; conver to [String]
        let changedKeysObject = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey]
        let changedKeys = changedKeysObject as [String]
        
        // get NSUbiquitousKeyValueStore for updating
        let keyValueStore = NSUbiquitousKeyValueStore.defaultStore()
        
        // update searches based on iCloud changes
        for key in changedKeys {
            if let query = keyValueStore.stringForKey(key) {
                saveQuery(query, forTag: key, syncToCloud: false)
            } else {
                searches.removeValueForKey(key)
                tags = tags.filter{$0 != key}
                updateUserDefaults(updateTags: true, updateSearches: true);
            }
            
            delegate.modelDataChanged()
        }
    }
    
    // save a tag-query pair
    func saveQuery(query: String, forTag tag: String, syncToCloud sync: Bool) {
        
        // dictionary method updateValue returns nil if key is new
        let oldValue = searches.updateValue(query, forKey: tag)
        
        if oldValue == nil {
            tags.insert(tag, atIndex: 0)
            updateUserDefaults(updateTags: true, updateSearches: true)
        } else {
            updateUserDefaults(updateTags: false, updateSearches: true)
        }
        
        // if sync is true, add tag-query pair to iCloud
        if sync {
            NSUbiquitousKeyValueStore.defaultStore().setObject(query, forKey: tag)
        }
    }
}
