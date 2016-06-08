//
//  EnumAndConstants.swift
//  FreeCell
//
//  Created by Yanbing Peng on 27/05/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import Foundation
import UIKit

enum CardSuit {
    case SPADE
    case CLUB
    case HEART
    case DIAMOND
    
    func name()->String{
        switch self {
        case .SPADE:
            return "Spade"
        case .CLUB:
            return "Club"
        case .HEART:
            return "Heart"
        case .DIAMOND:
            return "Diamond"
        }
    }
    
    func sameColorWith(cardSuit:CardSuit)->Bool{
        switch self {
        case .SPADE:
            if cardSuit == CardSuit.SPADE || cardSuit == CardSuit.CLUB{
                return true
            }
            else{
                return false
            }
        case .CLUB:
            if cardSuit == CardSuit.SPADE || cardSuit == CardSuit.CLUB{
                return true
            }
            else{
                return false
            }
        case .HEART:
            if cardSuit == CardSuit.SPADE || cardSuit == CardSuit.CLUB{
                return false
            }
            else{
                return true
            }
        case .DIAMOND:
            if cardSuit == CardSuit.SPADE || cardSuit == CardSuit.CLUB{
                return false
            }
            else{
                return true
            }
        }
    }
}

class CardAutoCompletionInfo{
    let card : PokerCard
    let indexPath : NSIndexPath
    init(_card: PokerCard, _indexPath:NSIndexPath){
        card = _card
        indexPath = _indexPath
    }
}

class CONSTANTS {
    //Notification
    static let NOTI_SOLITAIRE_MODEL_CHANGED = "PYBFreeCellModelChanged"
    
    static let CONST_POKER_VIEW_Z_POSITION_BASE_VALUE : CGFloat = 99
    
    static let NSUSER_DEFAULTS_NOT_SHOW_TUTORIAL_KEY = "PYBFreeCellUserDefaultsNotShowTutorialKey"
    static let NSUSER_DEFAULTS_SHOW_HINTS_KEY = "PYBFreeCellUserDefaultsShowHintsKey"
    static let NSUSER_DEFAULTS_NO_SOUND_EFFECTS_KEY = "PYBFreeCellUserDefaultsNoSoundEffectsKey"
    
    static let NSUSER_DEFAULTS_TIME_ELLAPSED_KEY = "PYBFreeCellUserDefaultsTimeEllapsedKey"
}
