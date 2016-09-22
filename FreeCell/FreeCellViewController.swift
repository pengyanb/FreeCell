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
import GameKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class FreeCellViewController: UIViewController {

    // MARK: - Variables
    var gameModel : FreeCellGameModel!
    
    fileprivate var dealedCardStack1 = [PokerView]()
    fileprivate var dealedCardStack2 = [PokerView]()
    fileprivate var dealedCardStack3 = [PokerView]()
    fileprivate var dealedCardStack4 = [PokerView]()
    fileprivate var dealedCardStack5 = [PokerView]()
    fileprivate var dealedCardStack6 = [PokerView]()
    fileprivate var dealedCardStack7 = [PokerView]()
    fileprivate var dealedCardStack8 = [PokerView]()
    
    fileprivate lazy var dealedCardStacks : [[PokerView]] = {
        return [self.dealedCardStack1, self.dealedCardStack2, self.dealedCardStack3, self.dealedCardStack4, self.dealedCardStack5, self.dealedCardStack6, self.dealedCardStack7, self.dealedCardStack8]
    }()
    
    fileprivate var movedPokerViewIndexPaths = [IndexPath]()
    
    fileprivate var dateTimeStart = Date()
    
    fileprivate var gameTimer = Timer.init()
    
    fileprivate var currentMovingCardIndexPath : IndexPath?
    
    fileprivate var dealCardAudioPlayers : [AVAudioPlayer] = [AVAudioPlayer]()
    
    fileprivate var gameStarted = false
    
    fileprivate let CARD_FREE_SPACE_INDEXPATH_SECTION = 8
    
    fileprivate let CARD_COMPLETE_INDEXPATH_SECTION = 9
    
    fileprivate var cardOnFreeSpace1 : PokerView?
    fileprivate var cardOnFreeSpace2 : PokerView?
    fileprivate var cardOnFreeSpace3 : PokerView?
    fileprivate var cardOnFreeSpace4 : PokerView?
    fileprivate lazy var cardsOnFreeSpace : [PokerView?] = {
        return [self.cardOnFreeSpace1, self.cardOnFreeSpace2, self.cardOnFreeSpace3, self.cardOnFreeSpace4]
    }()
    
    fileprivate var cardStacksOnHold : PokerView?
    
    fileprivate var cardCompleteStack1 = [PokerView]()
    fileprivate var cardCompleteStack2 = [PokerView]()
    fileprivate var cardCompleteStack3 = [PokerView]()
    fileprivate var cardCompleteStack4 = [PokerView]()
    fileprivate lazy var cardCompleteStacks : [[PokerView]] = {
        return [self.cardCompleteStack1, self.cardCompleteStack2, self.cardCompleteStack3, self.cardCompleteStack4]
    }()
    
    var winAudioPlayer : AVAudioPlayer?
    
    var dealedCardCount = 0
    
    let tutorialMessages = [NSLocalizedString("AlertTutorialMessage1", comment: "AlertTutorialMessage1"), NSLocalizedString("AlertTutorialMessage2", comment: "AlertTutorialMessage2"), NSLocalizedString("AlertTutorialMessage3", comment: "AlertTutorialMessage3"), NSLocalizedString("AlertTutorialMessage4", comment: "AlertTutorialMessage4"), NSLocalizedString("AlertTutorialMessage5", comment: "AlertTutorialMessage5"), NSLocalizedString("AlertTutorialMessage6", comment: "AlertTutorialMessage6")]
    var tutorialMessageIndex = 0
    
    var gameCenterEnabled = false
    var gameCenterLeaderboardIdentifier : String? = nil
    // MARK: - Outlets
    @IBOutlet weak var cardStacksOnHoldPlaceHolder: UIView!
    @IBOutlet var cardStacksDealedPlaceHolders: [PokerView]!
    @IBOutlet var cardFreeSpacePlaceHolders: [PokerView]!
    @IBOutlet var cardStackCompletedPlaceHolders: [PokerView]!
    
    @IBOutlet weak var newGameButton: UIBarButtonItem!
    
    @IBOutlet weak var undoButton: UIBarButtonItem!
    
    @IBOutlet weak var adBannerView: GADBannerView!
    
    // MARK: - Target Actions
    @IBAction func newGameButtonPressed(_ sender: UIBarButtonItem) {
        if gameModel.getTotalMoveCount > 0 && gameStarted{
            let alert = UIAlertController.init(title: NSLocalizedString("AlertNewGameTitle", comment: "AlertNewGameTitle"), message: NSLocalizedString("AlertNewGameMessage", comment: "AlertNewGameMessage"), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertNewGameRestartButton", comment: "AlertNewGameRestartButton"), style: UIAlertActionStyle.destructive, handler: {[weak self] (alertAction) in
                self?.newGameButton.isEnabled = false
                self?.startNewGame()
            }))
            alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertNewGameCancelButton", comment: "AlertNewGameCancelButton"), style: UIAlertActionStyle.cancel, handler: { (alertAction) in
                alert.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true, completion: nil)
        }
        else{
            newGameButton.isEnabled = false
            startNewGame()
        }
    }
    
    @IBAction func undoButtonPressed(_ sender: UIBarButtonItem) {
        
    }
    // MARK: - Notification related
    fileprivate func registerNotifications(){
        let notiCenter = NotificationCenter.default
        notiCenter.addObserver(self, selector: #selector(handleModelNotification(_:)), name: NSNotification.Name(rawValue: CONSTANTS.NOTI_SOLITAIRE_MODEL_CHANGED), object: nil)
        notiCenter.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        notiCenter.addObserver(self, selector: #selector(handleApplicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    fileprivate func deregisterNotifications(){
        NotificationCenter.default.removeObserver(self)
    }
    func handleApplicationWillResignActive(_ notification:Notification){
        if gameStarted{
            gameTimer.invalidate()
            let nowTime = Date()
            let timeUsedSoFar = Int.init(nowTime.timeIntervalSince(dateTimeStart)) + UserDefaults.standard.integer(forKey: CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
            UserDefaults.standard.set(timeUsedSoFar, forKey: CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
            UserDefaults.standard.synchronize()
        }
    }
    func handleApplicationWillEnterForeground(_ notification:Notification){
        if gameStarted{
            dateTimeStart = Date()
            gameTimer.invalidate()
            gameTimer = Timer.scheduledTimer(timeInterval: 1, target: BlockOperation(block: {[weak self] in
                    self?.updateTitle()
                }), selector: #selector(Operation.main), userInfo: nil, repeats: true)
        }
    }
    func handleModelNotification(_ notification:Notification){
        if let userInfo = (notification as NSNotification).userInfo{
            if let changeType = userInfo["changeType"] as? String{
                DispatchQueue.main.async(execute: {[weak self] in
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
    fileprivate func showTutorial(_ needAnimation:Bool){
        let alert = UIAlertController.init(title: NSLocalizedString("AlertTutorialTitle", comment: "AlertTutorialTitle"), message: tutorialMessages[tutorialMessageIndex], preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertTutorialBackButton", comment: "AlertTutorialBackButton"), style: UIAlertActionStyle.default, handler: { [weak self](alertAction) in
            if self?.tutorialMessageIndex > 0{
                self?.tutorialMessageIndex -= 1
                alert.dismiss(animated: false, completion: nil)
                self?.showTutorial(false)
            }
        }))
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertTutorialNextButton", comment: "AlertTutorialNextButton"), style: UIAlertActionStyle.default, handler: {[weak self] (alertAction) in
            if self?.tutorialMessageIndex < 5{
                self?.tutorialMessageIndex += 1
                alert.dismiss(animated: false, completion: nil)
                self?.showTutorial(false)
            }
        }))
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertTutorialCloseButton", comment: "AlertTutorialCloseButton"), style: UIAlertActionStyle.default, handler: { (alertAction) in
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("AlertTutorialNotShowAgainButton", comment: "AlertTutorialNotShowAgainButton"), style: UIAlertActionStyle.cancel, handler: { (alertAction) in
            UserDefaults.standard.set(true, forKey: CONSTANTS.NSUSER_DEFAULTS_NOT_SHOW_TUTORIAL_KEY)
            UserDefaults.standard.synchronize()
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: needAnimation, completion: nil)
    }
    
    fileprivate func getCardFreeSpacePlaceHolderByIndex(_ index:Int)->PokerView?{
        for pokerView in cardFreeSpacePlaceHolders{
            if pokerView.tag == index{
                return pokerView
            }
        }
        return nil
    }
    fileprivate func getCardStackCompletedPlaceHolderByIndex(_ index:Int)->PokerView?{
        for pokerView in cardStackCompletedPlaceHolders{
            if pokerView.tag == index{
                return pokerView
            }
        }
        return nil
    }
    
    fileprivate func startNewGame(){
        UserDefaults.standard.set(0, forKey: CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
        
        currentMovingCardIndexPath = nil
        
        for (i, _) in dealedCardStacks.enumerated() {
            for (j, _) in dealedCardStacks[i].enumerated(){
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
    
    fileprivate func updateTitle(){
        let previousUsedTime = UserDefaults.standard.integer(forKey: CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
        let currentDateTime = Date()
        let timeInterval = Int.init(currentDateTime.timeIntervalSince(dateTimeStart)) + previousUsedTime
        let second = timeInterval % 60
        let minute = ((timeInterval - second) % 3600) / 60
        let hour = (timeInterval - minute * 60 - second) / 3600
        
        self.title = "[\(NSLocalizedString("PageTitleMove", comment: "PageTitleMove"))] \(String.init(format: "%d", gameModel.getTotalMoveCount))\t[\(NSLocalizedString("PageTitleTime", comment: "PageTitleTime"))] \(hour > 0 ? "\(String.init(format: "%02d:", hour))" : "")\(String.init(format: "%02d", minute)):\(String.init(format: "%02d", second))"
        
        gameTimer.invalidate()
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: BlockOperation(block: {[weak self] in
            self?.updateTitle()
            }), selector: #selector(Operation.main), userInfo: nil, repeats: true)
    }
    
    fileprivate func handleDealCardStacks(){
        var animationDelay : TimeInterval = 0
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
                        pokerViewDestFrame = CGRect(x: pokerViewDestFrame.origin.x, y: pokerViewDestFrame.origin.y + downShiftOffset, width: pokerViewDestFrame.size.width, height: pokerViewDestFrame.size.height).integral
                        let pokerViewOriginFrame = cardStacksOnHoldPlaceHolder.frame
                        
                        let pokerView = PokerView.init(frame: pokerViewOriginFrame)
                        pokerView.pokerImageName = modelDealedCard._cardImageName
                        pokerView.pokerIsFacingUp = false
                        pokerView.viewIsPokerCard = true
                        
                        let pokerViewIndexPath = IndexPath.init(row: dealedCardStacks[i].count, section: i)
                        pokerView.pokerViewIndexPath = pokerViewIndexPath
                        pokerView.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + CGFloat.init((pokerViewIndexPath as NSIndexPath).row)
                        
                        pokerView.viewMoveDelegate = self
                        self.view.addSubview(pokerView)
                        self.view.bringSubview(toFront: pokerView)
                        dealedCardStacks[i].append(pokerView)
                        
                        UIView.animate(withDuration: 0.1, delay: animationDelay, options: UIViewAnimationOptions(), animations: {
                            pokerView.frame = pokerViewDestFrame
                            }, completion: {[weak self] (complete) in
                                self?.playDealCardSound()
                                self?.dealedCardCount += 1
                                pokerView.pokerIsFacingUp = modelDealedCard._cardIsFacingUp
                                
                                if self?.dealedCardCount >= 52{
                                    self?.newGameButton.isEnabled = true
                                    self?.cardStacksOnHold?.removeFromSuperview()
                                    self?.cardStacksOnHold = nil
                                    
                                    self?.dateTimeStart = Date()
                                    self?.updateTitle()
                                    self?.gameTimer.invalidate()
                                    self?.gameTimer = Timer.scheduledTimer(timeInterval: 1, target: BlockOperation(block: {[weak self] in
                                            self?.updateTitle()
                                        }), selector: #selector(Operation.main), userInfo: nil, repeats: true)
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
    
    fileprivate func handleCardMoveableAndCompletionStatus(){
        for (i, modelStack) in gameModel.dealedCardStacks.enumerated(){
            for (j, modelCard) in modelStack.enumerated(){
                //(dealedCardStacks[i][j]).clearViewOffset()
                (dealedCardStacks[i][j]).viewIsOffsetted = false
                (dealedCardStacks[i][j]).pokerIsFacingUp = modelCard._cardIsFacingUp
                (dealedCardStacks[i][j]).pokerIsMoveable = modelCard._cardIsMoveable
            }
        }
        if gameModel.cardsToBeAutoComplete.count > 0{
            var animationDelay : Double = 0

            for cardInfo in gameModel.cardsToBeAutoComplete{
                let pokerView = dealedCardStacks[(cardInfo.indexPath as NSIndexPath).section].removeLast()
                let toCompleteStackIndex = getCardCompletionStackIndexBySuit(cardInfo.card._cardSuit)
                if let placeHolder = getCardStackCompletedPlaceHolderByIndex(toCompleteStackIndex){
                    UIView.animate(withDuration: 0.2, delay: animationDelay, options: UIViewAnimationOptions(), animations: {
                        pokerView.center = placeHolder.center
                        }, completion: {[weak self] (complete) in  self?.playDealCardSound()})
                }
                pokerView.pokerViewIndexPath = IndexPath.init(row: toCompleteStackIndex, section: CARD_COMPLETE_INDEXPATH_SECTION)
                pokerView.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + CGFloat.init(cardCompleteStacks[toCompleteStackIndex].count)
                cardCompleteStacks[toCompleteStackIndex].append(pokerView)
                self.view.bringSubview(toFront: pokerView)
                pokerView.clearOriginal()
                pokerView.clearViewOffset()
                pokerView.pokerIsMoveable = false
                animationDelay += 0.2
                gameModel.processAutoCompletedCardFrom((cardInfo.indexPath as NSIndexPath).section, toCompletionStackIndex: toCompleteStackIndex)
            }
            updateTitle()
            gameModel.cardsToBeAutoComplete.removeAll()
            let delayTime = DispatchTime.now() + Double(Int64(animationDelay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime, execute: { [weak self] in
                self?.gameModel.processCardMoveableAndCompletionStatus()
            })
            
        }
        else{
            checkIfGameIsCompleted()
        }
    }
    fileprivate func getCardCompletionStackIndexBySuit(_ suit: CardSuit)->Int{
        switch suit {
        case .spade:
            return 0
        case .heart:
            return 1
        case .club:
            return 2
        case .diamond:
            return 3
        }
    }
    fileprivate func checkIfGameIsCompleted(){
        var gameDone = true
        for completeStack in gameModel.getCardCompleteStacks{
            if completeStack.last?._cardRank != 13{
                gameDone = false
                break
            }
        }
        if gameDone{

            let currentDate = Date()
            let moveCount = gameModel.getTotalMoveCount
            let timeUsed = Int.init(currentDate.timeIntervalSince(dateTimeStart)) + UserDefaults.standard.integer(forKey: CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
            let overallPlayedTime = UserDefaults.standard.integer(forKey: CONSTANTS.NSUSER_DEFAULTS_OVERALL_TIME_KEY) + timeUsed
            let currentScoreInfo = ["moveCount":moveCount, "timeUsed":timeUsed, "completeTime":currentDate, "isLatest":true] as [String : Any]
            var topTenScores = [[String:AnyObject]]()
            if let savedTopTenScores = UserDefaults.standard.object(forKey: CONSTANTS.NSUSER_DEFAULTS_TOP_TEN_SCORE_KEY) as? [[String:AnyObject]]{
                topTenScores = savedTopTenScores
            }
            
            var indexToInsert = 0
            for (i, _) in topTenScores.enumerated(){
                topTenScores[i]["isLatest"] = false as AnyObject?
            }
            for (i, scoreInfo) in topTenScores.enumerated(){
                if timeUsed < (scoreInfo["timeUsed"] as! Int){
                    indexToInsert = i
                    break
                }
                else if timeUsed == (scoreInfo["timeUsed"] as! Int){
                    if moveCount <= (scoreInfo["moveCount"] as! Int){
                        indexToInsert = i
                        break
                    }
                }
                indexToInsert += 1
            }
    
            if indexToInsert < 10{
                topTenScores.insert(currentScoreInfo as [String : AnyObject], at: indexToInsert)
                if indexToInsert == 0{
                    submitTopScoreToGameCenter(timeUsed)
                }
            }
            else{
                topTenScores.insert(currentScoreInfo as [String : AnyObject], at: 10)
            }
            if topTenScores.count > 11{
                topTenScores = Array( topTenScores.dropLast(topTenScores.count - 11) )
            }
            UserDefaults.standard.set(topTenScores, forKey: CONSTANTS.NSUSER_DEFAULTS_TOP_TEN_SCORE_KEY)
            UserDefaults.standard.set(overallPlayedTime, forKey: CONSTANTS.NSUSER_DEFAULTS_OVERALL_TIME_KEY)
            UserDefaults.standard.set( (UserDefaults.standard.integer(forKey: CONSTANTS.NSUSER_DEFAULTS_OVERALL_ROUND_COMPLETED_KEY) + 1), forKey: CONSTANTS.NSUSER_DEFAULTS_OVERALL_ROUND_COMPLETED_KEY)
            UserDefaults.standard.synchronize()
            //print("Top 10 Results: \(topTenScores)")
            
            UserDefaults.standard.set(0, forKey: CONSTANTS.NSUSER_DEFAULTS_TIME_ELLAPSED_KEY)
            let alertController =  UIAlertController(title: NSLocalizedString("AlertWinTitle", comment: "AlertWinTitle"), message: NSLocalizedString("AlertWinMessage", comment: "AlertWinMessage"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("AlertWinCancelButton", comment: "AlertWinCancelButton"), style: .default , handler: {[weak self] (action) in
                    if indexToInsert == 0{
                        self?.showLeaderboard()
                    }else{
                        self?.performSegue(withIdentifier: "showTopScoreSegue", sender: self)
                    }
                })
            )
            self.present(alertController, animated: true, completion: nil)

            gameTimer.invalidate()
            gameStarted = false
            winAudioPlayer?.play()
            
            var animationStartDelay : Double = 0
            var animatedCardCount = 0
            newGameButton.isEnabled = false
            //print("[CompletedStacks]: \(cardCompleteStacks)")
            for (i,  _) in cardCompleteStacks.enumerated(){
                for (_, card) in cardCompleteStacks[i].enumerated(){
                    //let cardIndex = NSIndexPath.init(forRow: j, inSection: i)
                    UIView.animate(withDuration: 0.1, delay: animationStartDelay, options: UIViewAnimationOptions(), animations: { [weak self] in
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
                                    wSelf.view.bringSubview(toFront: wSelf.cardStacksOnHold!)
                                }
                            }
                            //print("removeCompletedCardAt: \(cardIndex)")
                            card.removeFromSuperview()
                            
                            animatedCardCount += 1
                            self?.playDealCardSound()
                            if animatedCardCount >= 51{
                                self?.newGameButton.isEnabled = true
                                
                            }
                        })
                    animationStartDelay += 0.1
                }
                cardCompleteStacks[i].removeAll()
            }
            
        }
    }
    
    fileprivate func playDealCardSound(){
        let needPlaySound = !UserDefaults.standard.bool(forKey: CONSTANTS.NSUSER_DEFAULTS_NO_SOUND_EFFECTS_KEY)
        if needPlaySound{
            var availablePlayer : AVAudioPlayer? = nil
            for player in dealCardAudioPlayers{
                if player.isPlaying == false{
                    availablePlayer = player
                    break
                }
            }
            
            if availablePlayer == nil{
                do{
                    if let soundFileUrl = Bundle.main.path(forResource: "cardPlace1", ofType: "wav"){
                        try availablePlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: soundFileUrl))
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
    fileprivate func handleCardStackOnHoldCreate(){
        print(gameModel.getCardStackOnHold)
        cardStacksOnHold = PokerView.init(frame: cardStacksOnHoldPlaceHolder.frame)
        cardStacksOnHold?.pokerImageName = "PokerBack"
        cardStacksOnHold?.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + 100
        self.view.addSubview(cardStacksOnHold!)
        self.view.bringSubview(toFront: cardStacksOnHold!)
        gameModel.dealCardStacks()
    }
    
    // MARK: - View left cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticateLocalPlayer()
        self.title = "[\(NSLocalizedString("PageTitleMove", comment: "PageTitleMove"))] 0\t[\(NSLocalizedString("PageTitleTime", comment: "PageTitleTime"))] 00:00"
        
        gameModel = FreeCellGameModel()
        

        
        do{
            if let soundFileUrl = Bundle.main.path(forResource: "taDa", ofType: "wav"){
                try winAudioPlayer = AVAudioPlayer(contentsOf: URL(fileURLWithPath: soundFileUrl))
                winAudioPlayer?.prepareToPlay()
            }
        }
        catch{
            print(error)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerNotifications()
        let notShowTutorial = UserDefaults.standard.bool(forKey: CONSTANTS.NSUSER_DEFAULTS_NOT_SHOW_TUTORIAL_KEY)
        if !notShowTutorial{
            showTutorial(true)
        }
        gameModel.needAutoComplete = !UserDefaults.standard.bool(forKey: CONSTANTS.NSUSER_DEFAULTS_NOT_AUTO_COMPLETE_KEY)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterNotifications()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVc = segue.destination as? OptionsViewController{
            if let popoverVc = destVc.popoverPresentationController{
                popoverVc.delegate = self
            }
        }
    }
}

// MARK: - Extension GKGameCenterControllerDelegate
extension FreeCellViewController : GKGameCenterControllerDelegate{
    func authenticateLocalPlayer(){
        let localPlayer : GKLocalPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {[weak self] (viewController ,error)->Void in
            if viewController != nil{
                self?.present(viewController!, animated: true, completion: nil)
            }
            else if (localPlayer.isAuthenticated){
                self?.gameCenterEnabled = true
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifier, error) in
                    guard error == nil else{
                        print(error)
                        return
                    }
                    self?.gameCenterLeaderboardIdentifier = leaderboardIdentifier
                })
            }
            else{
                self?.gameCenterEnabled = false
            }
        }
    }
    
    func submitTopScoreToGameCenter(_ score:Int){
        if let gkLeaderboardIdentifier = gameCenterLeaderboardIdentifier{
            let gkScore = GKScore(leaderboardIdentifier: gkLeaderboardIdentifier)
            gkScore.value = Int64(score)
            let gkScoreArray  = [gkScore]
            GKScore.report(gkScoreArray, withCompletionHandler: { (error) in
                if error != nil{
                    print("\(error)")
                }
            })
         }
    }
    
    func showLeaderboard(){
        let gameCenterViewController = GKGameCenterViewController()
        gameCenterViewController.gameCenterDelegate = self
        self.present(gameCenterViewController, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Extension UIPopoverPresentationControllerDelegate
extension FreeCellViewController : UIPopoverPresentationControllerDelegate{
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        //print("popoverPresentationControllerDidDismissPopover")
        gameModel.needAutoComplete = !UserDefaults.standard.bool(forKey: CONSTANTS.NSUSER_DEFAULTS_NOT_AUTO_COMPLETE_KEY)
        if let presentedVc = popoverPresentationController.presentedViewController as? OptionsViewController{
            if presentedVc.needShowTopScores{
                performSegue(withIdentifier: "showTopScoreSegue", sender: self)
            }
        }
    }
}

// MARK: - Extension PokerViewMoveDelegate
extension FreeCellViewController : PokerViewMoveDelegate{
    func handlePokerCardTap(atIndexPath indexPath: IndexPath) {
        // For cards on Free space
        if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION || (indexPath as NSIndexPath).section == CARD_COMPLETE_INDEXPATH_SECTION{
            return
        }
        
        // For cards on Dealed Stacks
        playDealCardSound()
        let offsetState = (dealedCardStacks[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]).viewIsOffsetted
        for (i, cardStack) in dealedCardStacks.enumerated(){
            for (j, _) in cardStack.enumerated(){
                if (indexPath as NSIndexPath).section == i{
                    if j >= (indexPath as NSIndexPath).row{
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
    
    func handleUnmoveableViewPanGesture(atIndexPath indexPath: IndexPath, panGesture: UIPanGestureRecognizer) {
        // For cards on Free space
        if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION || (indexPath as NSIndexPath).section == CARD_COMPLETE_INDEXPATH_SECTION{
            return
        }
        //// For cards on Dealed Stacks
        for (_, cardView) in dealedCardStacks[(indexPath as NSIndexPath).section].enumerated(){
            if cardView.pokerIsMoveable{
                cardView.panGestureRecognized(panGesture)
                break
            }
        }
    }
    
    func handlePokerViewMoveBegan(atIndexPath indexPath: IndexPath) {
        if currentMovingCardIndexPath != nil{
            if currentMovingCardIndexPath != indexPath{
                return
            }
        }
        else{
            currentMovingCardIndexPath = indexPath
        }
        
        movedPokerViewIndexPaths = [IndexPath]()
        // For cards on Free space
        if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerView = cardsOnFreeSpace[(indexPath as NSIndexPath).row]{
                movedPokerViewIndexPaths.append(indexPath)
                pokerView.handleViewMoveBegan()
            }
            return
        }
        
        // For cards on Dealed stacks
        if (indexPath as NSIndexPath).row  < dealedCardStacks[(indexPath as NSIndexPath).section].count{
            for index in (indexPath as NSIndexPath).row ..< dealedCardStacks[(indexPath as NSIndexPath).section].count{
                movedPokerViewIndexPaths.append(IndexPath.init(row: index, section: (indexPath as NSIndexPath).section))
                let pokerView = dealedCardStacks[(indexPath as NSIndexPath).section][index]
                pokerView.handleViewMoveBegan()
            }
        }
    }
    
    func handlePokerViewMoveChanged(atIndexPath moveIndexPath: IndexPath, translation: CGPoint) {
        if currentMovingCardIndexPath != nil{
            if currentMovingCardIndexPath != moveIndexPath{
                return
            }
        }
        
        // For cards on Free space
        if (moveIndexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerView = cardsOnFreeSpace[(moveIndexPath as NSIndexPath).row]{
                pokerView.handleViewMoveChanged(translation)
            }
            return
        }
        // For cards on Dealed stacks
        for indexPath in movedPokerViewIndexPaths{
            let pokerView = dealedCardStacks[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            pokerView.handleViewMoveChanged(translation)
        }
    }
    
    func handlePokerViewMoveCancelled(atIndexPath moveIndexPath: IndexPath) {
        if currentMovingCardIndexPath != nil{
            if currentMovingCardIndexPath != moveIndexPath{
                return
            }
            else{
                currentMovingCardIndexPath = nil
            }
        }
        
        // For cards on Free space
        if (moveIndexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerView = cardsOnFreeSpace[(moveIndexPath as NSIndexPath).row]{
                pokerView.handleViewMoveCancelled()
            }
            return
        }
        // For cards on Dealed Card Stack
        for indexPath in movedPokerViewIndexPaths{
            let pokerView  = dealedCardStacks[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            pokerView.handleViewMoveCancelled()
        }
    }
    func handlePokerViewMoveFailed(atIndexPath moveIndexPath: IndexPath) {
        if currentMovingCardIndexPath != nil{
            if currentMovingCardIndexPath != moveIndexPath{
                return
            }
            else{
                currentMovingCardIndexPath = nil
            }
        }
        // For cards on Free space
        if (moveIndexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
            if let pokerView = cardsOnFreeSpace[(moveIndexPath as NSIndexPath).row]{
                pokerView.handleViewMoveFailed()
            }
            return
        }
        // For cards on Dealed Card Stack
        for indexPath in movedPokerViewIndexPaths{
            let pokerView  = dealedCardStacks[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            pokerView.handleViewMoveFailed()
        }
    }
    func handlePokerViewMoveEnd(atIndexPath moveIndexPath: IndexPath) {
        //print("[moveEndAtIndexPath]: \(moveIndexPath)")
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
            var movedPokerPosition = CGPoint.zero
            
            // get the card move ending position
            if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{ //if card is from free space
                movedPokerPosition = (cardsOnFreeSpace[(indexPath as NSIndexPath).row])!.center
            }
            else{                                           //else card is from the dealed stacks
                movedPokerPosition = (dealedCardStacks[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]).center
            }
            
            var targetIndexPath : IndexPath? = nil
            var targetView : PokerView? = nil
            var initialOffset : CGFloat = 1
            
            var toFreeSpaceIndex = -1
            
            var toCompleteStackIndex = -1
            
            //check if moved cards endup at one of the complete stacks
            for completeStackHolder in cardStackCompletedPlaceHolders{
                let tag = completeStackHolder.tag
                if completeStackHolder.frame.contains(movedPokerPosition){
                    toCompleteStackIndex = tag
                    break
                }
            }
            
            //check if moved cards endup at one of the free spaces
            for freeSpaceHolder in cardFreeSpacePlaceHolders{
                let tag = freeSpaceHolder.tag
                if freeSpaceHolder.frame.contains(movedPokerPosition){
                    if cardsOnFreeSpace[tag] == nil{
                        toFreeSpaceIndex = tag
                    }
                    break
                }
            }
            
            //check if moved cards endup at one of the dealed card stacks
            for (i, stack) in dealedCardStacks.enumerated(){
                if i == (indexPath as NSIndexPath).section{
                    continue
                }
                if let lastPokerView = stack.last{ //if there are still cards on th dealed card stack, then get the last card view
                    let cardHolderView = cardStacksDealedPlaceHolders[i]
                    if CGRect(x: cardHolderView.frame.origin.x, y: cardHolderView.frame.origin.y, width: cardHolderView.frame.size.width, height: self.view.bounds.height).contains(movedPokerPosition){
                        targetView = lastPokerView
                        initialOffset = 1
                        targetIndexPath = targetView?.pokerViewIndexPath as IndexPath?
                        break
                    }
                }
                else{                               //else if there is no more card on the dealed card stack, then get the stack placeholder view
                    let cardHolderView = cardStacksDealedPlaceHolders[i]
                    if CGRect(x: cardHolderView.frame.origin.x, y: cardHolderView.frame.origin.y, width: cardHolderView.frame.size.width, height: self.view.bounds.height).contains(movedPokerPosition){
                        targetView = cardHolderView
                        initialOffset = 0
                        targetIndexPath = IndexPath.init(row: 0, section: i)
                        break
                    }
                }
            }
            
            
            //if moved card endup to one of the dealed card stacks
            if let destIndexPath = targetIndexPath, let destView = targetView{
                //if moved card indexPath.section is same as destination indexPath.section, then reset the moved cards to original place
                if (indexPath as NSIndexPath).section == (destIndexPath as NSIndexPath).section{
                    for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                        (dealedCardStacks[(movedPokerViewIndexPath as NSIndexPath).section][(movedPokerViewIndexPath as NSIndexPath).row]).resetToOriginal()
                    }
                }
                //else if moved card endup at a new different indexPath.section
                else{
                    //if card move to other dealed stack is NOT a valid move
                    if !gameModel.validateCardMoveToOtherStack(indexPath, toDestIndexPath: destIndexPath){
                        //if moved card is from one of the free space, then reset it back the original position
                        if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                            cardsOnFreeSpace[(indexPath as NSIndexPath).row]?.resetToOriginal()
                        }
                        //else if moved cards is from one of the dealed card stacks
                        else{
                            for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                                (dealedCardStacks[(movedPokerViewIndexPath as NSIndexPath).section][(movedPokerViewIndexPath as NSIndexPath).row]).resetToOriginal()
                            }
                        }
                    }
                    //else if card move to other dealed stack is valid
                    else{
                        let downShiftOffset = round(CGFloat.init(destView.frame.size.height * 0.2)) //the down shift distances of each card is 0.2 of its height
                        var zPosIncrement : CGFloat = 1
                        
                        //if moved card is from one of the free space
                        if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                            if let pokerView = cardsOnFreeSpace[(indexPath as NSIndexPath).row]{
                                dealedCardStacks[(destIndexPath as NSIndexPath).section].append(pokerView)
                                pokerView.center = CGPoint.init(x: destView.center.x, y: destView.center.y + downShiftOffset * (initialOffset))
                                if initialOffset == 0{ //if dealed card stack is empty
                                    pokerView.pokerViewIndexPath = IndexPath.init(row: 0, section: (destIndexPath as NSIndexPath).section)
                                }
                                else{   //else dealed card stack is not empty
                                    pokerView.pokerViewIndexPath = IndexPath.init(row: (destIndexPath as NSIndexPath).row + 1, section: (destIndexPath as NSIndexPath).section)
                                }
                                pokerView.layer.zPosition = destView.layer.zPosition + zPosIncrement
                                self.view.bringSubview(toFront: pokerView)
                                pokerView.clearOriginal()
                                pokerView.clearViewOffset()
                                cardsOnFreeSpace[(indexPath as NSIndexPath).row] = nil
                            }
                        }
                        else{
                            for i in (indexPath as NSIndexPath).row ..< (dealedCardStacks[(indexPath as NSIndexPath).section]).count{
                                let pokerView = dealedCardStacks[(indexPath as NSIndexPath).section][i]
                                dealedCardStacks[(destIndexPath as NSIndexPath).section].append(pokerView)
                                pokerView.center = CGPoint.init(x: destView.center.x, y: destView.center.y + downShiftOffset * (CGFloat.init(i - (indexPath as NSIndexPath).row) + initialOffset) )
                                pokerView.pokerViewIndexPath = IndexPath.init(row: (destIndexPath as NSIndexPath).row + (i - (indexPath as NSIndexPath).row) + Int(initialOffset), section: (destIndexPath as NSIndexPath).section)
                                pokerView.layer.zPosition = destView.layer.zPosition + zPosIncrement
                                zPosIncrement += 1
                                self.view.bringSubview(toFront: pokerView)
                                pokerView.clearOriginal()
                                pokerView.clearViewOffset()
                            }
                            dealedCardStacks[(indexPath as NSIndexPath).section].removeSubrange((indexPath as NSIndexPath).row ..< (dealedCardStacks[(indexPath as NSIndexPath).section]).count )
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
                    if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                        pokerView = cardsOnFreeSpace[(indexPath as NSIndexPath).row]
                    }
                    //else if moved card is from one of the dealed card stacks
                    else{
                        pokerView = dealedCardStacks[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
                    }
                    
                    //if card move to complete stack is NOT valid, then reset it to the original position
                    if !gameModel.validateCardMoveToCompleteStack(indexPath, toDestIndexPath: IndexPath.init(row: toCompleteStackIndex, section: CARD_COMPLETE_INDEXPATH_SECTION)){
                        pokerView.resetToOriginal()
                    }
                    //else card move to complete stack is valid
                    else{
                        if let placeHolder = getCardStackCompletedPlaceHolderByIndex(toCompleteStackIndex){
                            pokerView.center = placeHolder.center //align moved card to complete stack
                        }
                        pokerView.pokerViewIndexPath = IndexPath.init(row: toCompleteStackIndex, section: CARD_COMPLETE_INDEXPATH_SECTION)
                        pokerView.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + CGFloat.init(cardCompleteStacks[toCompleteStackIndex].count)
                        cardCompleteStacks[toCompleteStackIndex].append(pokerView)
                        self.view.bringSubview(toFront: pokerView)
                        //if moved card is from one of other free space
                        if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                            cardsOnFreeSpace[(indexPath as NSIndexPath).row] = nil
                        }
                            //if moved card is from one of the dealed card stacks
                        else{
                            dealedCardStacks[(indexPath as NSIndexPath).section].removeLast()
                        }
                        //clear the remembered previous position
                        pokerView.clearOriginal()
                        pokerView.clearViewOffset()
                        pokerView.pokerIsMoveable = false
                        updateTitle()
                        gameModel.processCardMoveableAndCompletionStatus()
                    }
                }
                else{ //more than 1 card moved, they can only come from the dealed card stacks
                    for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                        (dealedCardStacks[(movedPokerViewIndexPath as NSIndexPath).section][(movedPokerViewIndexPath as NSIndexPath).row]).resetToOriginal()
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
                    if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                        pokerView = cardsOnFreeSpace[(indexPath as NSIndexPath).row]
                    }
                    //else if moved card is from one of the dealed card stacks
                    else{
                        pokerView = dealedCardStacks[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
                    }
                    
                    //if card move to free space is NOT valid, then reset it to the orignal position
                    if !gameModel.validateCardMoveToFreeSpace(indexPath, toDestIndexPath: IndexPath.init(row: toFreeSpaceIndex, section: CARD_FREE_SPACE_INDEXPATH_SECTION)){
                        pokerView.resetToOriginal()
                    }
                    //else card move to free space is valid
                    else{
                        if let placeHolder = getCardFreeSpacePlaceHolderByIndex(toFreeSpaceIndex){
                            pokerView.center = placeHolder.center //align moved card to free space
                        }
                        pokerView.pokerViewIndexPath = IndexPath.init(row: toFreeSpaceIndex, section: CARD_FREE_SPACE_INDEXPATH_SECTION) //set the moved card's new indexPath
                        pokerView.layer.zPosition = CONSTANTS.CONST_POKER_VIEW_Z_POSITION_BASE_VALUE + 1
                        cardsOnFreeSpace[toFreeSpaceIndex] = pokerView //put this moved card to cardsOnFreeSpace array
                        self.view.bringSubview(toFront: pokerView)
                        //if moved card is from one of other free space
                        if (indexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                            cardsOnFreeSpace[(indexPath as NSIndexPath).row] = nil
                        }
                        //if moved card is from one of the dealed card stacks
                        else{
                            dealedCardStacks[(indexPath as NSIndexPath).section].removeLast()
                        }
                        //clear the remembered previous position
                        pokerView.clearOriginal()
                        pokerView.clearViewOffset()
                        updateTitle()
                        gameModel.processCardMoveableAndCompletionStatus()
                    }
                }
                //else more than 1 card are moved to a free space, then reset them to the original positions
                else{
                    for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                        (dealedCardStacks[(movedPokerViewIndexPath as NSIndexPath).section][(movedPokerViewIndexPath as NSIndexPath).row]).resetToOriginal()
                    }
                }
            }
            //else moved card endup at outside the are of interests, the rest the card to the original place
            else{
                for movedPokerViewIndexPath in movedPokerViewIndexPaths{
                    if (movedPokerViewIndexPath as NSIndexPath).section == CARD_FREE_SPACE_INDEXPATH_SECTION{
                        cardsOnFreeSpace[(movedPokerViewIndexPath as NSIndexPath).row]?.resetToOriginal()
                    }
                    else{
                        (dealedCardStacks[(movedPokerViewIndexPath as NSIndexPath).section][(movedPokerViewIndexPath as NSIndexPath).row]).resetToOriginal()
                    }
                }
            }
        }
    }
}






















