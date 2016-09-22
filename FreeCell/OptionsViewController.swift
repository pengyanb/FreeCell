//
//  OptionsViewController.swift
//  FreeCell
//
//  Created by Yanbing Peng on 10/06/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {

    //MARK: - Variables
    var needShowTopScores = false
    //MARK: - Outlets
    
    @IBOutlet weak var showTopScoresButton: UIButton!
    
    @IBOutlet weak var autoCompleteSegmentedControl: UISegmentedControl!
    @IBOutlet weak var showTutorialSegmentedControl: UISegmentedControl!
    @IBOutlet weak var soundEffectsSegmentedControl: UISegmentedControl!
    //MARK: - Target Actions
    
    @IBAction func showTopScoreButtonPressed(_ sender: UIButton) {
        needShowTopScores = true
        //print("showTopScoreButtonPressed")
        dismiss(animated: false, completion: nil)
        popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover!(popoverPresentationController!)
    }
    
    @IBAction func autoCompleteSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        var notAutoComplete = true
        if sender.selectedSegmentIndex == 0{
            notAutoComplete = false
        }
        else{
            notAutoComplete = true
        }
        UserDefaults.standard.set(notAutoComplete, forKey: CONSTANTS.NSUSER_DEFAULTS_NOT_AUTO_COMPLETE_KEY)
    }
    
    @IBAction func showTutorialSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        var notShowTutorial = true
        if sender.selectedSegmentIndex == 0{
            notShowTutorial = false
        }
        else{
            notShowTutorial = true
        }
        UserDefaults.standard.set(notShowTutorial, forKey: CONSTANTS.NSUSER_DEFAULTS_NOT_SHOW_TUTORIAL_KEY)
    }
    @IBAction func soundEffectSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        var noSoundEffects = true
        if sender.selectedSegmentIndex == 0{
            noSoundEffects = false
        }
        else{
            noSoundEffects = true
        }
        UserDefaults.standard.set(noSoundEffects, forKey: CONSTANTS.NSUSER_DEFAULTS_NO_SOUND_EFFECTS_KEY)
    }
    
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.popoverPresentationController?.backgroundColor = self.view.backgroundColor
        
        let userDefaults = UserDefaults.standard
        let notAutoComplete = userDefaults.bool(forKey: CONSTANTS.NSUSER_DEFAULTS_NOT_AUTO_COMPLETE_KEY)
        autoCompleteSegmentedControl.selectedSegmentIndex = notAutoComplete ? 1 : 0
        let notShowTutorial = userDefaults.bool(forKey: CONSTANTS.NSUSER_DEFAULTS_NOT_SHOW_TUTORIAL_KEY)
        showTutorialSegmentedControl.selectedSegmentIndex = notShowTutorial ? 1 : 0
        let noSoundEffects = userDefaults.bool(forKey: CONSTANTS.NSUSER_DEFAULTS_NO_SOUND_EFFECTS_KEY)
        soundEffectsSegmentedControl.selectedSegmentIndex = noSoundEffects ? 1 : 0
        
        self.preferredContentSize = CGSize.init(width: self.view.bounds.width, height: showTopScoresButton.frame.origin.y + showTopScoresButton.frame.size.height)
    }
}












