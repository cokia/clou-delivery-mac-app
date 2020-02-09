//
//  PopoverViewController.swift
//  Quotes
//
//  Created by Joao Costa on 09/04/16.
//  Copyright © 2016 Joao Costa. All rights reserved.
//

import Cocoa

class PopoverViewController: NSViewController, NSPopoverDelegate {
	
	@IBOutlet weak var quoteTextField: NSTextField!
	@IBOutlet weak var authorTextField: NSTextField!
	@IBOutlet weak var playButton: NSButton!
	@IBOutlet weak var previousButton: NSButton!
	
	let url: NSURL?	=
		NSURL(string: "http://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=json")
	let playIcon: NSImage = NSImage(named: "PlayIcon")!
	let stopIcon: NSImage = NSImage(named: "StopIcon")!
	
	var quotes: [String]	= [String]()
	var authors: [String]	= [String]()
	var quoteIndex: Int		= 0
	var quote: String	= "Hello World" {
		didSet { quoteTextField.stringValue	= quote }
	}
	var author: String = "You" {
		didSet { authorTextField.stringValue = author }
	}
	var connected: Bool {
		get { return Reachability.isConnectedToNetwork() }
	}
    var task: Process = Process()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Change play button icon and tell OSX to invert it in dark mode.
        playIcon.isTemplate	= true
        stopIcon.isTemplate	= true
		playButton.image	= playIcon
	}
	
	override func viewWillLayout() {
		super.viewWillLayout()
		
		// Fetch new quote to present before the view is loaded.
        nextQuote(sender: self)
		
		// Hide the previous button.
        previousButton.isHidden	= true
	}
	
	// Quit Application.
	@IBAction func quitApp(sender: AnyObject?) {
		// Stop say task if it is currently running.
        if task.isRunning { task.interrupt() }
        NSApplication.shared.terminate(sender)
	}
	
	// Get a new quote and update the popover.
	@IBAction func nextQuote(sender: AnyObject?) {
        previousButton.isHidden	= false
		quoteIndex	+= 1
		
		if quoteIndex < quotes.count {
			quote				= quotes[quoteIndex]
			author			= authors[quoteIndex]
		} else {
			if let url = url {
				// Create a new data task to make a request to the API.
                let session = URLSession.shared
				session.dataTaskWithURL(url) {
                    [unowned self] (data: NSData?, response: URLResponse?, error: NSError?) -> Void in
                    if let data = data, let JSONString = NSString(data: data, encoding: NSUTF8StringEncoding) {
						// Remove '\' from the quoteText field to prevent JSON Serialization from failing.
						let fixedString	=
							JSONString.stringByReplacingOccurrencesOfString("\\", withString: "") as NSString
						let fixedData		= fixedString.dataUsingEncoding(NSUTF8StringEncoding)
						
						do {
							// Try to convert data to JSON and extract the author and the quote.
							let json = try NSJSONSerialization.JSONObjectWithData(fixedData!,
							                                                      options: NSJSONReadingOptions())
							
							// Get the quote text from the JSON, trimming it.
							if let jsonQuote = json["quoteText"] as? String {
								self.quote = jsonQuote
									.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
									.stringByReplacingOccurrencesOfString("\\", withString: "")
								self.quote = "\"\(self.quote)\""
							} else { self.quote = "\"Something went wrong :/\"" }
							
							// Get the quote author from the JSON, trimming it.
							if let jsonAuthor = json["quoteAuthor"] as? String {
								self.author = jsonAuthor
  							.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
								
								if self.author == "" { self.author = "Unknown" }
							}
							
							// Save the new quote.
							self.quotes.append(self.quote)
							self.authors.append(self.author)
							self.quoteIndex = self.quotes.count
						} catch {
							// Failure reading JSON.
							self.quote	= "Something went wrong! Try again."
							self.author	= "This App"
						}
					} else if error != nil {
						// No Internet Connection.
						if !self.connected {
							self.quote	= "\"It seems that you are not connected to the internet!\""
							self.author	= "This App"
						}
					}
					}.resume()
			}
			
		}
	}
	
	@IBAction func previousQuote(sender: AnyObject?) {
		if quoteIndex != 0 {
			quoteIndex -= 1
			
			quote		= quotes[quoteIndex]
			author	= authors[quoteIndex]
			
            if quoteIndex	== 0 { previousButton.isHidden = true }
		}
	}
	
	// Open default browser on the app github repo and close popover.
	@IBAction func openGithubPage(sender: AnyObject?) {
		if let githubURL = NSURL(string: "https://github.com/JoaoFCosta") {
            NSWorkspace.shared.open(githubURL as URL)
            let delegate = NSApplication.shared.delegate as! AppDelegate
            delegate.togglePopover(sender: sender)
		}
	}
	
	// Copy quote to clipboard.
	@IBAction func copyQuote(sender: AnyObject?) {
        let pasteBoard: NSPasteboard = NSPasteboard.general
		pasteBoard.clearContents()
		pasteBoard.writeObjects(["\(quote) - \(author)\n"])
	}
	
	@IBAction func sayQuote(sender: AnyObject?) {
        if task.isRunning {
			// Interrupt the current task and create a new one.
			task.interrupt()
            task = Process()
		} else {
			// Set the task launch path and arguments and launch it.
			task.launchPath	= "/usr/bin/say"
  		task.arguments	= ["--voice=Alex", "\(quote) - \(author)\n"]
			
			// Change play button icon before playing the quote.
			playButton.image	= stopIcon
			task.launch()
			
			task.terminationHandler = { [unowned self] _ -> Void in
				// Change the play button to the play icon and create a new task.
				self.playButton.image	= self.playIcon
                self.task = Process()
			}
		}
	}
}
