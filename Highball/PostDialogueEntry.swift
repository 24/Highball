//
//  PostDialogueEntry.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 8/31/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import Foundation

class PostDialogueEntry {

    var json: JSONValue!

    required init(json: JSONValue!) {
        self.json = json
    }

    func formattedString() -> (NSAttributedString) {
        let label = self.json["label"].string!
        let phrase = self.json["phrase"].string!
        let labelAttributes = [ NSFontAttributeName : UIFont(name: "Courier-Bold", size: 14) ]
        let phraseAttributes = [ NSFontAttributeName : UIFont(name: "Courier", size: 14) ]
        let attributedString = NSMutableAttributedString(string: "\(label) \(phrase)")

        attributedString.setAttributes(labelAttributes, range: NSMakeRange(0, countElements(label)))
        attributedString.setAttributes(phraseAttributes, range: NSMakeRange(countElements(label), countElements(phrase) + 1))

        return attributedString
    }

}
