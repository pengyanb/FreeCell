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
    private var cardSuitsAvailiable = [CardSuit.SPADE, CardSuit.HEART, CardSuit.CLUB, CardSuit.DIAMOND];
    
    private var cardStackOnHold = [PokerCard]()
    var getCardStackOnHold : [PokerCard]{
        get{
            return cardStackOnHold
        }
    }
    
    private var cardDealedStack1 = [PokerCard]()
    private var cardDealedStack2 = [PokerCard]()
    private var cardDealedStack3 = [PokerCard]()
    private var cardDealedStack4 = [PokerCard]()
    private var cardDealedStack5 = [PokerCard]()
    private var cardDealedStack6 = [PokerCard]()
    private var cardDealedStack7 = [PokerCard]()
    private var cardDealedStack8 = [PokerCard]()
    
    lazy var dealedCardStacks : [[PokerCard]] =  { return [self.cardDealedStack1, self.cardDealedStack2, self.cardDealedStack3, self.cardDealedStack4, self.cardDealedStack5, self.cardDealedStack6, self.cardDealedStack7, self.cardDealedStack8]}()
    
    private var totalMoveCount = 0
    var getTotalMoveCount : Int{
        get{
            return totalMoveCount
        }
    }
    
    private(set) var completeStackCount : Int = 0
    
    private var cardFreeSpaceCount = 4
    
    private var cardOnFreeSpace1 : PokerCard?
    private var cardOnFreeSpace2 : PokerCard?
    private var cardOnFreeSpace3 : PokerCard?
    private var cardOnFreeSpace4 : PokerCard?
    private lazy var cardsOnFreeSpace : [PokerCard?] = {
        return [self.cardOnFreeSpace1, self.cardOnFreeSpace2, self.cardOnFreeSpace3, self.cardOnFreeSpace4]
    }()
    
    private var cardCompleteStack1 = [PokerCard]()
    private var cardCompleteStack2 = [PokerCard]()
    private var cardCompleteStack3 = [PokerCard]()
    private var cardCompleteStack4 = [PokerCard]()
    private lazy var cardCompleteStacks : [[PokerCard]] = {
        return [self.cardCompleteStack1, self.cardCompleteStack2, self.cardCompleteStack3, self.cardCompleteStack4]
    }()
    
    var getCardCompleteStacks : [[PokerCard]]{
        get{
            return cardCompleteStacks
        }
    }
    
    private let CARD_FREE_SPACE_INDEXPATH_SECTION = 8
    
    private let CARD_COMPLETE_INDEXPATH_SECTION = 9
    
    var errorMessage = ""
    
    var needAutoComplete = true
    
    var cardsToBeAutoComplete = [CardAutoCompletionInfo] ()
    
    // MARK: - public API
    func startNewGame(){
        cardStackOnHold = [PokerCard]()
        totalMoveCount = 0
        completeStackCount = 0
        for (index, _) in dealedCardStacks.enumerate(){
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
    
    func validateCardMoveToFreeSpace(cardIndexPath:NSIndexPath, toDestIndexPath destIndexPath:NSIndexPath)->Bool{
        //if moved card is from other free space
        if cardIndexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            let pokerCard = cardsOnFreeSpace[cardIndexPath.row]
            cardsOnFreeSpace[destIndexPath.row] = pokerCard
            cardsOnFreeSpace[cardIndexPath.row] = nil
            totalMoveCount += 1
            return true
        }
        //else if moved card is from dealed card stacks
        else{
            //if card moved is the last card the dealed cards stack
            if cardIndexPath.row == (dealedCardStacks[cardIndexPath.section].count - 1){
                let pokerCard = dealedCardStacks[cardIndexPath.section].removeLast()
                cardsOnFreeSpace[destIndexPath.row] = pokerCard
                cardFreeSpaceCount -= 1
                totalMoveCount += 1
                return true
            }
        }
        return false
    }
    
    func validateCardMoveToCompleteStack(cardIndexPath:NSIndexPath, toDestIndexPath destIndexPath:NSIndexPath)->Bool{
        //if moved card is from a free space
        if cardIndexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerCard = cardsOnFreeSpace[cardIndexPath.row]{
                //get destinaton stack suit
                if let destStackSuit = getCardCompletedStackSuit(destIndexPath.row){
                    //if completeStack contains other cards
                    if cardCompleteStacks[destIndexPath.row].count > 0{
                        if let lastCardInStack = cardCompleteStacks[destIndexPath.row].last{
                            if (pokerCard._cardRank - lastCardInStack._cardRank == 1) && (pokerCard._cardSuit == lastCardInStack._cardSuit){
                                cardCompleteStacks[destIndexPath.row].append(pokerCard)
                                cardsOnFreeSpace[cardIndexPath.row] = nil
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
                            cardCompleteStacks[destIndexPath.row].append(pokerCard)
                            cardsOnFreeSpace[cardIndexPath.row] = nil
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
            if cardIndexPath.row == dealedCardStacks[cardIndexPath.section].count - 1{
                let pokerCard = dealedCardStacks[cardIndexPath.section][cardIndexPath.row]
                //get destination stack suit
                if let destStackSuit = getCardCompletedStackSuit(destIndexPath.row){
                    //if completeStack contains other cards
                    if cardCompleteStacks[destIndexPath.row].count > 0{
                        if let lastCardInStack = cardCompleteStacks[destIndexPath.row].last{
                            if(pokerCard._cardRank - lastCardInStack._cardRank == 1) && (pokerCard._cardSuit == lastCardInStack._cardSuit){
                                cardCompleteStacks[destIndexPath.row].append(pokerCard)
                                dealedCardStacks[cardIndexPath.section].removeLast()
                                pokerCard._cardIsMoveable = false
                                totalMoveCount += 1
                                return true
                            }
                        }
                    }
                    //else completeStack is empty
                    else{
                        if pokerCard._cardRank == 1 && pokerCard._cardSuit == destStackSuit{
                            cardCompleteStacks[destIndexPath.row].append(pokerCard)
                            dealedCardStacks[cardIndexPath.section].removeLast()
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
    
    func validateCardMoveToOtherStack(cardIndexPath:NSIndexPath, toDestIndexPath destIndexPath:NSIndexPath)->Bool{
        var cardMoved : PokerCard!
        var cardCount = Int.max
        var cardIsFromFreeSpace = false
        //if moved card is from the free space section
        if cardIndexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            cardMoved = cardsOnFreeSpace[cardIndexPath.row]
            cardCount = 1
            cardIsFromFreeSpace = true
        }
        //if moved cards is from the dealed card stacks
        else{
            cardMoved = dealedCardStacks[cardIndexPath.section][cardIndexPath.row]
            cardCount = dealedCardStacks[cardIndexPath.section].count - cardIndexPath.row 
        }
        
        //if destination dealed card stack constains other cards
        if let cardDest = dealedCardStacks[destIndexPath.section].last{
            //To be a valid move, moved card needs to be one less the destination card and has a different color suit
            //and alse, moved card count needs to be less or equal to MaxCardsCanMoveCount
            if (cardDest._cardRank - cardMoved._cardRank == 1) && (!cardDest._cardSuit.sameColorWith(cardMoved._cardSuit)) && (cardCount <= getMaxCardsCanMoveCount()){
                //if moved card is from one of the other free space
                if cardIndexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                    dealedCardStacks[destIndexPath.section].append(cardMoved)
                    cardsOnFreeSpace[cardIndexPath.row] = nil
                }
                //else moved cards are from dealed card stacks
                else{
                    for i in cardIndexPath.row ..< (dealedCardStacks[cardIndexPath.section]).count{
                        let card = dealedCardStacks[cardIndexPath.section][i]
                        dealedCardStacks[destIndexPath.section].append(card)
                    }
                    dealedCardStacks[cardIndexPath.section].removeRange(cardIndexPath.row ..< (dealedCardStacks[cardIndexPath.section]).count)
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
                if cardIndexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                    dealedCardStacks[destIndexPath.section].append(cardMoved)
                    cardsOnFreeSpace[cardIndexPath.row] = nil
                }
                else{
                    for i in cardIndexPath.row ..< (dealedCardStacks[cardIndexPath.section]).count{
                        let card = dealedCardStacks[cardIndexPath.section][i]
                        dealedCardStacks[destIndexPath.section].append(card)
                    }
                    dealedCardStacks[cardIndexPath.section].removeRange(cardIndexPath.row ..< (dealedCardStacks[cardIndexPath.section]).count )
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
        for (stackIndex, cardStack) in dealedCardStacks.enumerate(){
            dealedCardStacks[stackIndex].last?._cardIsMoveable = true
            
            //print("\(dealedCardStacks[stackIndex].last)")
            
            for index in (cardStack.count - 1).stride(to: -1, by: -1){
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
            for (i, _) in dealedCardStacks.enumerate(){
                if let lastCard = dealedCardStacks[i].last{
                    for (j, _) in cardCompleteStacks.enumerate(){
                        if let lastCompleteCard = cardCompleteStacks[j].last{
                            if ((lastCard._cardRank - lastCompleteCard._cardRank) == 1) && (lastCard._cardSuit == lastCompleteCard._cardSuit){
                                cardsToBeAutoComplete.append(CardAutoCompletionInfo.init(_card: lastCard, _indexPath: NSIndexPath.init(forRow: dealedCardStacks[i].count - 1, inSection: i)))
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
    func processAutoCompletedCardFrom(dealCardStackIndex: Int, toCompletionStackIndex completionStackIndex:Int ){
        let lastCard = dealedCardStacks[dealCardStackIndex].removeLast()
        cardCompleteStacks[completionStackIndex].append(lastCard)
        lastCard._cardIsMoveable = false
        totalMoveCount += 1
    }
    
    // MARK: - Private func
    private func getCardCompletedStackSuit(index:Int)->CardSuit?{
        switch index {
        case 0:
            return CardSuit.SPADE
        case 1:
            return CardSuit.HEART
        case 2:
            return CardSuit.CLUB
        case 3:
            return CardSuit.DIAMOND
        default:
            return nil
        }
    }
    private func getMaxCardsCanMoveCount()->Int{
        return cardFreeSpaceCount + 1
    }
    private func postNotification(changeType: String){
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_SOLITAIRE_MODEL_CHANGED, object: self, userInfo: ["changeType": changeType])
    }
    private func drawRandomCardFromStack(stack:[PokerCard])->(card:PokerCard, remainingStack:[PokerCard]){
        var stack = stack
        let cardIndex = Int(arc4random_uniform(UInt32.init(stack.count)))
        let card = stack.removeAtIndex(cardIndex)
        return (card, stack)
    }
    private func generateCardStackWith(suit:CardSuit)->[PokerCard]{
        var cardStack = [PokerCard]()
        for rank in 1...13{
            let pokerCard = PokerCard.init(cardRank: rank, cardSuit: suit)
            cardStack.append(pokerCard)
        }
        return cardStack
    }
}












