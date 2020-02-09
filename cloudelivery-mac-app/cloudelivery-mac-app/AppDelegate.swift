
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
  let popover = NSPopover()
  var eventMonitor: EventMonitor?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    if let button = statusItem.button {
      button.image = NSImage(named: NSImage.Name("StatusBarButtonImage"))
      button.action = #selector(AppDelegate.togglePopover(_:))
    }
    
    popover.contentViewController = appViewController.freshController()
    
    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      if let strongSelf = self, strongSelf.popover.isShown {
        strongSelf.closePopover(sender: event)
      }
    }
  }
  
  @objc func togglePopover(_ sender: Any?) {
    if popover.isShown {
      closePopover(sender: sender)
    } else {
      showPopover(sender: sender)
    }
  }

  func showPopover(sender: Any?) {
    if let button = statusItem.button {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
      eventMonitor?.start()
    }
  }

  func closePopover(sender: Any?) {
    popover.performClose(sender)
    eventMonitor?.stop()
  }

  @objc func printQuote(_ sender: Any?) {
    let quoteText = "Never put off until tomorrow what you can do the day after tomorrow."
    let quoteAuthor = "Mark Twain"

    print("\(quoteText) — \(quoteAuthor)")
  }

  func constructMenu() {
    let menu = NSMenu()

    menu.addItem(NSMenuItem(title: "Print Quote", action: #selector(AppDelegate.printQuote(_:)), keyEquivalent: "P"))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit Quotes", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    statusItem.menu = menu
  }

}
