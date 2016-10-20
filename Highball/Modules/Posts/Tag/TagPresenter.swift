//
//  TagPresenter.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 9/2/16.
//  Copyright © 2016 ianynda. All rights reserved.
//

import Foundation
import TMTumblrSDK

open class TagPresenter: PostsPresenter {
	open weak var view: PostsView?
	open var dataManager: PostsDataManager?
	open var loadingCompletion: (() -> ())?

	fileprivate let tag: String

	public init(tag: String) {
		self.tag = tag.substring(from: tag.characters.index(tag.startIndex, offsetBy: 1))
	}

	public func dataManager(_ dataManager: PostsDataManager, requestPostsWithCount postCount: Int, parameters: [String : AnyObject], callback: @escaping TMAPICallback) {
		var mutableParameters = parameters
		if let lastPost = dataManager.posts?.last {
			mutableParameters["before"] = "\(lastPost.timestamp)" as AnyObject?
		}
		TMAPIClient.sharedInstance().tagged(tag, parameters: mutableParameters, callback: callback)
	}

	public func dataManagerPostsJSONKey(_ dataManager: PostsDataManager) -> String? {
		return nil
	}
}
