//
//  BitDateMDP.swift
//  BitDateMDP
//
//  Created by Dan Manteufel on 5/26/15.
//  Copyright (c) 2015 ManDevil Programming. All rights reserved.
//

import UIKit

//MARK: - View Controllers
//MARK: - Home VC
class HomeVC: UIViewController {
    //MARK: Defines

    //MARK: Properties
    
    //MARK: Flow Functions
    
    //MARK: Helper Functions

}

//MARK: - Login VC
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
                        user!["picture"] = ((resultDict["picture"] as! NSDictionary)["data"] as! NSDictionary)["url"]
                        var dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "MM/dd/yyyy"
                        user!["birthday"] = dateFormatter.dateFromString(resultDict["birthday"] as! String)
                        user!.saveInBackgroundWithBlock() {
                            success, error in
                            println(success)
                            println(error)
                        }
                    }
                }
            } else {
                println("User logged in through Facebook")
            }
            let mainSB = UIStoryboard(name: "Main", bundle: nil) //Main is the default Storyboard name
            if let navVC = mainSB.instantiateViewControllerWithIdentifier("CardsNavController") as? UIViewController {
                self.presentViewController(navVC, animated: true) {/*Completion handler */}
            }
        }
    }
    
    //MARK: Helper Functions
    
}

//MARK: - Card View Controller
class CardsVC: UIViewController, SwipeViewDelegate {
    //MARK: Defines
    let kFrontCardTopMargin = CGFloat(0)
    let kBackCardTopMargin = CGFloat(10)

    struct Card {
        let cardView: CardView
        let swipeView: SwipeView
    }
    
    //MARK: Properties
    @IBOutlet weak var cardStackView: UIView!
    var frontCard: Card?
    var backCard: Card?
    
    //MARK: Flow Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        cardStackView.backgroundColor = .clearColor()
        
        backCard = createCard(kBackCardTopMargin)
        cardStackView.addSubview(backCard!.swipeView)
        frontCard = createCard(kFrontCardTopMargin)
        cardStackView.addSubview(frontCard!.swipeView)
    }
    
    //MARK: Helper Functions
    private func createCardFrame(topMargin: CGFloat) -> CGRect {
        return CGRect(origin: CGPoint(x: 0, y: topMargin), size: cardStackView.frame.size)
    }
    
    private func createCard(topMargin: CGFloat) -> Card {
        let cardView = CardView()
        let swipeView = SwipeView(frame: createCardFrame(topMargin))
        swipeView.delegate = self
        swipeView.innerView = cardView
        return Card(cardView: cardView, swipeView: swipeView)
    }
    
    //MARK: SwipeView Delegate
    func swipedLeft() {
        println("Swiped Left")
        if let frontCard = frontCard {
            frontCard.swipeView.removeFromSuperview()
        }
    }
    
    func swipedRight() {
        println("Swiped Right")
        if let frontCard = frontCard {
            frontCard.swipeView.removeFromSuperview()
        }
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
    //Defines
    let kSVConstraintStandardMultiplier = CGFloat(1)
    let kSVConstraintStandardConstant = CGFloat(0)
    let kAnimationDuration = 0.2
    let kDecisionThreshold = CGFloat(4)
    
    //Properties
    private var originalPoint: CGPoint?
    weak var delegate: SwipeViewDelegate? //prevents memory retain cycle - makes sense with delegation
    var innerView: UIView? {
        didSet {
            if let innerView = innerView {
                innerView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
                addSubview(innerView)
            }
        }
    }
    
    //Flow Functions
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    //Helper Functions
    private func initialSetup() {
        backgroundColor = .clearColor()
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "dragged:"))
        
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
    
}

protocol SwipeViewDelegate: class {
    func swipedLeft()
    func swipedRight()
}

//MARK: - Enums
enum Direction {
    case None
    case Left
    case Right
}
//
//
//
//
//
//