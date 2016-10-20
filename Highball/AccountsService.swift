//
//  AccountsService.swift
//  Highball
//
//  Created by Ian Ynda-Hummel on 12/16/14.
//  Copyright (c) 2014 ianynda. All rights reserved.
//

import OAuthSwift
import RealmSwift
import SwiftyJSON
import TMTumblrSDK
import UIKit

import Cartography

internal class TestVC: OAuthWebViewController, UIWebViewDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()

		let webView = UIWebView()
		view.addSubview(webView)

		constrain(webView, view) { webView, view in
			webView.edges == view.edges
		}
	}

	override func doHandle(_ url: URL) {
		(view.subviews.first! as! UIWebView).loadRequest(URLRequest(url: url))
		super.doHandle(url)
	}
}

public struct AccountsService {
	fileprivate static let lastAccountNameKey = "HILastAccountKey"

	public fileprivate(set) static var account: Account!

	public static func accounts() -> [Account] {
		guard let realm = try? Realm() else {
			return []
		}

		return realm.objects(AccountObject.self).map { $0 }
	}

	public static func lastAccount() -> Account? {
		let userDefaults = UserDefaults.standard

		guard let accountName = userDefaults.string(forKey: lastAccountNameKey) else {
			return nil
		}

		guard let realm = try? Realm() else {
			return nil
		}

		guard let account = realm.object(ofType: AccountObject.self, forPrimaryKey: accountName as AnyObject) else {
			return nil
		}

		return account
	}

	public static func start(fromViewController viewController: UIViewController, completion: @escaping (Account) -> ()) {
		if let lastAccount = lastAccount() {
			loginToAccount(lastAccount, completion: completion)
			return
		}

		guard let firstAccount = accounts().first else {
			authenticateNewAccount(fromViewController: viewController) { account in
				if let account = account {
					self.loginToAccount(account, completion: completion)
				} else {
					self.start(fromViewController: viewController, completion: completion)
				}
			}
			return
		}

		loginToAccount(firstAccount, completion: completion)
	}

	public static func loginToAccount(_ account: Account, completion: @escaping (Account) -> ()) {
		self.account = account

		TMAPIClient.sharedInstance().oAuthToken = account.token
		TMAPIClient.sharedInstance().oAuthTokenSecret = account.tokenSecret

		DispatchQueue.main.async {
			completion(account)
		}
	}

	public static func authenticateNewAccount(fromViewController viewController: UIViewController, completion: @escaping (_ account: Account?) -> ()) {
		let oauth = OAuth1Swift(
			consumerKey: TMAPIClient.sharedInstance().oAuthConsumerKey,
			consumerSecret: TMAPIClient.sharedInstance().oAuthConsumerSecret,
			requestTokenUrl: "https://www.tumblr.com/oauth/request_token",
			authorizeUrl: "https://www.tumblr.com/oauth/authorize",
			accessTokenUrl: "https://www.tumblr.com/oauth/access_token"
		)
		let currentAccount: Account? = account

		account = nil

		TMAPIClient.sharedInstance().oAuthToken = nil
		TMAPIClient.sharedInstance().oAuthTokenSecret = nil

		oauth.authorizeURLHandler = TestVC()// SafariURLHandler(viewController: viewController)

		oauth.authorizeWithCallbackURL(
			URL(string: "highball://oauth-callback")!,
			success: { (credential, response, parameters) in
				TMAPIClient.sharedInstance().OAuthToken = credential.oauth_token
				TMAPIClient.sharedInstance().OAuthTokenSecret = credential.oauth_token_secret

				TMAPIClient.sharedInstance().userInfo { response, error in
					var account: Account?

					defer {
						completion(account: account)
					}

					if let error = error {
						print(error)
						return
					}

					let json = JSON(response)

					guard let blogsJSON = json["user"]["blogs"].array else {
						return
					}

					let blogs = blogsJSON.map { blogJSON -> UserBlogObject in
						let blog = UserBlogObject()
						blog.name = blogJSON["name"].stringValue
						blog.url = blogJSON["url"].stringValue
						blog.title = blogJSON["title"].stringValue
						blog.isPrimary = blogJSON["primary"].boolValue
						return blog
					}

					let accountObject = AccountObject()
					accountObject.name = json["user"]["name"].stringValue
					accountObject.token = TMAPIClient.sharedInstance().OAuthToken
					accountObject.tokenSecret = TMAPIClient.sharedInstance().OAuthTokenSecret
					accountObject.blogObjects.appendContentsOf(blogs)

					guard let realm = try? Realm() else {
						return
					}

					do {
						try realm.write {
							realm.add(accountObject, update: true)
						}
					} catch {
						print(error)
						return
					}

					account = accountObject

					self.account = currentAccount

					TMAPIClient.sharedInstance().OAuthToken = currentAccount?.token
					TMAPIClient.sharedInstance().OAuthTokenSecret = currentAccount?.tokenSecret
				}
			},
			failure: { (error) in
				print(error)
			}
		)
	}

	public static func deleteAccount(_ account: Account, fromViewController viewController: UIViewController, completion: @escaping (_ changedAccount: Bool) -> ()) {
		guard let realm = try? Realm(), let accountObject = account as? AccountObject else {
			return
		}

		let accountNeedsToChange = self.account == account

		do {
			try realm.write {
				realm.delete(accountObject)
			}
		} catch {
			DispatchQueue.main.async {
				completion(false)
			}
		}

		if accountNeedsToChange {
			self.account = nil

			start(fromViewController: viewController) { _ in
				completion(true)
			}
		}

		DispatchQueue.main.async {
			completion(false)
		}
	}
}
