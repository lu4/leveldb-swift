/*
* Copyright © 2014, codesplice pty ltd (sam@codesplice.com.au)
*
* Licensed under the terms of the ISC License http://opensource.org/licenses/ISC
*/

import Foundation

public struct KeySequence<Key: KeyType> : Sequence {
    public typealias Iterator = AnyIterator<Key>
    let db : Database
    let startKey : Key?
    let endKey : Key?
    let descending : Bool
    
    init(db : Database, startKey : Key? = nil, endKey : Key? = nil, descending : Bool = false) {
        self.db = db
        self.startKey = startKey
        self.endKey = endKey
        self.descending = descending
    }
    
    public func makeIterator() -> Iterator {
        let iterator = db.newIterator()
        if let key = startKey {
            key.withSlice { k in
                iterator.seek(k)
                if descending && iterator.isValid && db.compare(k, iterator.key!) == .orderedAscending {
                    iterator.prev()
                }
            }
        } else if descending {
            iterator.seekToLast()
        } else {
            iterator.seekToFirst()
        }
        return AnyIterator({
            if !iterator.isValid {
                return nil
            }
            let currentSlice = iterator.key!
            let currentKey = Key(bytes: currentSlice.bytes, count: currentSlice.length)
            if let key = self.endKey {
                var result = ComparisonResult.orderedSame
                key.withSlice { k in
                    result = self.db.compare(currentSlice, k)
                }
                if !self.descending && result == .orderedDescending
                    || self.descending && result == .orderedAscending {
                        return nil
                }
            }
            if self.descending { iterator.prev() } else { iterator.next() }
            return currentKey
        })
    }
}
