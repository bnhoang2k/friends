//
//  GlobalVariables.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import Foundation

final class GlobalVariables {
    
    static let shared = GlobalVariables()
    
    init() {}
    
    let TEXTFIELD_FRAMEHEIGHT: CGFloat = 35
    let TEXTFIELD_RRRADIUS: CGFloat = 10
    let TEXTFIELD_RRLINEWIDTH: CGFloat = 1
    let PROFILE_PICTUREWIDTH: CGFloat = 50
    let APPLEBUTTON_HEIGHT: CGFloat = 40
    let APPLEBUTTON_FONTSIZE: CGFloat = (40 * 0.43).rounded(.toNearestOrAwayFromZero)
    let CENTER_MODAL_VIEW_BORDER: CGFloat = 300
    
    let SHORTEST_ANIM_DUR: CGFloat = 0.25
    let MED_ANIM_DUR: CGFloat = 0.35
    
    let APP_FONT = "Avenir Next"
    let textBody: CGFloat = 15
    let textHeader: CGFloat = 25
    let textTitle: CGFloat = 35
    
}
