//
//  FreeCellGameModel.swift
//  FreeCell
//
//  Created by Yanbing Peng on 27/05/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import Foundation

class FreeCellGameModel: NSObject {
    
    // MARK: - Variables
    fileprivate var cardSuitsAvailiable = [CardSuit.spade, CardSuit.heart, CardSuit.club, CardSuit.diamond];
    
    fileprivate var cardStackOnHold = [PokerCard]()
    var getCardStackOnHold : [PokerCard]{
        get{
            return cardStackOnHold
        }
    }
    
    fileprivate var cardDealedStack1 = [PokerCard]()
    fileprivate var cardDealedStack2 = [PokerCard]()
    fileprivate var cardDealedStack3 = [PokerCard]()
    fileprivate var cardDealedStack4 = [PokerCard]()
    fileprivate var cardDealedStack5 = [PokerCard]()
    fileprivate var cardDealedStack6 = [PokerCard]()
    fileprivate var cardDealedStack7 = [PokerCard]()
    fileprivate var cardDealedStack8 = [PokerCard]()
    
    lazy var dealedCardStacks : [[PokerCard]] =  { return [self.cardDealedStack1, self.cardDealedStack2, self.cardDealedStack3, self.cardDealedStack4, self.cardDealedStack5, self.cardDealedStack6, self.cardDealedStack7, self.cardDealedStack8]}()
    
    fileprivate var totalMoveCount = 0
    var getTotalMoveCount : Int{
        get{
            return totalMoveCount
        }
    }
    
    fileprivate(set) var completeStackCount : Int = 0
    
    fileprivate var cardFreeSpaceCount = 4
    
    fileprivate var cardOnFreeSpace1 : PokerCard?
    fileprivate var cardOnFreeSpace2 : PokerCard?
    fileprivate var cardOnFreeSpace3 : PokerCard?
    fileprivate var cardOnFreeSpace4 : PokerCard?
    fileprivate lazy var cardsOnFreeSpace : [PokerCard?] = {
        return [self.cardOnFreeSpace1, self.cardOnFreeSpace2, self.cardOnFreeSpace3, self.cardOnFreeSpace4]
    }()
    
    fileprivate var cardCompleteStack1 = [PokerCard]()
    fileprivate var cardCompleteStack2 = [PokerCard]()
    fileprivate var cardCompleteStack3 = [PokerCard]()
    fileprivate var cardCompleteStack4 = [PokerCard]()
    fileprivate lazy var cardCompleteStacks : [[PokerCard]] = {
        return [self.cardCompleteStack1, self.cardCompleteStack2, self.cardCompleteStack3, self.cardCompleteStack4]
    }()
    
    var getCardCompleteStacks : [[PokerCard]]{
        get{
            return cardCompleteStacks
        }
    }
    
    fileprivate let CARD_FREE_SPACE_INDEXPATH_SECTION = 8
    
    fileprivate let CARD_COMPLETE_INDEXPATH_SECTION = 9
    
    var errorMessage = ""
    
    var needAutoComplete = true
    
    var cardsToBeAutoComplete = [CardAutoCompletionInfo] ()
    
    // MARK: - public API
    func startNewGame(){
        cardStackOnHold = [PokerCard]()
        totalMoveCount = 0
        completeStackCount = 0
        for (index, _) in dealedCardStacks.enumerated(){
            dealedCardStacks[index].removeAll()
        }
        for i in 0..<4{
            cardsOnFreeSpace[i] = nil
        }
        for i in 0..<4{
            cardCompleteStacks[i].removeAll()
        }
        
        var cardStackOverall = [PokerCard]()
        for suit in cardSuitsAvailiable{
            let stack = generateCardStackWith(suit)
            cardStackOverall += stack
        }
        cardFreeSpaceCount = 4
        
        if cardStackOverall.count > 0{
            var keepGoing = true
            while keepGoing {
                let (card, remainingStack) = drawRandomCardFromStack(cardStackOverall)
                cardStackOnHold.append(card)
                cardStackOverall = remainingStack
                if cardStackOverall.count > 0{
                    keepGoing = true
                }
                else{
                    keepGoing = false
                }
            }
        }
        
        postNotification("cardStackOnHoldCreated")
    }
    
    func dealCardStacks(){
        var cardStackIndexToDeal = 0
        if cardStackOnHold.count > 0{
            for pokerCard in cardStackOnHold{
                pokerCard._cardIsFacingUp = true
                dealedCardStacks[cardStackIndexToDeal].append(pokerCard)
                cardStackIndexToDeal += 1
                if cardStackIndexToDeal > 7{
                    cardStackIndexToDeal = 0
                }
            }
            cardStackOnHold.removeAll()
            print(dealedCardStacks)
            postNotification("cardStacksDealed")
            processCardMoveableAndCompletionStatus()
        }
    }
    
    func validateCardMoveToFreeSpace(_ cardIndexPath:IndexPath, toDestIndexPath destIndexPath:IndexPath)->Bool{
        //if moved card is from other free space
        if (cardIndexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            let pokerCard = cardsOnFreeSpace[(cardIndexPath as NSIndexPath).row]
            cardsOnFreeSpace[(destIndexPath as NSIndexPath).row] = pokerCard
            cardsOnFreeSpace[(cardIndexPath as NSIndexPath).row] = nil
            totalMoveCount += 1
            return true
        }
        //else if moved card is from dealed card stacks
        else{
            //if card moved is the last card the dealed cards stack
            if (cardIndexPath as NSIndexPath).row == (dealedCardStacks[(cardIndexPath as NSIndexPath).section].count - 1){
                let pokerCard = dealedCardStacks[(cardIndexPath as NSIndexPath).section].removeLast()
                cardsOnFreeSpace[(destIndexPath as NSIndexPath).row] = pokerCard
                cardFreeSpaceCount -= 1
                totalMoveCount += 1
                return true
            }
        }
        return false
    }
    
    func validateCardMoveToCompleteStack(_ cardIndexPath:IndexPath, toDestIndexPath destIndexPath:IndexPath)->Bool{
        //if moved card is from a free space
        if (cardIndexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerCard = cardsOnFreeSpace[(cardIndexPath as NSIndexPath).row]{
                //get destinaton stack suit
                if let destStackSuit = getCardCompletedStackSuit((destIndexPath as NSIndexPath).row){
                    //if completeStack contains other cards
                    if cardCompleteStacks[(destIndexPath as NSIndexPath).row].count > 0{
                        if let lastCardInStack = cardCompleteStacks[(destIndexPath as NSIndexPath).row].last{
                            if (pokerCard._cardRank - lastCardInStack._cardRank == 1) && (pokerCard._cardSuit == lastCardInStack._cardSuit){
                                cardCompleteStacks[(destIndexPath as NSIndexPath).row].append(pokerCard)
                                cardsOnFreeSpace[(cardIndexPath as NSIndexPath).row] = nil
                                cardFreeSpaceCount += 1
                                pokerCard._cardIsMoveable = false
                                totalMoveCount += 1
                                return true
                            }
                        }
                    }
                    //else completeStack is empty
                    else{
                        if pokerCard._cardRank == 1 && pokerCard._cardSuit == destStackSuit{
                            cardCompleteStacks[(destIndexPath as NSIndexPath).row].append(pokerCard)
                            cardsOnFreeSpace[(cardIndexPath as NSIndexPath).row] = nil
                            cardFreeSpaceCount += 1
                            pokerCard._cardIsMoveable = false
                            totalMoveCount += 1
                            return true
                        }
                    }
                }
            }
        }
        //else moved card is from dealed card stacks
        else{
            if (cardIndexPath as NSIndexPath).row == dealedCardStacks[(cardIndexPath as NSIndexPath).section].count - 1{
                let pokerCard = dealedCardStacks[(cardIndexPath as NSIndexPath).section][(cardIndexPath as NSIndexPath).row]
                //get destination stack suit
                if let destStackSuit = getCardCompletedStackSuit((destIndexPath as NSIndexPath).row){
                    //if completeStack contains other cards
                    if cardCompleteStacks[(destIndexPath as NSIndexPath).row].count > 0{
                        if let lastCardInStack = cardCompleteStacks[(destIndexPath as NSIndexPath).row].last{
                            if(pokerCard._cardRank - lastCardInStack._cardRank == 1) && (pokerCard._cardSuit == lastCardInStack._cardSuit){
                                cardCompleteStacks[(destIndexPath as NSIndexPath).row].append(pokerCard)
                                dealedCardStacks[(cardIndexPath as NSIndexPath).section].removeLast()
                                pokerCard._cardIsMoveable = false
                                totalMoveCount += 1
                                return true
                            }
                        }
                    }
                    //else completeStack is empty
                    else{
                        if pokerCard._cardRank == 1 && pokerCard._cardSuit == destStackSuit{
                            cardCompleteStacks[(destIndexPath as NSIndexPath).row].append(pokerCard)
                            dealedCardStacks[(cardIndexPath as NSIndexPath).section].removeLast()
                            pokerCard._cardIsMoveable = false
                            totalMoveCount += 1
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func validateCardMoveToOtherStack(_ cardIndexPath:IndexPath, toDestIndexPath destIndexPath:IndexPath)->Bool{
        var cardMoved : PokerCard!
        var cardCount = Int.max
        var cardIsFromFreeSpace = false
        //if moved card is from the free space section
        if (cardIndexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            cardMoved = cardsOnFreeSpace[(cardIndexPath as NSIndexPath).row]
            cardCount = 1
            cardIsFromFreeSpace = true
        }
        //if moved cards is from the dealed card stacks
        else{
            cardMoved = dealedCardStacks[(cardIndexPath as NSIndexPath).section][(cardIndexPath as NSIndexPath).row]
            cardCount = dealedCardStacks[(cardIndexPath as NSIndexPath).section].count - (cardIndexPath as NSIndexPath).row 
        }
        
        //if destination dealed card stack constains other cards
        if let cardDest = dealedCardStacks[(destIndexPath as NSIndexPath).section].last{
            //To be a valid move, moved card needs to be one less the destination card and has a different color suit
            //and alse, moved card count needs to be less or equal to MaxCardsCanMoveCount
            if (cardDest._cardRank - cardMoved._cardRank == 1) && (!cardDest._cardSuit.sameColorWith(cardMoved._cardSuit)) && (cardCount <= getMaxCardsCanMoveCount()){
                //if moved card is from one of the other free space
                if (cardIndexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                    dealedCardStacks[(destIndexPath as NSIndexPath).section].append(cardMoved)
                    cardsOnFreeSpace[(cardIndexPath as NSIndexPath).row] = nil
                }
                //else moved cards are from dealed card stacks
                else{
                    for i in (cardIndexPath as NSIndexPath).row ..< (dealedCardStacks[(cardIndexPath as NSIndexPath).section]).count{
                        let card = dealedCardStacks[(cardIndexPath as NSIndexPath).section][i]
                        dealedCardStacks[(destIndexPath as NSIndexPath).section].append(card)
                    }
                    dealedCardStacks[(cardIndexPath as NSIndexPath).section].removeSubrange((cardIndexPath as NSIndexPath).row ..< (dealedCardStacks[(cardIndexPath as NSIndexPath).section]).count)
                }
                totalMoveCount += 1
                if cardIsFromFreeSpace{
                    cardFreeSpaceCount += 1
                }
                return true
            }
            else if cardCount > getMaxCardsCanMoveCount(){
                errorMessage = NSLocalizedString("AlertWarningMessage1", comment: "AlertWarningMessage1")
                postNotification("needToDisplayErrorMessage")
            }
            else if (!cardDest._cardSuit.sameColorWith(cardMoved._cardSuit)){
                errorMessage = NSLocalizedString("AlertWarningMessage2", comment: "AlertWarningMessage2")
                postNotification("needToDisplayErrorMessage")
            }
        }
        //else destination dealed card stack in empty
        else{
            if (cardCount <= getMaxCardsCanMoveCount()){
                if (cardIndexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                    dealedCardStacks[(destIndexPath as NSIndexPath).section].append(cardMoved)
                    cardsOnFreeSpace[(cardIndexPath as NSIndexPath).row] = nil
                }
                else{
                    for i in (cardIndexPath as NSIndexPath).row ..< (dealedCardStacks[(cardIndexPath as NSIndexPath).section]).count{
                        let card = dealedCardStacks[(cardIndexPath as NSIndexPath).section][i]
                        dealedCardStacks[(destIndexPath as NSIndexPath).section].append(card)
                    }
                    dealedCardStacks[(cardIndexPath as NSIndexPath).section].removeSubrange((cardIndexPath as NSIndexPath).row ..< (dealedCardStacks[(cardIndexPath as NSIndexPath).section]).count )
                }
                totalMoveCount += 1
                if cardIsFromFreeSpace{
                    cardFreeSpaceCount += 1
                }
                return true
            }
        }
        return false
    }
    func processCardMoveableAndCompletionStatus(){
        //print("processCardMoveableAndCompletionStatus")
        for (stackIndex, cardStack) in dealedCardStacks.enumerated(){
            dealedCardStacks[stackIndex].last?._cardIsMoveable = true
            
            //print("\(dealedCardStacks[stackIndex].last)")
            
            for index in stride(from: (cardStack.count - 1), to: -1, by: -1){
                let previousCardIndex = index + 1
                if previousCardIndex < cardStack.count{
                    let previousCard = dealedCardStacks[stackIndex][previousCardIndex]
                    let currentCard = dealedCardStacks[stackIndex][index]
                    
                    if previousCard._cardIsMoveable{
                        if (currentCard._cardRank - previousCard._cardRank == 1) && (!currentCard._cardSuit.sameColorWith(previousCard._cardSuit)){
                            dealedCardStacks[stackIndex][index]._cardIsMoveable = true
                        }
                        else{
                            dealedCardStacks[stackIndex][index]._cardIsMoveable = false
                        }
                    }
                    else{
                        dealedCardStacks[stackIndex][index]._cardIsMoveable = false
                    }
                }
            }
        }
        
        
        if needAutoComplete{
            for (i, _) in dealedCardStacks.enumerated(){
                if let lastCard = dealedCardStacks[i].last{
                    for (j, _) in cardCompleteStacks.enumerated(){
                        if let lastCompleteCard = cardCompleteStacks[j].last{
                            if ((lastCard._cardRank - lastCompleteCard._cardRank) == 1) && (lastCard._cardSuit == lastCompleteCard._cardSuit){
                                cardsToBeAutoComplete.append(CardAutoCompletionInfo.init(_card: lastCard, _indexPath: IndexPath.init(row: dealedCardStacks[i].count - 1, section: i)))
                            }
                        }
                        /*
                        else{
                            if (lastCard._cardRank == 1) && (lastCard._cardSuit == getCardCompletedStackSuit(j)){
                                cardCompleteStacks[j].append(lastCard)
                                dealedCardStacks[i].removeLast()
                                lastCard._cardIsMoveable = false
                                totalMoveCount += 1
                                
                                cardsToBeAutoComplete.append(CardAutoCompletionInfo.init(_card: lastCard, _indexPath: NSIndexPath.init(forRow: dealedCardStacks[i].count, inSection: i)))
                            }
                        }
                        */
                    }
                }
            }
            
        }
        postNotification("processCardMoveableAndCompletionStatus")
    }
    func processAutoCompletedCardFrom(_ dealCardStackIndex: Int, toCompletionStackIndex completionStackIndex:Int ){
        let lastCard = dealedCardStacks[dealCardStackIndex].removeLast()
        cardCompleteStacks[completionStackIndex].append(lastCard)
        lastCard._cardIsMoveable = false
        totalMoveCount += 1
    }
    
    // MARK: - Private func
    fileprivate func getCardCompletedStackSuit(_ index:Int)->CardSuit?{
        switch index {
        case 0:
            return CardSuit.spade
        case 1:
            return CardSuit.heart
        case 2:
            return CardSuit.club
        case 3:
            return CardSuit.diamond
        default:
            return nil
        }
    }
    fileprivate func getMaxCardsCanMoveCount()->Int{
        return cardFreeSpaceCount + 1
    }
    fileprivate func postNotification(_ changeType: String){
        NotificationCenter.default.post(name: Notification.Name(rawValue: CONSTANTS.NOTI_SOLITAIRE_MODEL_CHANGED), object: self, userInfo: ["changeType": changeType])
    }
    fileprivate func drawRandomCardFromStack(_ stack:[PokerCard])->(card:PokerCard, remainingStack:[PokerCard]){
        var stack = stack
        let cardIndex = Int(arc4random_uniform(UInt32.init(stack.count)))
        let card = stack.remove(at: cardIndex)
        return (card, stack)
    }
    fileprivate func generateCardStackWith(_ suit:CardSuit)->[PokerCard]{
        var cardStack = [PokerCard]()
        for rank in 1...13{
            let pokerCard = PokerCard.init(cardRank: rank, cardSuit: suit)
            cardStack.append(pokerCard)
        }
        return cardStack
    }
}












