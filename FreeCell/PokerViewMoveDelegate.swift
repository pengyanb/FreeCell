//
//  PokerViewMoveDelegate.swift
//  FreeCell
//
//  Created by Yanbing Peng on 27/05/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import Foundation
import UIKit

protocol PokerViewMoveDelegate {

    func handlePokerViewMoveBegan(atIndexPath indexPath:NSIndexPath) -> Void
    
    func handlePokerViewMoveChanged(atIndexPath indexPath:NSIndexPath, translation:CGPoint) -> Void
    
    func handlePokerViewMoveEnd(atIndexPath indexPath:NSIndexPath) -> Void
    
    func handlePokerViewMoveCancelled(atIndexPath indexPath:NSIndexPath) -> Void
    
    func handlePokerViewMoveFailed(atIndexPath indexPath:NSIndexPath) -> Void
    
    //func handlePokerStackTap()->Void
    
    func handlePokerCardTap(atIndexPath indexPath: NSIndexPath)->Void
    
    func handleUnmoveableViewPanGesture(atIndexPath indexPath: NSIndexPath, panGesture: UIPanGestureRecognizer)->Void
}
