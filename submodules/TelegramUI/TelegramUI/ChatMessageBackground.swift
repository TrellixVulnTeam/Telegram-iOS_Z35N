import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData

enum ChatMessageBackgroundMergeType: Equatable {
    case None, Side, Top(side: Bool), Bottom, Both
    
    init(top: Bool, bottom: Bool, side: Bool) {
        if top && bottom {
            self = .Both
        } else if top {
            self = .Top(side: side)
        } else if bottom {
            if side {
                self = .Side
            } else {
                self = .Bottom
            }
        } else {
            if side {
                self = .Side
            } else {
                self = .None
            }
        }
    }
}

enum ChatMessageBackgroundType: Equatable {
    case none
    case incoming(ChatMessageBackgroundMergeType)
    case outgoing(ChatMessageBackgroundMergeType)

    static func ==(lhs: ChatMessageBackgroundType, rhs: ChatMessageBackgroundType) -> Bool {
        switch lhs {
            case .none:
                if case .none = rhs {
                    return true
                } else {
                    return false
                }
            case let .incoming(mergeType):
                if case .incoming(mergeType) = rhs {
                    return true
                } else {
                    return false
                }
            case let .outgoing(mergeType):
                if case .outgoing(mergeType) = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

class ChatMessageBackground: ASDisplayNode {
    private(set) var type: ChatMessageBackgroundType?
    private var currentHighlighted: Bool?
    private var graphics: PrincipalThemeEssentialGraphics?
    private var maskMode: Bool?
    private let imageNode: ASImageNode
    
    override init() {
        self.imageNode = ASImageNode()
        self.imageNode.displaysAsynchronously = false
        self.imageNode.displayWithoutProcessing = true
        
        super.init()
        
        self.isUserInteractionEnabled = false
        self.addSubnode(self.imageNode)
    }
    
    func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.imageNode, frame: CGRect(origin: CGPoint(), size: size).insetBy(dx: -1.0, dy: -1.0))
    }
    
    func setMaskMode(_ maskMode: Bool) {
        if let type = self.type, let highlighted = self.currentHighlighted, let graphics = self.graphics {
            self.setType(type: type, highlighted: highlighted, graphics: graphics, maskMode: maskMode, transition: .immediate)
        }
    }
    
    func setType(type: ChatMessageBackgroundType, highlighted: Bool, graphics: PrincipalThemeEssentialGraphics, maskMode: Bool, transition: ContainedViewLayoutTransition) {
        let previousType = self.type
        if let currentType = previousType, currentType == type, self.currentHighlighted == highlighted, self.graphics === graphics, self.maskMode == maskMode {
            return
        }
        self.type = type
        self.currentHighlighted = highlighted
        self.graphics = graphics
        
        let image: UIImage?
        switch type {
        case .none:
            image = nil
        case let .incoming(mergeType):
            if maskMode && graphics.incomingBubbleGradientImage != nil {
                image = nil
            } else {
                switch mergeType {
                case .None:
                    image = highlighted ? graphics.chatMessageBackgroundIncomingHighlightedImage : graphics.chatMessageBackgroundIncomingImage
                case let .Top(side):
                    if side {
                        image = highlighted ? graphics.chatMessageBackgroundIncomingMergedTopSideHighlightedImage : graphics.chatMessageBackgroundIncomingMergedTopSideImage
                    } else {
                        image = highlighted ? graphics.chatMessageBackgroundIncomingMergedTopHighlightedImage : graphics.chatMessageBackgroundIncomingMergedTopImage
                    }
                case .Bottom:
                    image = highlighted ? graphics.chatMessageBackgroundIncomingMergedBottomHighlightedImage : graphics.chatMessageBackgroundIncomingMergedBottomImage
                case .Both:
                    image = highlighted ? graphics.chatMessageBackgroundIncomingMergedBothHighlightedImage : graphics.chatMessageBackgroundIncomingMergedBothImage
                case .Side:
                    image = highlighted ? graphics.chatMessageBackgroundIncomingMergedSideHighlightedImage : graphics.chatMessageBackgroundIncomingMergedSideImage
                }
            }
        case let .outgoing(mergeType):
            if maskMode && graphics.outgoingBubbleGradientImage != nil {
                image = nil
            } else {
                switch mergeType {
                case .None:
                    image = highlighted ? graphics.chatMessageBackgroundOutgoingHighlightedImage : graphics.chatMessageBackgroundOutgoingImage
                case let .Top(side):
                    if side {
                        image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedTopSideHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedTopSideImage
                    } else {
                        image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedTopHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedTopImage
                    }
                case .Bottom:
                    image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedBottomHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedBottomImage
                case .Both:
                    image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedBothHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedBothImage
                case .Side:
                    image = highlighted ? graphics.chatMessageBackgroundOutgoingMergedSideHighlightedImage : graphics.chatMessageBackgroundOutgoingMergedSideImage
                }
            }
        }
        
        if let previousType = previousType, previousType != .none, type == .none {
            if transition.isAnimated {
                let tempLayer = CALayer()
                tempLayer.contents = self.imageNode.layer.contents
                tempLayer.contentsScale = self.imageNode.layer.contentsScale
                tempLayer.rasterizationScale = self.imageNode.layer.rasterizationScale
                tempLayer.contentsGravity = self.imageNode.layer.contentsGravity
                tempLayer.contentsCenter = self.imageNode.layer.contentsCenter
                
                tempLayer.frame = self.bounds
                self.layer.addSublayer(tempLayer)
                transition.updateAlpha(layer: tempLayer, alpha: 0.0, completion: { [weak tempLayer] _ in
                    tempLayer?.removeFromSuperlayer()
                })
            }
        } else if transition.isAnimated {
            if let previousContents = self.imageNode.layer.contents, let image = image {
                self.imageNode.layer.animate(from: previousContents as AnyObject, to: image.cgImage! as AnyObject, keyPath: "contents", timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, duration: 0.42)
            }
        }
        
        self.imageNode.image = image
    }
}
