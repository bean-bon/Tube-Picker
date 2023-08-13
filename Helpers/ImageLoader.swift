//
//  ImageLoader.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 13/08/2023.
//

import SwiftUI

struct ImageLoader {
    
    enum roundel: String, Comparable {
        
        case DLRRoundel
        case OvergroundRoundel
        case TubeRoundel
        case XRRoundel
        
        static func fromMode(_ mode: StopPointMetaData.modeName) -> roundel {
            switch mode {
            case .allMetro:
                return TubeRoundel
            case .tube:
                return TubeRoundel
            case .dlr:
                return DLRRoundel
            case .elizabeth:
                return XRRoundel
            case .overground:
                return OvergroundRoundel
            default:
                return TubeRoundel
            }
        }
        
        static func < (lhs: ImageLoader.roundel, rhs: ImageLoader.roundel) -> Bool {
            switch lhs {
            case .DLRRoundel:
                return rhs == TubeRoundel
            case .OvergroundRoundel:
                return [DLRRoundel, TubeRoundel].contains(rhs)
            case .TubeRoundel:
                return true
            case .XRRoundel:
                return false
            }
        }
        
    }
    
    private init() {}
    
    static func getRoundel(mode: StopPointMetaData.modeName) -> Image {
        return Image(uiImage: UIImage(named: roundel.fromMode(mode).rawValue)!)
    }
    
    static func getRoundel(roundel: roundel) -> Image {
        return Image(uiImage: UIImage(named: roundel.rawValue)!)
    }
    
    static func getRoundelGivenModes(modes: [StopPointMetaData.modeName]) -> Image {
        guard !modes.isEmpty
        else { return getRoundel(mode: .tube) }
        return getRoundel(roundel: modes.map(roundel.fromMode).sorted().last!)
    }
    
}
