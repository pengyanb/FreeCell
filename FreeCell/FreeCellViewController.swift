//
//  ViewController.swift
//  FreeCell
//
//  Created by Yanbing Peng on 26/05/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit
import AVFoundation
import GoogleMobileAds

class FreeCellViewController: UIViewController {

    // MARK: - Variables
    var gameModel : FreeCellGameModel!
    
    private var dealedCardStack1 = [PokerView]()
    private var dealedCardStack2 = [PokerView]()
    private var dealedCardStack3 = [PokerView]()
    private var dealedCardStack4 = [PokerView]()
    private var dealedCardStack5 = [PokerView]()
    private var dealedCardStack6 = [PokerView]()
    private var dealedCardStack7 = [PokerView]()
    private var dealedCardStack8 = [PokerView]()
    
    private lazy var dealedCardStacks : [[PokerView]] = {
        return [self.dealedCardStack1, self.dealedCardStack2, self.dealedCardStack3, self.dealedCardStack4, self.dealedCardStack5, self.dealedCardStack6, self.dealedCardStack7, self.dealedCardStack8]
    }()
    
    private var movedPokerViewIndexPaths = [NSIndexPath]()
    
    private var dateTimeStart = NSDate()
    
    private var gameTimer = NSTimer.init()
    
    private var currentMovingCardIndexPath : NSIndexPath?
    
    private var dealCardAudioPlayers : [AVAudioPlayer] = [AVAudioPlayer]()
    
    private var gameStarted = false
    
    private let CARD_FREE_SPACE_INDEXPATH_SECTION = 8
    
    private let CARD_COMPLETE_INDEXPATH_SECTION = 9
    
    private var cardOnFreeSpace1 : PokerView?
    private var cardOnFreeSpace2 : PokerView?
    private var cardOnFreeSpace3 : PokerView?
    private var cardOnFreeSpace4 : PokerView?
    private lazy var cardsOnFreeSpace : [PokerView?] = {
        return [self.cardOnFreeSpace1, self.cardOnFreeSpace2, self.cardOnFreeSpace3, self.cardOnFreeSpace4]
    }()
    
    private var cardStacksOnHold : PokerView?
    
    private var cardCompleteStack1 = [PokerView]()
    private var cardCompleteStack2 = [PokerView]()
    private var cardCompleteStack3 = [PokerView]()
    private var cardCompleteStack4 = [PokerView]()
    private lazy var cardCompleteStacks : [[PokerView]] = {
        return [self.cardCompleteStack1, self.cardCompleteStack2, self.cardCompleteStack3, self.cardCompleteStack4]
    }()
    
    var winAudioPlayer : AVAudioPlayer?
    
    var dealedCardCount = 0
    
    let tutorialMessages = [NSLocalizedString("AlertTutorialMessage1", comment: "AlertTutorialMessage1"), NSLocalizedString("AlertTutorialMessage2", comment: "AlertTutorialMessage2"), NSLocalizedString("AlertTutorialMessage3", comment: "AlertTutorialMessage3"), NSLocalizedString("AlertTutorialMessage4", comment: "AlertTutorialMessage4"), NSLocalizedString("AlertTutorialMessage5", comment: "AlertTutorialMessage5"), NSLocalizedString("AlertTutorialMessage6", comment: "AlertTutorialMessage6")]
    var tutorialMessageIndex = 0
    
    // MARK: - Outlets
    @IBOutlet weak var cardStacksOnHoldPlaceHolder: UIView!
    @IBOutlet var cardStacksDealedPlaceHolders: [PokerView]!
    @IBOutlet var cardFreeSpacePlaceHolders: [PokerView]!
    @IBOutlet var cardStackCompletedPlaceHolders: [PokerView]!
    
    @IBOutlet weak var newGameButton: UIBarButtonItem!
    
    @IBOutlet weak var adBannerView: GADBannerView!
    
    // MARK: - Target Actions
    @IBAction func newGameButtonPressed(sender: UIBarButtonItem) {
        newGameButton.enabled = false
        startNewGame()
    }
    
    // MARK: - Notification related
    private func registerNotifications(){
        let notiCenter = NSNotificationCenter.defaultCenter()
        notiCenter.addObserver(self, selector: #selector(handleModelNotification(_:)), name: CONSTANTS.NOTI_SOLITAIRE_MODEL_CHANGED, object: nil)
        notiCenter.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
        notiCenter.addObserver(self, selector: #selector(handleApplicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    private func deregisterNotifications(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    func handleApplicationWillResignActive(notification:NSNotification){
        if gameStarted{
            gameTimer.invalidate()
            let nowTime = NSDate()
            let timeUsedSoFar = Int.init(nowTime.timeIntervalSinceDate(dateTimeStart)) + NSUserDefaults.standardUserDefaults().integerForKey(CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
            NSUserDefaults.standardUserDefaults().setInteger(timeUsedSoFar, forKey: CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    func handleApplicationWillEnterForeground(notification:NSNotification){
        if gameStarted{
            dateTimeStart = NSDate()
            gameTimer.invalidate()
            gameTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: NSBlockOperation(block: {[weak self] in
                    self?.updateTitle()
                }), selector: #selector(NSOperation.main), userInfo: nil, repeats: true)
        }
    }
    func handleModelNotification(notification:NSNotification){
        if let userInfo = notification.userInfo{
            if let changeType = userInfo["changeType"] as? String{
                dispatch_async(dispatch_get_main_queue(), {[weak self] in
                    switch changeType{
                        case "cardStackOnHoldCreated":
                            self?.handleCardStackOnHoldCreate()
                        case "cardStacksDealed":
                            self?.handleDealCardStacks()
                        case "processCardMoveableAndCompletionStatus":
                            self?.handleCardMoveableAndCompletionStatus()
                        case "needToDisplayErrorMessage":
                            UIAlertView.init(title: "Alert", message: self?.gameModel.errorMessage, delegate: nil, cancelButtonTitle: "OK").show()
                        default:break
                    }
                })
            }
        }
    }
    
    // MARK: - Private func
    private func showTutorial(needAnimation:Bool){
        let alert = UIAlertController.init(title: NSLocalizedString("AlertTutorialTitle", comment: "AlertTutorialTitle"), message: tutorialMessages[tutorialMessageIndex], preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertTutorialBackButton", comment: "AlertTutorialBackButton"), style: UIAlertActionStyle.Default, handler: { [weak self](alertAction) in
            if self?.tutorialMessageIndex > 0{
                self?.tutorialMessageIndex -= 1
                alert.dismissViewControllerAnimated(false, completion: nil)
                self?.showTutorial(false)
            }
        }))
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertTutorialNextButton", comment: "AlertTutorialNextButton"), style: UIAlertActionStyle.Default, handler: {[weak self] (alertAction) in
            if self?.tutorialMessageIndex < 5{
                self?.tutorialMessageIndex += 1
                alert.dismissViewControllerAnimated(false, completion: nil)
                self?.showTutorial(false)
            }
        }))
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertTutorialCloseButton", comment: "AlertTutorialCloseButton"), style: UIAlertActionStyle.Default, handler: { (alertAction) in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertTutorialNotShowAgainButton", comment: "AlertTutorialNotShowAgainButton"), style: UIAlertActionStyle.Cancel, handler: { (alertAction) in
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: CONSTANTS.NSUSER_DEFAULTS_NOT_SHOW_TUTORIAL_KEY)
            NSUserDefaults.standardUserDefaults().synchronize()
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: needAnimation, completion: nil)
    }
    
    private func getCardFreeSpacePlaceHolderByIndex(index:Int)->PokerView?{
        for pokerView in cardFreeSpacePlaceHolders{
            if pokerView.tag == index{
                return pokerView
            }
        }
        return nil
    }
    private func getCardStackCompletedPlaceHolderByIndex(index:Int)->PokerView?{
        for pokerView in cardStackCompletedPlaceHolders{
            if pokerView.tag == index{
                return pokerView
            }
        }
        return nil
    }
    
    private func startNewGame(){
        NSUserDefaults.standardUserDefaults().setInteger(0, forKey: CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
        
        currentMovingCardIndexPath = nil
        
        for (i, _) in dealedCardStacks.enumerate() {
            for (j, _) in dealedCardStacks[i].enumerate(){
                //print("\(dealedCardStacks[i][j])")
                (dealedCardStacks[i][j]).removeFromSuperview()
            }
            dealedCardStacks[i].removeAll()
        }

        for i in 0..<4{
            cardsOnFreeSpace[i]?.removeFromSuperview()
            cardsOnFreeSpace[i] = nil
        }
        for i in 0..<4{
            for j in 0..<cardCompleteStacks[i].count{
                (cardCompleteStacks[i][j]).removeFromSuperview()
            }
            cardCompleteStacks[i].removeAll()
        }

        cardStacksOnHold?.removeFromSuperview()
        cardStacksOnHold = nil
        
        dealedCardCount = 0
        
        gameModel.startNewGame()
        gameTimer.invalidate()
        gameStarted = true
        
        self.title = "[\(NSLocalizedString("PageTitleMove", comment: "PageTitleMove"))] 0\t[\(NSLocalizedString("PageTitleTime", comment: "PageTitleTime"))] 00:00"
    }
    
    private func updateTitle(){
        let previousUsedTime = NSUserDefaults.standardUserDefaults().integerForKey(CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
        let currentDateTime = NSDate()
        let timeInterval = Int.init(currentDateTime.timeIntervalSinceDate(dateTimeStart)) + previousUsedTime
        let second = timeInterval % 60
        let minute = ((timeInterval - second) % 3600) / 60
        let hour = (timeInterval - minute * 60 - second) / 3600
        
        self.title = "[\(NSLocalizedString("PageTitleMove", comment: "PageTitleMove"))] \(String.init(format: "%d", gameModel.getTotalMoveCount))\t[\(NSLocalizedString("PageTitleTime", comment: "PageTitleTime"))] \(hour > 0 ? "\(String.init(format: "%02d:", hour))" : "")\(String.init(format: "%02d", minute)):\(String.init(format: "%02d", second))"
        
        gameTimer.invalidate()
        gameTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: NSBlockOperation(block: {[weak self] in
            self?.updateTitle()
            }), selector: #selector(NSOperation.main), userInfo: nil, repeats: true)
    }
    
    private func handleDealCardStacks(){
        var animationDelay : NSTimeInterval = 0
        //for (i, _) in gameModel.dealedCardStacks.enumerate(){
        for rowNumber in 0 ..< 7{
            for i in 0 ..< 8{
                let modelDealedCardStack = gameModel.dealedCardStacks[i]
                //print("\(modelDealedCardStack)")
                let viewDealedCardStack = dealedCardStacks[i]
                if rowNumber < modelDealedCardStack.count {
                    let modelDealedCard = modelDealedCardStack[rowNumber]
                    var placeHolder : UIView? = nil
                    for _placeHolder in cardStacksDealedPlaceHolders{
                        if _placeHolder.tag == i{
                            placeHolder = _placeHolder
                        }
                    }
                    
                    if let cardStackPlaceHolder = placeHolder{
                        var pokerViewDestFrame = cardStackPlaceHolder.frame
                        let downShiftOffset = round(CGFloat.init(pokerViewDestFrame.size.height * 0.2 * CGFloat(viewDealedCardStack.count)) )
                        pokerViewDestFrame = CGRectIntegral( CGRectMake(pokerViewDestFrame.origin.x, pokerViewDestFrame.origin.y + downShiftOffset, pokerViewDestFrame.size.width, pokerViewDestFrame.size.height))
                        let pokerViewOriginFrame = cardStacksOnHoldPlaceHolder.frame
                        
                        let pokerView = PokerView.init(frame: pokerViewOriginFrame)
                        pokerView.pokerImageName = modelDealedCard._cardImageName
                        pokerView.pokerIsFacingUp = false
                        pokerView.viewIsPokerCard = true
                        
                        let pokerViewIndexPath = NSIndexPath.init(forRow: dealedCardStacks[i].count, inSection: i)
                        pokerView.pokerViewIndexPath = pokerViewIndexPath
                        pokerView.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + CGFloat.init(pokerViewIndexPath.row)
                        
                        pokerView.viewMoveDelegate = self
                        self.view.addSubview(pokerView)
                        self.view.bringSubviewToFront(pokerView)
                        dealedCardStacks[i].append(pokerView)
                        
                        UIView.animateWithDuration(0.1, delay: animationDelay, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                            pokerView.frame = pokerViewDestFrame
                            }, completion: {[weak self] (complete) in
                                self?.playDealCardSound()
                                self?.dealedCardCount += 1
                                pokerView.pokerIsFacingUp = modelDealedCard._cardIsFacingUp
                                
                                if self?.dealedCardCount >= 52{
                                    self?.newGameButton.enabled = true
                                    self?.cardStacksOnHold?.removeFromSuperview()
                                    self?.cardStacksOnHold = nil
                                    
                                    self?.dateTimeStart = NSDate()
                                    self?.updateTitle()
                                    self?.gameTimer.invalidate()
                                    self?.gameTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: NSBlockOperation(block: {[weak self] in
                                            self?.updateTitle()
                                        }), selector: #selector(NSOperation.main), userInfo: nil, repeats: true)
                                }
                                //!! todo
                            }
                        )
                        

                        animationDelay += 0.1
                    }
                }
            }
        }
    }
    
    private func handleCardMoveableAndCompletionStatus(){
        for (i, modelStack) in gameModel.dealedCardStacks.enumerate(){
            for (j, modelCard) in modelStack.enumerate(){
                (dealedCardStacks[i][j]).clearViewOffset()
                (dealedCardStacks[i][j]).pokerIsFacingUp = modelCard._cardIsFacingUp
                (dealedCardStacks[i][j]).pokerIsMoveable = modelCard._cardIsMoveable
            }
        }
        if gameModel.cardsToBeAutoComplete.count > 0{
            var animationDelay : Double = 0

            for cardInfo in gameModel.cardsToBeAutoComplete{
                let pokerView = dealedCardStacks[cardInfo.indexPath.section].removeLast()
                let toCompleteStackIndex = getCardCompletionStackIndexBySuit(cardInfo.card._cardSuit)
                if let placeHolder = getCardStackCompletedPlaceHolderByIndex(toCompleteStackIndex){
                    UIView.animateWithDuration(0.2, delay: animationDelay, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                        pokerView.center = placeHolder.center
                        }, completion: {[weak self] (complete) in  self?.playDealCardSound()})
                }
                pokerView.pokerViewIndexPath = NSIndexPath.init(forRow: toCompleteStackIndex, inSection: CARD_COMPLETE_INDEXPATH_SECTION)
                pokerView.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + CGFloat.init(cardCompleteStacks[toCompleteStackIndex].count)
                cardCompleteStacks[toCompleteStackIndex].append(pokerView)
                self.view.bringSubviewToFront(pokerView)
                pokerView.clearOriginal()
                pokerView.pokerIsMoveable = false
                animationDelay += 0.2
                gameModel.processAutoCompletedCardFrom(cardInfo.indexPath.section, toCompletionStackIndex: toCompleteStackIndex)
            }
            updateTitle()
            gameModel.cardsToBeAutoComplete.removeAll()
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(animationDelay * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue(), { [weak self] in
                self?.gameModel.processCardMoveableAndCompletionStatus()
            })
            
        }
        else{
            checkIfGameIsCompleted()
        }
    }
    private func getCardCompletionStackIndexBySuit(suit: CardSuit)->Int{
        switch suit {
        case .SPADE:
            return 0
        case .HEART:
            return 1
        case .CLUB:
            return 2
        case .DIAMOND:
            return 3
        }
    }
    private func checkIfGameIsCompleted(){
        var gameDone = true
        for completeStack in gameModel.getCardCompleteStacks{
            if completeStack.last?._cardRank != 13{
                gameDone = false
                break
            }
        }
        if gameDone{
            NSUserDefaults.standardUserDefaults().setInteger(0, forKey: CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
            UIAlertView.init(title: NSLocalizedString("AlertWinTitle", comment: "AlertWinTitle"), message: NSLocalizedString("AlertWinMessage", comment: "AlertWinMessage"), delegate: nil, cancelButtonTitle: NSLocalizedString("AlertWinCancelButton", comment: "AlertWinCancelButton")).show()
            gameTimer.invalidate()
            gameStarted = false
            winAudioPlayer?.play()
            
            var animationStartDelay : Double = 0
            var animatedCardCount = 0
            newGameButton.enabled = false
            print("[CompletedStacks]: \(cardCompleteStacks)")
            for (i,  _) in cardCompleteStacks.enumerate(){
                for (j, card) in cardCompleteStacks[i].enumerate(){
                    let cardIndex = NSIndexPath.init(forRow: j, inSection: i)
                    UIView.animateWithDuration(0.1, delay: animationStartDelay, options: UIViewAnimationOptions.CurveEaseInOut, animations: { [weak self] in
                        if let center = self?.cardStacksOnHoldPlaceHolder.center{
                            card.center = center
                        }
                        }, completion: {[weak self] (done) in
                            if self?.cardStacksOnHold == nil{
                                if let wSelf = self{
                                    wSelf.cardStacksOnHold = PokerView.init(frame: wSelf.cardStacksOnHoldPlaceHolder.frame)
                                    wSelf.cardStacksOnHold?.pokerImageName = "PokerBack"
                                    wSelf.cardStacksOnHold?.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + 100
                                    wSelf.view.addSubview(wSelf.cardStacksOnHold!)
                                    wSelf.view.bringSubviewToFront(wSelf.cardStacksOnHold!)
                                }
                            }
                            print("removeCompletedCardAt: \(cardIndex)")
                            card.removeFromSuperview()
                            
                            animatedCardCount += 1
                            self?.playDealCardSound()
                            if animatedCardCount >= 51{
                                self?.newGameButton.enabled = true
                                
                            }
                        })
                    animationStartDelay += 0.1
                }
                cardCompleteStacks[i].removeAll()
            }
            
        }
    }
    
    private func playDealCardSound(){
        let needPlaySound = !NSUserDefaults.standardUserDefaults().boolForKey(CONSTANTS.NSUSER_DEFAULTS_NO_SOUND_EFFECTS_KEY)
        if needPlaySound{
            var availablePlayer : AVAudioPlayer? = nil
            for player in dealCardAudioPlayers{
                if player.playing == false{
                    availablePlayer = player
                    break
                }
            }
            
            if availablePlayer == nil{
                do{
                    if let soundFileUrl = NSBundle.mainBundle().pathForResource("cardPlace1", ofType: "wav"){
                        try availablePlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: soundFileUrl))
                        availablePlayer?.prepareToPlay()
                        availablePlayer?.numberOfLoops = 0
                        dealCardAudioPlayers.append(availablePlayer!)
                    }
                }
                catch{
                    print(error)
                }
            }
            if let player = availablePlayer{
                player.play()
            }
        }
    }
    
    // MARK: - Model Noti Handlers
    private func handleCardStackOnHoldCreate(){
        print(gameModel.getCardStackOnHold)
        cardStacksOnHold = PokerView.init(frame: cardStacksOnHoldPlaceHolder.frame)
        cardStacksOnHold?.pokerImageName = "PokerBack"
        cardStacksOnHold?.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + 100
        self.view.addSubview(cardStacksOnHold!)
        self.view.bringSubviewToFront(cardStacksOnHold!)
        gameModel.dealCardStacks()
    }
    
    // MARK: - View left cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "[\(NSLocalizedString("PageTitleMove", comment: "PageTitleMove"))] 0\t[\(NSLocalizedString("PageTitleTime", comment: "PageTitleTime"))] 00:00"
        
        gameModel = FreeCellGameModel()
        
        self.adBannerView.adUnitID = "ca-app-pub-3199275288482759/8642595027"
        self.adBannerView.rootViewController = self
        self.adBannerView.loadRequest(GADRequest.init())
        
        do{
            if let soundFileUrl = NSBundle.mainBundle().pathForResource("taDa", ofType: "wav"){
                try winAudioPlayer = AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: soundFileUrl))
                winAudioPlayer?.prepareToPlay()
            }
        }
        catch{
            print(error)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerNotifications()
        let notShowTutorial = NSUserDefaults.standardUserDefaults().boolForKey(CONSTANTS.NSUSER_DEFAULTS_NOT_SHOW_TUTORIAL_KEY)
        if !notShowTutorial{
            showTutorial(true)
        }
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterNotifications()
    }
}


// MARK: - PokerViewMoveDelegate
extension FreeCellViewController : PokerViewMoveDelegate{
    func handlePokerCardTap(atIndexPath indexPath: NSIndexPath) {
        // For cards on Free space
        if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION || indexPath == CARD_COMPLETE_INDEXPATH_SECTION{
            return
        }
        
        // For cards on Dealed Stacks
        playDealCardSound()
        let offsetState = (dealedCardStacks[indexPath.section][indexPath.row]).viewIsOffsetted
        for (i, cardStack) in dealedCardStacks.enumerate(){
            for (j, _) in cardStack.enumerate(){
                if indexPath.section == i{
                    if j >= indexPath.row{
                        if dealedCardStacks[i][j].pokerIsFacingUp{
                            dealedCardStacks[i][j].viewIsOffsetted = !offsetState
                        }
                    }
                    else{
                        dealedCardStacks[i][j].viewIsOffsetted = false
                    }
                }
                else{
                    dealedCardStacks[i][j].viewIsOffsetted = false
                }
            }
        }
    }
    
    func handleUnmoveableViewPanGesture(atIndexPath indexPath: NSIndexPath, panGesture: UIPanGestureRecognizer) {
        // For cards on Free space
        if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION || indexPath.section == CARD_COMPLETE_INDEXPATH_SECTION{
            return
        }
        //// For cards on Dealed Stacks
        for (_, cardView) in dealedCardStacks[indexPath.section].enumerate(){
            if cardView.pokerIsMoveable{
                cardView.panGestureRecognized(panGesture)
                break
            }
        }
    }
    
    func handlePokerViewMoveBegan(atIndexPath indexPath: NSIndexPath) {
        if currentMovingCardIndexPath != nil{
            if currentMovingCardIndexPath != indexPath{
                return
            }
        }
        else{
            currentMovingCardIndexPath = indexPath
        }
        
        movedPokerViewIndexPaths = [NSIndexPath]()
        // For cards on Free space
        if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerView = cardsOnFreeSpace[indexPath.row]{
                movedPokerViewIndexPaths.append(indexPath)
                pokerView.handleViewMoveBegan()
            }
            return
        }
        
        // For cards on Dealed stacks
        if indexPath.row  < dealedCardStacks[indexPath.section].count{
            for index in indexPath.row ..< dealedCardStacks[indexPath.section].count{
                movedPokerViewIndexPaths.append(NSIndexPath.init(forRow: index, inSection: indexPath.section))
                let pokerView = dealedCardStacks[indexPath.section][index]
                pokerView.handleViewMoveBegan()
            }
        }
    }
    
    func handlePokerViewMoveChanged(atIndexPath moveIndexPath: NSIndexPath, translation: CGPoint) {
        if currentMovingCardIndexPath != nil{
            if currentMovingCardIndexPath != moveIndexPath{
                return
            }
        }
        
        // For cards on Free space
        if moveIndexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerView = cardsOnFreeSpace[moveIndexPath.row]{
                pokerView.handleViewMoveChanged(translation)
            }
            return
        }
        // For cards on Dealed stacks
        for indexPath in movedPokerViewIndexPaths{
            let pokerView = dealedCardStacks[indexPath.section][indexPath.row]
            pokerView.handleViewMoveChanged(translation)
        }
    }
    
    func handlePokerViewMoveCancelled(atIndexPath moveIndexPath: NSIndexPath) {
        if currentMovingCardIndexPath != nil{
            if currentMovingCardIndexPath != moveIndexPath{
                return
            }
            else{
                currentMovingCardIndexPath = nil
            }
        }
        
        // For cards on Free space
        if moveIndexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerView = cardsOnFreeSpace[moveIndexPath.row]{
                pokerView.handleViewMoveCancelled()
            }
            return
        }
        // For cards on Dealed Card Stack
        for indexPath in movedPokerViewIndexPaths{
            let pokerView  = dealedCardStacks[indexPath.section][indexPath.row]
            pokerView.handleViewMoveCancelled()
        }
    }
    func handlePokerViewMoveFailed(atIndexPath moveIndexPath: NSIndexPath) {
        if currentMovingCardIndexPath != nil{
            if currentMovingCardIndexPath != moveIndexPath{
                return
            }
            else{
                currentMovingCardIndexPath = nil
            }
        }
        // For cards on Free space
        if moveIndexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerView = cardsOnFreeSpace[moveIndexPath.row]{
                pokerView.handleViewMoveFailed()
            }
            return
        }
        // For cards on Dealed Card Stack
        for indexPath in movedPokerViewIndexPaths{
            let pokerView  = dealedCardStacks[indexPath.section][indexPath.row]
            pokerView.handleViewMoveFailed()
        }
    }
    func handlePokerViewMoveEnd(atIndexPath moveIndexPath: NSIndexPath) {
        print("[moveEndAtIndexPath]: \(moveIndexPath)")
        if currentMovingCardIndexPath != nil{
            if currentMovingCardIndexPath != moveIndexPath{
                return
            }
            else{
                currentMovingCardIndexPath = nil
            }
        }
        playDealCardSound()
        
        //reset all card offsets
        /*
        for (i, _) in dealedCardStacks.enumerate(){
            for (j, _) in dealedCardStacks[i].enumerate(){
                (dealedCardStacks[i][j]).viewIsOffsetted = false
            }
        }*/
        
        //get the top moved card indexPath
        if let indexPath = movedPokerViewIndexPaths.first{
            var movedPokerPosition = CGPointZero
            
            // get the card move ending position
            if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{ //if card is from free space
                movedPokerPosition = (cardsOnFreeSpace[indexPath.row])!.center
            }
            else{                                           //else card is from the dealed stacks
                movedPokerPosition = (dealedCardStacks[indexPath.section][indexPath.row]).center
            }
            
            var targetIndexPath : NSIndexPath? = nil
            var targetView : PokerView? = nil
            var initialOffset : CGFloat = 1
            
            var toFreeSpaceIndex = -1
            
            var toCompleteStackIndex = -1
            
            //check if moved cards endup at one of the complete stacks
            for completeStackHolder in cardStackCompletedPlaceHolders{
                let tag = completeStackHolder.tag
                if CGRectContainsPoint(completeStackHolder.frame, movedPokerPosition){
                    toCompleteStackIndex = tag
                    break
                }
            }
            
            //check if moved cards endup at one of the free spaces
            for freeSpaceHolder in cardFreeSpacePlaceHolders{
                let tag = freeSpaceHolder.tag
                if CGRectContainsPoint(freeSpaceHolder.frame, movedPokerPosition){
                    if cardsOnFreeSpace[tag] == nil{
                        toFreeSpaceIndex = tag
                    }
                    break
                }
            }
            
            //check if moved cards endup at one of the dealed card stacks
            for (i, stack) in dealedCardStacks.enumerate(){
                if i == indexPath.section{
                    continue
                }
                if let lastPokerView = stack.last{ //if there are still cards on th dealed card stack, then get the last card view
                    let cardHolderView = cardStacksDealedPlaceHolders[i]
                    if CGRectContainsPoint(CGRectMake(cardHolderView.frame.origin.x, cardHolderView.frame.origin.y, cardHolderView.frame.size.width, self.view.bounds.height), movedPokerPosition){
                        targetView = lastPokerView
                        initialOffset = 1
                        targetIndexPath = targetView?.pokerViewIndexPath
                        break
                    }
                }
                else{                               //else if there is no more card on the dealed card stack, then get the stack placeholder view
                    let cardHolderView = cardStacksDealedPlaceHolders[i]
                    if CGRectContainsPoint(CGRectMake(cardHolderView.frame.origin.x, cardHolderView.frame.origin.y, cardHolderView.frame.size.width, self.view.bounds.height), movedPokerPosition){
                        targetView = cardHolderView
                        initialOffset = 0
                        targetIndexPath = NSIndexPath.init(forRow: 0, inSection: i)
                        break
                    }
                }
            }
            
            
            //if moved card endup to one of the dealed card stacks
            if let destIndexPath = targetIndexPath, destView = targetView{
                //if moved card indexPath.section is same as destination indexPath.section, then reset the moved cards to original place
                if indexPath.section == destIndexPath.section{
                    for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                        (dealedCardStacks[movedPokerViewIndexPath.section][movedPokerViewIndexPath.row]).resetToOriginal()
                    }
                }
                //else if moved card endup at a new different indexPath.section
                else{
                    //if card move to other dealed stack is NOT a valid move
                    if !gameModel.validateCardMoveToOtherStack(indexPath, toDestIndexPath: destIndexPath){
                        //if moved card is from one of the free space, then reset it back the original position
                        if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                            cardsOnFreeSpace[indexPath.row]?.resetToOriginal()
                        }
                        //else if moved cards is from one of the dealed card stacks
                        else{
                            for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                                (dealedCardStacks[movedPokerViewIndexPath.section][movedPokerViewIndexPath.row]).resetToOriginal()
                            }
                        }
                    }
                    //else if card move to other dealed stack is valid
                    else{
                        let downShiftOffset = round(CGFloat.init(destView.frame.size.height * 0.2)) //the down shift distances of each card is 0.2 of its height
                        var zPosIncrement : CGFloat = 1
                        
                        //if moved card is from one of the free space
                        if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                            if let pokerView = cardsOnFreeSpace[indexPath.row]{
                                dealedCardStacks[destIndexPath.section].append(pokerView)
                                pokerView.center = CGPoint.init(x: destView.center.x, y: destView.center.y + downShiftOffset * (initialOffset))
                                if initialOffset == 0{ //if dealed card stack is empty
                                    pokerView.pokerViewIndexPath = NSIndexPath.init(forRow: 0, inSection: destIndexPath.section)
                                }
                                else{   //else dealed card stack is not empty
                                    pokerView.pokerViewIndexPath = NSIndexPath.init(forRow: destIndexPath.row + 1, inSection: destIndexPath.section)
                                }
                                pokerView.layer.zPosition = destView.layer.zPosition + zPosIncrement
                                self.view.bringSubviewToFront(pokerView)
                                pokerView.clearOriginal()
                                cardsOnFreeSpace[indexPath.row] = nil
                            }
                        }
                        else{
                            for i in indexPath.row ..< (dealedCardStacks[indexPath.section]).count{
                                let pokerView = dealedCardStacks[indexPath.section][i]
                                dealedCardStacks[destIndexPath.section].append(pokerView)
                                pokerView.center = CGPoint.init(x: destView.center.x, y: destView.center.y + downShiftOffset * (CGFloat.init(i - indexPath.row) + initialOffset) )
                                pokerView.pokerViewIndexPath = NSIndexPath.init(forRow: destIndexPath.row + (i - indexPath.row) + Int(initialOffset), inSection: destIndexPath.section)
                                pokerView.layer.zPosition = destView.layer.zPosition + zPosIncrement
                                zPosIncrement += 1
                                self.view.bringSubviewToFront(pokerView)
                                pokerView.clearOriginal()
                            }
                            dealedCardStacks[indexPath.section].removeRange(indexPath.row ..< (dealedCardStacks[indexPath.section]).count )
                        }
                        updateTitle()
                        gameModel.processCardMoveableAndCompletionStatus()
                    }
                }
            }
            //else if moved card end up to one of the completed stacks
            else if toCompleteStackIndex >= 0{
                let movedCardCount = movedPokerViewIndexPaths.count //get the total moved card count
                if movedCardCount == 1{
                    var pokerView : PokerView!
                    //if this moved card is from free space
                    if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                        pokerView = cardsOnFreeSpace[indexPath.row]
                    }
                    //else if moved card is from one of the dealed card stacks
                    else{
                        pokerView = dealedCardStacks[indexPath.section][indexPath.row]
                    }
                    
                    //if card move to complete stack is NOT valid, then reset it to the original position
                    if !gameModel.validateCardMoveToCompleteStack(indexPath, toDestIndexPath: NSIndexPath.init(forRow: toCompleteStackIndex, inSection: CARD_COMPLETE_INDEXPATH_SECTION)){
                        pokerView.resetToOriginal()
                    }
                    //else card move to complete stack is valid
                    else{
                        if let placeHolder = getCardStackCompletedPlaceHolderByIndex(toCompleteStackIndex){
                            pokerView.center = placeHolder.center //align moved card to complete stack
                        }
                        pokerView.pokerViewIndexPath = NSIndexPath.init(forRow: toCompleteStackIndex, inSection: CARD_COMPLETE_INDEXPATH_SECTION)
                        pokerView.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + CGFloat.init(cardCompleteStacks[toCompleteStackIndex].count)
                        cardCompleteStacks[toCompleteStackIndex].append(pokerView)
                        self.view.bringSubviewToFront(pokerView)
                        //if moved card is from one of other free space
                        if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                            cardsOnFreeSpace[indexPath.row] = nil
                        }
                            //if moved card is from one of the dealed card stacks
                        else{
                            dealedCardStacks[indexPath.section].removeLast()
                        }
                        //clear the remembered previous position
                        pokerView.clearOriginal()
                        pokerView.pokerIsMoveable = false
                        updateTitle()
                        gameModel.processCardMoveableAndCompletionStatus()
                    }
                }
                else{ //more than 1 card moved, they can only come from the dealed card stacks
                    for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                        (dealedCardStacks[movedPokerViewIndexPath.section][movedPokerViewIndexPath.row]).resetToOriginal()
                    }
                }
            }
            //else if moved card endup to one of the free space
            else if toFreeSpaceIndex >= 0{
                let movedCardCount = movedPokerViewIndexPaths.count //get the total moved card count
                //if only one card is moved [only one card can be moved to free space at each time]
                if movedCardCount == 1{
                    var pokerView : PokerView!
                    //if this moved card is from other free space
                    if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                        pokerView = cardsOnFreeSpace[indexPath.row]
                    }
                    //else if moved card is from one of the dealed card stacks
                    else{
                        pokerView = dealedCardStacks[indexPath.section][indexPath.row]
                    }
                    
                    //if card move to free space is NOT valid, then reset it to the orignal position
                    if !gameModel.validateCardMoveToFreeSpace(indexPath, toDestIndexPath: NSIndexPath.init(forRow: toFreeSpaceIndex, inSection: CARD_FREE_SPACE_INDEXPATH_SECTION)){
                        pokerView.resetToOriginal()
                    }
                    //else card move to free space is valid
                    else{
                        if let placeHolder = getCardFreeSpacePlaceHolderByIndex(toFreeSpaceIndex){
                            pokerView.center = placeHolder.center //align moved card to free space
                        }
                        pokerView.pokerViewIndexPath = NSIndexPath.init(forRow: toFreeSpaceIndex, inSection: CARD_FREE_SPACE_INDEXPATH_SECTION) //set the moved card's new indexPath
                        pokerView.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + 1
                        cardsOnFreeSpace[toFreeSpaceIndex] = pokerView //put this moved card to cardsOnFreeSpace array
                        self.view.bringSubviewToFront(pokerView)
                        //if moved card is from one of other free space
                        if indexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                            cardsOnFreeSpace[indexPath.row] = nil
                        }
                        //if moved card is from one of the dealed card stacks
                        else{
                            dealedCardStacks[indexPath.section].removeLast()
                        }
                        //clear the remembered previous position
                        pokerView.clearOriginal()
                        updateTitle()
                        gameModel.processCardMoveableAndCompletionStatus()
                    }
                }
                //else more than 1 card are moved to a free space, then reset them to the original positions
                else{
                    for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                        (dealedCardStacks[movedPokerViewIndexPath.section][movedPokerViewIndexPath.row]).resetToOriginal()
                    }
                }
            }
            //else moved card endup at outside the are of interests, the rest the card to the original place
            else{
                for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                    if movedPokerViewIndexPath.section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                        cardsOnFreeSpace[movedPokerViewIndexPath.row]?.resetToOriginal()
                    }
                    else{
                        (dealedCardStacks[movedPokerViewIndexPath.section][movedPokerViewIndexPath.row]).resetToOriginal()
                    }
                }
            }
        }
    }
}






















