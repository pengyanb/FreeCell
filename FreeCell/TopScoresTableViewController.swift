//
//  TopScoresTableViewController.swift
//  FreeCell
//
//  Created by Yanbing Peng on 11/06/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit
import GameKit

class TopScoresTableViewController: UITableViewController, GKGameCenterControllerDelegate {

    //MARK: - Outlets
    @IBOutlet weak var gameCenterRankButton: UIBarButtonItem!
    
    
    //MARK: - Target Actions
    
    @IBAction func gameCenterRankButtonPressed(_ sender: UIBarButtonItem) {
        showLeaderboard()
    }
    
    //MAKR: - Game Cente Related
    func showLeaderboard(){
        let gameCenterViewController = GKGameCenterViewController()
        gameCenterViewController.gameCenterDelegate = self
        self.present(gameCenterViewController, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: - Variables
    var topScoresArray : [[String:AnyObject]]? = nil
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        //self.tableView.allowsSelection = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let topScores = UserDefaults.standard.object(forKey: CONSTANTS.NSUSER_DEFAULTS_TOP_TEN_SCORE_KEY) as? [[String:AnyObject]]{
            topScoresArray = topScores
            if topScoresArray!.count > 11{
                topScoresArray = Array( topScoresArray!.dropLast(topScoresArray!.count - 11) )
            }
            //print("Count: \(topScoresArray?.count)")
            //print("\(topScoresArray)")
            self.tableView.reloadData()
            for (row, scoreInfo) in topScoresArray!.enumerated(){
                if let isLatest =  scoreInfo["isLatest"] as? Bool{
                    if isLatest == true{
                        let indexPath = IndexPath.init(row: row, section: 0)
                        tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
                        DispatchQueue.main.async(execute: { [weak self] in
                            self?.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.middle, animated: true)
                        })
                    }
                }
            }
        }
        self.navigationController?.navigationBar.topItem?.title = NSLocalizedString("TopScoreTableViewControllerBackButton", comment: "TopScoreTableViewControllerBackButton")
        self.title = NSLocalizedString("TopScoreTableViewControlerTitle", comment: "TopScoreTableViewControlerTitle")
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if topScoresArray != nil{
            return 1
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let topScores = topScoresArray{
            if let lastScoreInfo = topScores.last{
                if (lastScoreInfo["isLatest"] as? Bool) == true{
                    return topScores.count
                }
                else{
                    if topScores.count > 10{
                        return 10
                    }
                    else{
                        return topScores.count
                    }
                }
            }
        }
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topScoreCell", for: indexPath)
        if let topScoreCell = cell as? TopScoreTableViewCell{
            if (indexPath as NSIndexPath).row < 10{
                topScoreCell.rankLabel.text = "\((indexPath as NSIndexPath).row + 1)"
            }
            else{
                topScoreCell.rankLabel.text = "-"
            }
            if (indexPath as NSIndexPath).row == 0{
                topScoreCell.rankLabel.textColor = UIColor.init(red: 255/255.0, green: 204/255.0, blue: 102/255.0, alpha: 1)
            }
            else if (indexPath as NSIndexPath).row == 1{
                topScoreCell.rankLabel.textColor = UIColor.init(red: 204/255.0, green: 204/255.0, blue: 204/255.0, alpha: 1)
            }
            else if (indexPath as NSIndexPath).row == 2{
                
                topScoreCell.rankLabel.textColor = UIColor.init(red: 128/255.0, green: 64/255.0, blue: 0, alpha: 1)
            }
            else{
                topScoreCell.rankLabel.textColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
            }
            let scoreInfo = topScoresArray![(indexPath as NSIndexPath).row]
            //cell.highlighted = false
            //cell.selectionStyle = UITableViewCellSelectionStyle.None
            if let isLatest = scoreInfo["isLatest"] as? Bool{
                if isLatest == true{
                    cell.selectionStyle = UITableViewCellSelectionStyle.blue
                    cell.isHighlighted = true
                }
            }
            if let timeUsed = scoreInfo["timeUsed"] as? Int, let moveCount = scoreInfo["moveCount"] as? Int{
                let second = timeUsed % 60
                let minute = ((timeUsed - second) % 3600) / 60
                let hour = (timeUsed - minute * 60 - second) / 3600
                
                topScoreCell.scoreLabel.text = "\(NSLocalizedString("PageTitleTime", comment: "PageTitleTime")) \(hour > 0 ? "\(String.init(format: "%02d:", hour))" : "")\(String.init(format: "%02d", minute)):\(String.init(format: "%02d", second))\t\(NSLocalizedString("PageTitleMove", comment: "PageTitleMove")) \(String.init(format: "%d", moveCount))"
            }
            if let completedTime = scoreInfo["completeTime"] as? Date{
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                topScoreCell.timeLabel.text = formatter.string(from: completedTime)
            }
        }

        return cell
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let topScores = topScoresArray {
            let scoreInfo = topScores[(indexPath as NSIndexPath).row]
            if let isLatest = scoreInfo["isLatest"] as? Bool{
                if isLatest == true{
                    return indexPath
                }
            }
        }
        return nil
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
