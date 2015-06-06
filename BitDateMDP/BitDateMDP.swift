//
//  BitDateMDP.swift
//  BitDateMDP
//
//  Created by Dan Manteufel on 5/26/15.
//  Copyright (c) 2015 ManDevil Programming. All rights reserved.
//

import UIKit

//MARK: - View Controllers
let kAnimationDuration = 0.2
//Kinda lazy. Not sure if this is enough encapsulation for proper OOP.
let pageController = PageVC(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)

struct SB {
    static let Main = UIStoryboard(name: "Main", bundle: nil) //Main is the default Storyboard name
    static let LoginVC = "LoginVC"
    static let CardsNC = "CardsNavController"
    static let ProfileNC = "ProfileNavController"
    static let MatchesNC = "MatchesNavController"
    static let UserCell = "User Cell"
}

//MARK: - Page View Controller
class PageVC: UIPageViewController, UIPageViewControllerDataSource {
    //MARK: Defines
    let cardsVC = SB.Main.instantiateViewControllerWithIdentifier(SB.CardsNC) as! UIViewController
    let profileVC = SB.Main.instantiateViewControllerWithIdentifier(SB.ProfileNC) as! UIViewController
    let matchesVC = SB.Main.instantiateViewControllerWithIdentifier(SB.MatchesNC) as! UIViewController

    //MARK: Properties
    
    //MARK: Flow Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteColor()
        dataSource = self
        setViewControllers([cardsVC], direction: .Forward, animated: true, completion: nil)
    }
    
    //MARK: Helper Functions
    func goToNextVC() {
        let nextVC = pageViewController(self, viewControllerAfterViewController: viewControllers[0] as! UIViewController)!
        setViewControllers([nextVC], direction: .Forward, animated: true, completion: nil)
    }
    
    func goToPreviousVC() {
        let previousVC = pageViewController(self, viewControllerBeforeViewController: viewControllers[0] as! UIViewController)!
        setViewControllers([previousVC], direction: .Reverse, animated: true, completion: nil)
    }

    //MARK: PageVC Data Source
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        switch viewController {
            case cardsVC: return profileVC
            case matchesVC: return cardsVC
            default: return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        switch viewController {
            case cardsVC: return matchesVC
            case profileVC: return cardsVC
            default: return nil
        }
    }
}

//MARK: - Login View Controller
class LoginVC: UIViewController {
    //MARK: Defines
    
    //MARK: Properties
    
    //MARK: Flow Functions
    @IBAction func pressedFBLogin(sender: UIButton) {
        PFFacebookUtils.logInWithPermissions(["public_profile","user_about_me","user_birthday"]) {
            user, error in
            if user == nil {
                println("User cancelled Facebook login")
                //Alert user that it won't work without Facebook login
                return
            } else if user!.isNew {
                println("User logged in for the first time")
                FBRequestConnection.startWithGraphPath("/me?fields=picture,first_name,birthday,gender") {
                    connection, result, error in
                    if let resultDict = result as? NSDictionary {
                        user!["firstName"] = resultDict["first_name"]
                        user!["gender"] = resultDict["gender"]
                        var dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "MM/dd/yyyy"
                        user!["birthday"] = dateFormatter.dateFromString(resultDict["birthday"] as! String)
                        
                        let pictureURL = NSURL(string: ((resultDict[K.PictureKey] as! NSDictionary)["data"] as! NSDictionary)["url"] as! String)
                        let request = NSURLRequest(URL: pictureURL!)
                        NSURLConnection.sendAsynchronousRequest(request, queue: .mainQueue()) { //Is mainQueue() really best practice?
                            response, data, error in
                            let imageFile = PFFile(name: "avatar.jpg", data: data)
                            user![K.PictureKey] = imageFile
                            user!.saveInBackgroundWithBlock(nil)
                        }
                    }
                }
            } else {
                println("User logged in through Facebook")
            }
            if let navVC = SB.Main.instantiateViewControllerWithIdentifier(SB.CardsNC) as? UIViewController {
                self.presentViewController(navVC, animated: true) {/*Completion handler */}
            }
        }
    }
    
    //MARK: Helper Functions
    
}

//MARK: - Profile View Controller
class ProfileVC: UIViewController {
    //MARK: Defines
    
    //MARK: Properties
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    //MARK: Flow Functions
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.titleView = UIImageView(image: UIImage(named: "profile-header"))
        let rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav-back-button"), style: .Plain, target: self, action: "goToCards:")
        navigationItem.setRightBarButtonItem(rightBarButtonItem, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = currentUser()?.name
        currentUser()?.getPhoto() {
            image in
            self.imageView.layer.masksToBounds = true
            self.imageView.contentMode = .ScaleAspectFill
            self.imageView.image = image
        }
    }
    
    func goToCards(button: UIBarButtonItem) {
        pageController.goToNextVC()
    }
    
    //MARK: Helper Functions
    
}

//MARK: - Cards View Controller
class CardsVC: UIViewController, SwipeViewDelegate {
    //MARK: Defines
    let kFrontCardTopMargin = CGFloat(0)
    let kBackCardTopMargin = CGFloat(10)//Actually delta between front and back

    struct Card {
        let cardView: CardView
        let swipeView: SwipeView
        let user: User
    }
    
    //MARK: Properties
    @IBOutlet weak var cardStackView: UIView!
    @IBOutlet weak var nahButton: UIButton!
    @IBOutlet weak var yeahButton: UIButton!
    
    var frontCard: Card?
    var backCard: Card?
    var users: [User]?
    
    //MARK: Flow Functions
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.titleView = UIImageView(image: UIImage(named: "nav-header"))
        let leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav-back-button"), style: .Plain, target: self, action: "goToProfile:")
        navigationItem.setLeftBarButtonItem(leftBarButtonItem, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardStackView.backgroundColor = .clearColor()
        nahButton.setImage(UIImage(named: "nah-button-pressed"), forState: .Highlighted)
        yeahButton.setImage(UIImage(named: "yeah-button-pressed"), forState: .Highlighted)
        fetchUnviewedUsers() {
            self.users = $0
            if let card = self.popCard() {
                self.frontCard = card
                self.cardStackView.addSubview(self.frontCard!.swipeView)
            }
            if let card = self.popCard() {
                self.backCard = card
                self.backCard!.swipeView.frame = self.createCardFrame(self.kBackCardTopMargin)
                self.cardStackView.insertSubview(self.backCard!.swipeView, belowSubview: self.frontCard!.swipeView)
            }
        }
    }
    
    @IBAction func nahButtonPressed(sender: UIButton) {
        if let card = frontCard {
            card.swipeView.swipe(.Left)
        }
    }
    
    @IBAction func yeahButtonPressed(sender: UIButton) {
        if let card = frontCard {
            card.swipeView.swipe(.Right)
        }
    }
    
    func goToProfile(button: UIBarButtonItem) {
        pageController.goToPreviousVC()
    }
    
    //MARK: Helper Functions
    private func createCardFrame(topMargin: CGFloat) -> CGRect {
        return CGRect(origin: CGPoint(x: 0, y: topMargin), size: cardStackView.frame.size)
    }
    
    private func createCard(user: User) -> Card {
        let cardView = CardView()
        cardView.name = user.name
        user.getPhoto() { cardView.image = $0 }
        let swipeView = SwipeView(frame: createCardFrame(kFrontCardTopMargin))
        swipeView.delegate = self
        swipeView.innerView = cardView
        return Card(cardView: cardView, swipeView: swipeView, user: user)
    }
    
    private func popCard() -> Card? {
        if users != nil && users?.count > 0 {
            return createCard(users!.removeLast())
        }
        return nil
    }
    
    private func switchCards() {
        if let card = backCard {
            frontCard = card
            UIView.animateWithDuration(kAnimationDuration) {
                self.frontCard!.swipeView.frame = self.createCardFrame(self.kFrontCardTopMargin)
            }
        }
        if let card = self.popCard() {
            backCard = card
            backCard!.swipeView.frame = createCardFrame(kBackCardTopMargin)
            cardStackView.insertSubview(backCard!.swipeView, belowSubview: frontCard!.swipeView)
        }
    }
    
    //MARK: SwipeView Delegate
    func swipedLeft() {
//        println("Swiped Left")
        if let frontCard = frontCard {
            frontCard.swipeView.removeFromSuperview()
            saveSkip(frontCard.user)
            switchCards()
        }
    }
    
    func swipedRight() {
//        println("Swiped Right")
        if let frontCard = frontCard {
            frontCard.swipeView.removeFromSuperview()
            saveLike(frontCard.user)
            switchCards()
        }
    }
}

//MARK: - Matches Table View Controller
class MatchesTVC: UITableViewController {
    //MARK: Defines
    
    //MARK: Properties
    var matches: [Match] = [] { didSet { tableView.reloadData() } }
    
    //MARK: Flow Functions
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.titleView = UIImageView(image: UIImage(named: "chat-header"))
        let leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "nav-back-button"), style: .Plain, target: self, action: "goToPreviousVC:")
        navigationItem.setLeftBarButtonItem(leftBarButtonItem, animated: true)
        fetchMatches() { self.matches = $0 }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: Helper Functions
    func goToPreviousVC(button: UIBarButtonItem) {
        pageController.goToPreviousVC()
    }
    
    //MARK: UITableView Data Source
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(SB.UserCell) as! UserCell
        let user = matches[indexPath.row].user
        cell.nameLabel.text = user.name
        user.getPhoto() {
            cell.avatarImageView.image = $0
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    //MARK: UITableView Delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let chatVC = ChatVC()
        let match = matches[indexPath.row]
        chatVC.matchID = match.id
        chatVC.title = match.user.name
        navigationController?.pushViewController(chatVC, animated: true)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    
}

//MARK: - Chat View Controller
class ChatVC: JSQMessagesViewController {
    //MARK: Defines
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(.jsq_messageBubbleBlueColor())
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(.jsq_messageBubbleLightGrayColor())
    
    //MARK: Properties
    var messages: [JSQMessage] = []
    var matchID: String?
    var messageListener: MessageListener?
    override var senderId: String! {
        get {
            return currentUser()?.id
        }
        set {
            super.senderId = newValue
        }
    }
    override var senderDisplayName: String! {
        get {
            return currentUser()?.name
        }
        set {
            super.senderDisplayName = newValue
        }
    }
    
    //MARK: Flow Functions
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let id = matchID {
            messageListener = MessageListener(matchID: id, startDate: NSDate()) {
                message in
                self.messages.append(JSQMessage(senderId: message.senderID, senderDisplayName: message.senderID, date: message.date, text: message.message))
                self.finishReceivingMessage()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Removing avators because we don't have time to figure them out
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        if let id = matchID {
            fetchMessages(id) {
                messages in
                for message in messages {
                    self.messages.append(JSQMessage(senderId: message.senderID, senderDisplayName: message.senderID, date: message.date, text: message.message))
                }
                self.finishReceivingMessage()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        messageListener?.stop()
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        messages.append(message)
        if let id = matchID {
            saveMessage(id, Message(message: text, senderID: senderId, date: date))
        }
        finishSendingMessage()
    }
    
    //MARK: Helper Functions
    
    //MARK: JSQMessagesCollectionView Data Source
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        if messages[indexPath.row].senderId == PFUser.currentUser()?.objectId {
            return outgoingBubble
        } else { return incomingBubble }
    }
    
    //MARK: UICollectionView Data Source
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
}

//MARK: - Views
//MARK: - Card View
@IBDesignable
class CardView: UIView {
    //MARK: Defines
    let kCVLayerBorderWidth = CGFloat(0.5)
    let kCVLayerCornerRadius = CGFloat(5)
    let kCVConstraintStandardMultiplier = CGFloat(1)
    let kCVConstraintStandardConstant = CGFloat(0)
    let kCVConstraintNameLabelOffsetConstant = CGFloat(10)
    
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    
    //MARK: Properties
    var name: String? { didSet { if let name = name { nameLabel.text = name }}}
    var image: UIImage? { didSet { if let image = image { imageView.image = image }}}
    
    //MARK: Flow Functions
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
//    override init() {
//        super.init()
//        initialSetup()
//    }
    
    //MARK: Helper Functions
    private func initialSetup() {
        imageView.setTranslatesAutoresizingMaskIntoConstraints(false) //Using custom constraints in code
        imageView.backgroundColor = .redColor()
        addSubview(imageView)
        
        nameLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(nameLabel)
        
        backgroundColor = .greenColor()
        layer.borderWidth = kCVLayerBorderWidth
        layer.borderColor = UIColor.lightGrayColor().CGColor
        layer.cornerRadius = kCVLayerCornerRadius
        layer.masksToBounds = true
        
        setConstraints()
        
    }
    
    private func setConstraints() {
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: kCVConstraintStandardMultiplier, constant: kCVConstraintStandardConstant))
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: kCVConstraintStandardMultiplier, constant: kCVConstraintStandardConstant))
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: kCVConstraintStandardMultiplier, constant: kCVConstraintStandardConstant))
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: kCVConstraintStandardMultiplier, constant: kCVConstraintStandardConstant))
        
        addConstraint(NSLayoutConstraint(item: nameLabel, attribute: .Top, relatedBy: .Equal, toItem: imageView, attribute: .Bottom, multiplier: kCVConstraintStandardMultiplier, constant: kCVConstraintStandardConstant))
        addConstraint(NSLayoutConstraint(item: nameLabel, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: kCVConstraintStandardMultiplier, constant: kCVConstraintNameLabelOffsetConstant))
        addConstraint(NSLayoutConstraint(item: nameLabel, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: kCVConstraintStandardMultiplier, constant: -kCVConstraintNameLabelOffsetConstant))
        addConstraint(NSLayoutConstraint(item: nameLabel, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: kCVConstraintStandardMultiplier, constant: kCVConstraintStandardConstant))

    }
    
}

//MARK: - Swipe View
@IBDesignable
class SwipeView: UIView {
    //MARK: Defines
    let kSVConstraintStandardMultiplier = CGFloat(1)
    let kSVConstraintStandardConstant = CGFloat(0)
    let kDecisionThreshold = CGFloat(4)
    
    let overlay = UIImageView()
    
    //MARK: Properties
    private var originalPoint: CGPoint?
    weak var delegate: SwipeViewDelegate? //prevents memory retain cycle - makes sense with delegation
    var innerView: UIView? {
        didSet {
            if let innerView = innerView {
                innerView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
                insertSubview(innerView, belowSubview: overlay)
            }
        }
    }
    var direction: Direction?
    
    //MARK: Flow Functions
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    //MARK: Helper Functions
    private func initialSetup() {
        backgroundColor = .clearColor()
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "dragged:"))
        
        overlay.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height) //overlay is same size as SwipeView
        addSubview(overlay)
        
    }
    
    func dragged(gesture: UIPanGestureRecognizer) {
        let distance = gesture.translationInView(self)
        
        switch gesture.state {
        case .Began: originalPoint = center
        case .Changed:
            let rotationPct = min(distance.x/(superview!.frame.width/2), 1)
            let rotationAngle = CGFloat(2*M_PI/16)*rotationPct
            transform = CGAffineTransformMakeRotation(rotationAngle)
            
            center = CGPointMake(originalPoint!.x + distance.x, originalPoint!.y + distance.y)
            updateOverlay(distance.x)
            
        case .Ended:
            if abs(distance.x) < frame.width/kDecisionThreshold { resetViewPositionAndTransformations() }
            else { swipe(distance.x > 0 ? .Right : .Left) }
        default: break
        }
        
    }
    
    private func resetViewPositionAndTransformations() {
        UIView.animateWithDuration(kAnimationDuration) {
            self.center = self.originalPoint!
            self.transform = CGAffineTransformIdentity
            self.overlay.alpha = 0
        }
    }
    
    func swipe(s: Direction) {
        if s == .None { return }
        var parentWidth = superview!.frame.size.width
        if s == .Left { parentWidth *= -1 }
        
        UIView.animateWithDuration(kAnimationDuration, animations: { self.center.x = self.frame.origin.x + parentWidth }) {
            success in
            if let delegate = self.delegate {
                s == .Right ? delegate.swipedRight() : delegate.swipedLeft()
            }
        }
    }
    
    private func updateOverlay(distance: CGFloat) {
        var newDirection: Direction
        newDirection = distance < 0 ? .Left : .Right
        if newDirection != direction {
            direction = newDirection
            overlay.image = direction == .Right ? UIImage(named: "yeah-stamp") : UIImage(named: "nah-stamp")
        }
        overlay.alpha = abs(distance) / (superview!.frame.width / 2)
    }
    
}

protocol SwipeViewDelegate: class {
    func swipedLeft()
    func swipedRight()
}

//MARK: - User Cell
class UserCell: UITableViewCell {
    //MARK: Defines
    
    //MARK: Properties
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    //MARK: Flow Functions
    
    //MARK: Helper Functions
    override func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.height / 2
        avatarImageView.layer.masksToBounds = true
    }
    
}

//MARK: - Enums
enum Direction {
    case None
    case Left
    case Right
}

//MARK: - Model
//MARK: Constants
private struct K {
    static let PictureKey = "picture"
    static let ParseAppID = "TXYTkJvwFTxGTCRAcXRq5MsXmuPjehT1sc42gz3J"
    static let ParseClientKey = "lXTnV3acc8gNoimtDGzy3EdGzAnyKhHQHbYJzu1o"
    static let ParseActionObject = "Action"
    static let ByUserAttr = "byUser"
    static let ToUserAttr = "toUser"
    static let ObjectIDAttr = "objectId"
    static let TypeAttr = "type"
    static let MatchedValue = "matched"
    static let MessageKey = "message"
    static let SenderKey = "sender"
    static let FirebaseSession = Firebase(url: "https://bitdatemdp.firebaseio.com/messages")
    static let MessageQueryLimit = UInt(25)
    
    static func dateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        return dateFormatter
    }

}

//MARK: Model Data Structs
struct User {
    //Public Interface
    let id: String
    let name: String
    
    func getPhoto(callback: (UIImage) -> () ) {
        let imageFile = pfUser.objectForKey(K.PictureKey) as! PFFile
        imageFile.getDataInBackgroundWithBlock() {
            data, error in
            if let data = data {
                callback(UIImage(data: data)!)
            }
        }
    }
    
    //Private Interface - Backend
    private let pfUser: PFUser
}

struct Match {
    //Public Interface
    let id: String
    let user: User
    
    //Private Interface - Backend
}

struct Message {
    //Public Interface
    let message: String
    let senderID: String
    let date: NSDate
    
    //Private Interface - Backend
}

//MARK: Model Classes
class MessageListener {
    //MARK: Defines
    
    //MARK: Properties
    var currentHandle: UInt?
    
    //MARK: Functions
    init(matchID: String, startDate: NSDate, callback: (Message) -> ()) {
        let handle = K.FirebaseSession.childByAppendingPath(matchID).queryOrderedByKey().queryStartingAtValue(K.dateFormatter().stringFromDate(startDate))
            .observeEventType(FEventType.ChildAdded, withBlock: {
                snapshot in
                let message = snapshotToMessage(snapshot)
                callback(message)
        })
        self.currentHandle = handle
    }
    
    func stop() {
        if let handle = currentHandle {
            K.FirebaseSession.removeObserverWithHandle(handle)
            currentHandle = nil
        }
    }
}

//MARK: - Public Model Functions
func currentUser() -> User? {
    if let user = PFUser.currentUser() {
        return pfUserToUser(user)
    }
    return nil
}

func setupUserBackend() {
    Parse.setApplicationId(K.ParseAppID, clientKey: K.ParseClientKey)
    PFFacebookUtils.initializeFacebook()
}

func fetchUnviewedUsers(callback: ([User]) -> ()) {
    PFQuery(className: K.ParseActionObject)
        .whereKey(K.ByUserAttr, equalTo: PFUser.currentUser()!.objectId!)
        .findObjectsInBackgroundWithBlock() {
        objects, error in
        if let pfUsers = objects as? [PFObject] {
            let seenIDs = map(pfUsers) { $0.objectForKey(K.ToUserAttr)!}
            PFUser.query()!
                .whereKey(K.ObjectIDAttr, notEqualTo: (PFUser.currentUser()?.objectId)!)
                .whereKey(K.ObjectIDAttr, notContainedIn: seenIDs)
                .findObjectsInBackgroundWithBlock() {
                objects, error in
                if let pfUsers = objects as? [PFUser] {
                    let users = map(pfUsers) { pfUserToUser($0) }
                    callback(users)
                }
            }
        }
    }
}

func saveSkip(user: User) {
    let skip = PFObject(className: "Action")
    skip.setObject(PFUser.currentUser()!.objectId!, forKey: "byUser")
    skip.setObject(user.id, forKey: "toUser")
    skip.setObject("skipped", forKey: "type")
    skip.saveInBackgroundWithBlock(nil)
}

func saveLike(user: User) {
//    let like = PFObject(className: "Action")
//    like.setObject(PFUser.currentUser()!.objectId!, forKey: "byUser")
//    like.setObject(user.id, forKey: "toUser")
//    like.setObject("liked", forKey: "type")
//    like.saveInBackgroundWithBlock(nil)
    
    //TEST FOR MATCHES WOULD NORMALLY BE ON BACK END
    PFQuery(className: "Action")
        .whereKey("byUser", equalTo: user.id)
        .whereKey("toUser", equalTo: PFUser.currentUser()!.objectId!)
        .whereKey("type", equalTo: "liked")
        .getFirstObjectInBackgroundWithBlock() { //Know there's only one (optimized)
            object, error in
            var matched = false
            if object != nil {
                matched = true
                object?.setObject("matched", forKey: "type")
                object?.saveInBackgroundWithBlock(nil)
            }
            let match = PFObject(className: "Action")
            match.setObject(PFUser.currentUser()!.objectId!, forKey: "byUser")
            match.setObject(user.id, forKey: "toUser")
            match.setObject(matched ? "matched" : "liked", forKey: "type")
            match.saveInBackgroundWithBlock(nil)
    }
}

func fetchMatches(callback: ([Match]) -> ()) {
    PFQuery(className: K.ParseActionObject)
        .whereKey(K.ByUserAttr, equalTo: PFUser.currentUser()!.objectId!)
        .whereKey(K.TypeAttr, equalTo: K.MatchedValue)
        .findObjectsInBackgroundWithBlock() {
            objects, error in
            if let matches = objects as? [PFObject] {
                let matchedUsers = matches.map(){
                    (object) -> (matchID: String , userID: String) in
                    (object.objectId! , object.objectForKey(K.ToUserAttr) as! String)
                }
                let userIDs = matchedUsers.map(){ $0.userID }
                PFUser.query()?
                    .whereKey(K.ObjectIDAttr, containedIn: userIDs)
                    .findObjectsInBackgroundWithBlock() {
                        objects, error in
                        if var users = objects as? [PFUser] {
                            //Parse gives you users in reverse order
                            users.reverse()
                            var matches = Array<Match>()
                            for (index , user) in enumerate(users) {
                                matches.append(Match(id: matchedUsers[index].matchID, user: pfUserToUser(user)))
                            }
                            callback(matches)
                        }
                }
            }
    }
}

func saveMessage(matchID: String, message: Message) {
    K.FirebaseSession.childByAppendingPath(matchID).updateChildValues([K.dateFormatter().stringFromDate(message.date) : [K.MessageKey : message.message ,
        K.SenderKey : message.senderID]])
    
}

func fetchMessages(matchId: String, callback: ([Message]) -> ()) {
    K.FirebaseSession.childByAppendingPath(matchId).queryLimitedToFirst(K.MessageQueryLimit).observeSingleEventOfType(FEventType.Value, withBlock: {
        snapshot in
        var messages = Array<Message>()
        let enumerator = snapshot.children
        while let data = enumerator.nextObject() as? FDataSnapshot {
            messages.append(snapshotToMessage(data))
        }
        callback(messages)
    })
}

//MARK: Private Model Functions
private func pfUserToUser(user: PFUser) -> User {
    return User(id: user.objectId!, name: user.objectForKey("firstName") as! String, pfUser: user)
}

private func snapshotToMessage(snapshot: FDataSnapshot) -> Message {
    let date = K.dateFormatter().dateFromString(snapshot.key)
    let sender = snapshot.value[K.SenderKey] as? String
    let text = snapshot.value[K.MessageKey] as? String
    return Message(message: text!, senderID: sender!, date: date!)
}

//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//