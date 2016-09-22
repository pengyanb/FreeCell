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
    case spade
    case club
    case heart
    case diamond
    
    func name()->String{
        switch self {
        case .spade:
            return "Spade"
        case .club:
            return "Club"
        case .heart:
            return "Heart"
        case .diamond:
            return "Diamond"
        }
    }
    
    func sameColorWith(_ cardSuit:CardSuit)->Bool{
        switch self {
        case .spade:
            if cardSuit == CardSuit.spade || cardSuit == CardSuit.club{
                return true
            }
            else{
                return false
            }
        case .club:
            if cardSuit == CardSuit.spade || cardSuit == CardSuit.club{
                return true
            }
            else{
                return false
            }
        case .heart:
            if cardSuit == CardSuit.spade || cardSuit == CardSuit.club{
                return false
            }
            else{
                return true
            }
        case .diamond:
            if cardSuit == CardSuit.spade || cardSuit == CardSuit.club{
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
    let indexPath : IndexPath
    init(_card: PokerCard, _indexPath:IndexPath){
        card = _card
        indexPath = _indexPath
    }
}

class CONSTANTS {
    //Notification
    static let NOTI_SOLITAIRE_MODEL_CHANGED = "PYBFreeCellModelChanged"
    
    static let CONST_POKER_VIEW_Z_POSITION_BASE_VALUE : CGFloat = 99
    
    static let NSUSER_DEFAULTS_NOT_AUTO_COMPLETE_KEY = "PYBFreeCellUserDefaultsNotAutoCompleteKey"
    static let NSUSER_DEFAULTS_NOT_SHOW_TUTORIAL_KEY = "PYBFreeCellUserDefaultsNotShowTutorialKey"
    static let NSUSER_DEFAULTS_SHOW_HINTS_KEY = "PYBFreeCellUserDefaultsShowHintsKey"
    static let NSUSER_DEFAULTS_NO_SOUND_EFFECTS_KEY = "PYBFreeCellUserDefaultsNoSoundEffectsKey"
    
    static let NSUSER_DEFAULTS_TIME_ELLAPSED_KEY = "PYBFreeCellUserDefaultsTimeEllapsedKey"
    static let NSUSER_DEFAULTS_TOP_TEN_SCORE_KEY = "PYBFeeCellUserDefaultsTopTenScoreKey"
    static let NSUSER_DEFAULTS_OVERALL_TIME_KEY = "PYBFreeCellUserDefaultsOverallTimeKey"
    static let NSUSER_DEFAULTS_OVERALL_ROUND_COMPLETED_KEY = "PYNFreeCellUserDefaultsOverallRoundCompletedKey"
}
