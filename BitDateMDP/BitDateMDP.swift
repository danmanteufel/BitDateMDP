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

//MARK: - Card View Controller
class CardsVC: UIViewController {
    //MARK: Defines
    let kFrontCardTopMargin = CGFloat(0)
    let kBackCardTopMargin = CGFloat(10)
    
    //MARK: Properties
    @IBOutlet weak var cardStackView: UIView!
    var frontCard: SwipeView?
    var backCard: SwipeView?
    
    //MARK: Flow Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        cardStackView.backgroundColor = .clearColor()
        
        backCard = SwipeView(frame: createCardFrame(kBackCardTopMargin))
        cardStackView.addSubview(backCard!)
        frontCard = SwipeView(frame: createCardFrame(kFrontCardTopMargin))
        cardStackView.addSubview(frontCard!)
    }
    
    //MARK: Helper Functions
    private func createCardFrame(topMargin: CGFloat) -> CGRect {
        return CGRect(origin: CGPoint(x: 0, y: topMargin), size: cardStackView.frame.size)
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
    let kResetAnimationDuration = 0.2
    
    private let card = CardView()
    
    //Properties
    private var originalPoint: CGPoint?
    
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
        card.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(card)
        
        backgroundColor = .clearColor()
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "dragged:"))
        
        setConstraints()
    }
    
    private func setConstraints() {
        addConstraint(NSLayoutConstraint(item: card, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: kSVConstraintStandardMultiplier, constant: kSVConstraintStandardConstant))
        addConstraint(NSLayoutConstraint(item: card, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: kSVConstraintStandardMultiplier, constant: kSVConstraintStandardConstant))
        addConstraint(NSLayoutConstraint(item: card, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: kSVConstraintStandardMultiplier, constant: kSVConstraintStandardConstant))
        addConstraint(NSLayoutConstraint(item: card, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: kSVConstraintStandardMultiplier, constant: kSVConstraintStandardConstant))

    }
    
    func dragged(gesture: UIPanGestureRecognizer) {
        let distance = gesture.translationInView(self)
        
        switch gesture.state {
        case .Began: originalPoint = center
        case .Changed: center = CGPointMake(originalPoint!.x + distance.x, originalPoint!.y + distance.y)
        case .Ended: resetViewPositionAndTransformations()
        default: break
        }
        
    }
    
    private func resetViewPositionAndTransformations() {
        UIView.animateWithDuration(kResetAnimationDuration) { self.center = self.originalPoint! }
    }
    
}
//
//
//
//
//
//