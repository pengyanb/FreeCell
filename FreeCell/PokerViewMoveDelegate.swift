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

    func handlePokerViewMoveBegan(atIndexPath indexPath:IndexPath) -> Void
    
    func handlePokerViewMoveChanged(atIndexPath indexPath:IndexPath, translation:CGPoint) -> Void
    
    func handlePokerViewMoveEnd(atIndexPath indexPath:IndexPath) -> Void
    
    func handlePokerViewMoveCancelled(atIndexPath indexPath:IndexPath) -> Void
    
    func handlePokerViewMoveFailed(atIndexPath indexPath:IndexPath) -> Void
    
    //func handlePokerStackTap()->Void
    
    func handlePokerCardTap(atIndexPath indexPath: IndexPath)->Void
    
    func handleUnmoveableViewPanGesture(atIndexPath indexPath: IndexPath, panGesture: UIPanGestureRecognizer)->Void
}
