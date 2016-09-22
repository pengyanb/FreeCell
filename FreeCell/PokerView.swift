//
//  PokerView.swift
//  FreeCell
//
//  Created by Yanbing Peng on 26/05/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit

@IBDesignable class PokerView: UIView {

    //MARK: - Variables
    let pokerBackImageName = "CardBack"
    let pokerSpaceImageName = "CardSpace"
    let pokerSpaceSpadeImageName = "CardSpaceSpade"
    let pokerSpaceHeartImageName = "CardSpaceHeart"
    let pokerSpaceClubImageName = "CardSpaceClub"
    let pokerSpaceDiamondImageName = "CardSpaceDiamond"
    
    @IBInspectable
    var pokerImageName:String = "CardSpace"{
        didSet{
            var imageName = ""
            if pokerIsFacingUp{
                imageName = pokerImageName
            }
            else{
                if pokerImageName == pokerSpaceImageName{
                    imageName = pokerSpaceImageName
                }
                else if pokerImageName == pokerSpaceSpadeImageName{
                    imageName = pokerSpaceSpadeImageName
                }
                else if pokerImageName == pokerSpaceHeartImageName{
                    imageName = pokerSpaceHeartImageName
                }
                else if pokerImageName == pokerSpaceClubImageName{
                    imageName = pokerSpaceClubImageName
                }
                else if pokerImageName == pokerSpaceDiamondImageName{
                    imageName = pokerSpaceDiamondImageName
                }
                else {
                    imageName = pokerBackImageName
                }
            }
            if imageName != oldValue{
                if let image = UIImage.init(named: imageName){
                    pokerImageView.image = image
                }
            }
        }
    }
    
    var pokerIsFacingUp = false{
        didSet{
            if pokerIsFacingUp != oldValue{
                var imageName = ""
                if pokerIsFacingUp{
                    imageName = pokerImageName
                }
                else{
                    if pokerImageName == pokerSpaceImageName{
                        imageName = pokerSpaceImageName
                    }
                    else if pokerImageName == pokerSpaceSpadeImageName{
                        imageName = pokerSpaceSpadeImageName
                    }
                    else if pokerImageName == pokerSpaceHeartImageName{
                        imageName = pokerSpaceHeartImageName
                    }
                    else if pokerImageName == pokerSpaceClubImageName{
                        imageName = pokerSpaceClubImageName
                    }
                    else if pokerImageName == pokerSpaceDiamondImageName{
                        imageName = pokerSpaceDiamondImageName
                    }
                    else{
                        imageName = pokerBackImageName
                    }
                }
                
                if let image = UIImage.init(named: imageName){
                    if pokerImageName == pokerSpaceImageName || pokerImageName == pokerSpaceSpadeImageName || pokerImageName == pokerSpaceHeartImageName || pokerImageName == pokerSpaceClubImageName || pokerImageName == pokerSpaceDiamondImageName{
                        pokerImageView.image = image
                    }
                    else{
                        UIView.transition(with: pokerImageView, duration: 0.1, options: UIViewAnimationOptions.transitionFlipFromLeft, animations: { [weak self] in
                                self?.pokerImageView.image = image
                            }, completion: nil)
                    }
                }
            }
        }
    }
    
    var pokerIsMoveable = false
    
    var pokerViewIndexPath : IndexPath?   //indexPath in dealed card stacks
    
    var pokerFreeSpaceIndex : Int?          //index in the free space
    
    var viewOriginalPosition: CGPoint?
    
    var viewOriginalZPosition : CGFloat?
    
    var viewMoveDelegate : PokerViewMoveDelegate?
    
    var viewOriginalPosBeforeOsset: CGPoint?
    
    var viewIsOffsetted = false{
        didSet{
            if !pokerIsFacingUp{
                viewIsOffsetted = false
                return
            }
            
            if viewIsOffsetted == true{
                if viewOriginalPosBeforeOsset == nil{
                    viewOriginalPosBeforeOsset = self.center
                    self.center = CGPoint.init(x: self.center.x, y: round(self.center.y + self.bounds.size.height / 3.0))
                }
            }
            else{
                if viewOriginalPosBeforeOsset != nil{
                    viewOriginalPosition = viewOriginalPosBeforeOsset
                    self.center = viewOriginalPosBeforeOsset!
                    viewOriginalPosBeforeOsset = nil
                }
                
            }
        }
    }
    
    override var description: String{
        return "\(pokerImageName)"
    }
    
    var viewIsPokerCard = false
    
    //MARK: - Outlets
    @IBOutlet weak var pokerImageView: UIImageView!
    
    //MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    fileprivate func xibSetup(){
        let nib = UINib(nibName: "PokerView", bundle: Bundle(for: type(of: self)))
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        //let objArray = NSBundle.mainBundle().loadNibNamed("PokerView", owner: self, options: nil)
        //let view = objArray[0] as! UIView
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognized(_:)))
        self.gestureRecognizers = [panRecognizer]
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(_:)))
        self.gestureRecognizers?.append(tapRecognizer)
    
        addSubview(view)
    }
    
    // MARK: - Public API
    func clearViewOffset(){
        if viewOriginalPosBeforeOsset != nil{
            viewOriginalPosBeforeOsset = nil
        }
        viewIsOffsetted = false
    }
    func resetToOriginal(){
        if let position = viewOriginalPosition{
            UIView.animate(withDuration: 0.1, animations: { 
                [weak self] in
                    self?.center = position
                }, completion: {[weak self] (completed) in
                    if let zPosition = self?.viewOriginalZPosition{
                        self?.layer.zPosition = zPosition
                        self?.viewIsOffsetted = false
                    }
            })
        }
        else{
            self.viewIsOffsetted = false
        }
    }
    func clearOriginal(){
        viewOriginalPosition = nil
        viewOriginalZPosition = nil
    }
    
    // MARK : - View Move handlers
    func handleViewMoveBegan(){
        if pokerIsMoveable{
            viewOriginalPosition = self.center
            viewOriginalZPosition = self.layer.zPosition
            self.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE * 10 + self.layer.zPosition
        }
    }
    func handleViewMoveChanged(_ translation:CGPoint){
        if pokerIsMoveable{
            self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
        }
    }
    func handleViewMoveCancelled(){
        if pokerIsMoveable{
            resetToOriginal()
        }
    }
    func handleViewMoveFailed(){
        if pokerIsMoveable{
            resetToOriginal()
        }
    }
    
    // MARK: - Gesture handler
    func tapGestureRecognized(_ gesture: UITapGestureRecognizer){
        if viewIsPokerCard{
            if let indexPath = self.pokerViewIndexPath{
                if self.pokerIsFacingUp{
                    viewMoveDelegate?.handlePokerCardTap(atIndexPath: indexPath)
                }
            }
        }
    }
    
    func panGestureRecognized(_ gesture: UIPanGestureRecognizer){
        if pokerIsMoveable{
            switch gesture.state {
            case .began:
                if let indexPath = self.pokerViewIndexPath{
                    viewMoveDelegate?.handlePokerViewMoveBegan(atIndexPath: indexPath)
                }
            case .changed:
                if let suView = self.superview{
                    let translation = gesture.translation(in: suView)
                    if let indexPath = self.pokerViewIndexPath{
                        viewMoveDelegate?.handlePokerViewMoveChanged(atIndexPath: indexPath, translation: translation)
                    }
                    gesture.setTranslation(CGPoint.zero, in: suView)
                }
            case .ended:
                if let indexPath = self.pokerViewIndexPath{
                    viewMoveDelegate?.handlePokerViewMoveEnd(atIndexPath: indexPath)
                }
            case .cancelled:
                if let indexPath = self.pokerViewIndexPath{
                    viewMoveDelegate?.handlePokerViewMoveCancelled(atIndexPath: indexPath)
                }
            case .failed:
                if let indexPath = self.pokerViewIndexPath{
                    viewMoveDelegate?.handlePokerViewMoveFailed(atIndexPath: indexPath)
                }
            default:
                break
            }
        }
        else{
            if let indexPath = self.pokerViewIndexPath{
                viewMoveDelegate?.handleUnmoveableViewPanGesture(atIndexPath: indexPath, panGesture: gesture)
            }
        }
    }

}
