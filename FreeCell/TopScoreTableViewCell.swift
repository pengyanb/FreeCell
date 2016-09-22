//
//  TopScoreTableViewCell.swift
//  FreeCell
//
//  Created by Yanbing Peng on 11/06/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit

class TopScoreTableViewCell: UITableViewCell {

    //MARK: - Outlets
    @IBOutlet weak var rankLabel: UILabel!
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
