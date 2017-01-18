//
//  ProgressHUD.swift
//  ProgressHUD
//
//  Created by zero on 17/1/15.
//  Copyright © 2017年 zero. All rights reserved.
//

import Foundation
import UIKit

/// 模式
///
/// - indicator: 菊花
/// - pieChart: 馅饼图
/// - horizontalBar: 水平条
/// - annular: 环
/// - customView: 自定义
/// - text: 文字
public enum Mode: Int {
    case indicator
    case pieChart
    case horizontalBar
    case annular
    case customView
    case text
}

/// 动画
///
/// - fade: 淡入淡出,只有透明度变化
/// - zoom: 缩放,透明度变化+缩放
/// - zoomOut: 缩出,透明度变化+缩出
/// - zoomIn: 缩进,透明度变化+缩进
public enum Animation: Int {
    case fade
    case zoom
    case zoomOut
    case zoomIn
}

/// 背景风格
///
/// - solidColor: 一致
/// - blur: 模糊
public enum BackgroundStyle: Int {
    case solidColor
    case blur
}

public typealias CompletionHandler = ()->()

fileprivate let DefaultPadding: CGFloat = 4
fileprivate let DefaultLabelFontSize: CGFloat = 16
fileprivate let DefaultDetailsLabelFontSize: CGFloat = 12


@objc public protocol ProgressHUDDelegate: NSObjectProtocol {
    @objc optional func hudHidden(progressHUD: ProgressHUD)
}

public class ProgressHUD: UIView {
    
    /// 便利构造器
    ///
    /// - Parameters:
    ///   - view: 作为superview,并且提供bounds
    public convenience init(view: UIView) {
        self.init(frame:view.bounds)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.unregisterNofications()
    }
    
    
    /// 代理对象
    public weak var delegate: ProgressHUDDelegate?
    
    /// Called after the HUD is hiden
    public var completionHandler: CompletionHandler?
    
    /// Grace period is the time (in seconds) that the invoked method may be run without showing the HUD. If the task finishes before the grace time runs out, the HUD will not be shown at all. This may be used to prevent HUD display for very short tasks. Defaults to 0 (no grace time).
    public var graceTime: TimeInterval = 0
    
    /// 最短显示时间,避免一显示就隐藏
    public var minShowTime: TimeInterval = 0
    
    /// 当隐藏的时候从superview移除
    public var removeFromSuperViewOnHide: Bool = false
    
    /// 展示模式
    public var mode: Mode = .indicator {
        didSet {
            if mode != oldValue {
                self.updateIndicators()
            }
        }
    }
    
    /// 所有labels、indicator 以及 customview的颜色，默认半透明黑
    public var contentColor: UIColor = UIColor(white: 0, alpha: 0.7) {
        didSet {
            if oldValue != contentColor && !oldValue.isEqual(contentColor) {
                self.updateViews(forColor: contentColor)
            }
        }
    }
    
    /// 动画
    public var animation: Animation = .fade
    
    /// 控制HUD的位置
    public var offset: CGPoint = CGPoint.zero {
        didSet {
            if !oldValue.equalTo(offset) {
                self.setNeedsUpdateConstraints()
            }
        }
    }
    
    /// HUD边缘距superview边缘的距离、以及HUD边缘与内部childview的距离
    public var margin: CGFloat = 20 {
        didSet {
            if oldValue != margin {
                self.setNeedsUpdateConstraints()
            }
        }
    }
    
    /// The minimum size of the HUD bezel
    public var minSize: CGSize = CGSize.zero {
        didSet {
            if !oldValue.equalTo(minSize) {
                self.setNeedsUpdateConstraints()
            }
        }
    }
    
    /// Force the HUD dimensions to be equal if possible.
    public var square: Bool = false {
        didSet {
            if oldValue != square {
                self.setNeedsUpdateConstraints()
            }
        }
    }
    
    /// When enabled, the bezel center gets slightly affected by the device accelerometer data. Defaults to YES.
    public var defaultMotionEffectsEnabled: Bool = true {
        didSet {
            if oldValue != defaultMotionEffectsEnabled {
                self.updateBezelMotionEffects()
            }
        }
    }
    
    /// The progress of the progress indicator, from 0.0 to 1.0. Defaults to 0.0
    public var progress: CGFloat = 0 {
        didSet {
            if progress != oldValue {
                if let indicator = self.indicator, indicator.responds(to: #selector(setter: progress)) {
                    let _ = indicator.perform(#selector(setter: progress), with: progress)
                }
            }
        }
    }
    
    /// The NSProgress object feeding the progress information to the progress indicator.
    public var progressObject: Progress? {
        didSet {
            if oldValue != progressObject {
                self.setProgressDisplayLinkEnable(enable: true)
            }
        }
    }
    
    /// The view containing the labels and indicator (or customView)
    fileprivate(set) lazy var bezelView: BackgroundView = {
        let bezelView = BackgroundView.init(frame: CGRect.zero)
        bezelView.translatesAutoresizingMaskIntoConstraints = false
        bezelView.layer.cornerRadius = 5
        bezelView.alpha = 0
        return bezelView
    }()
    
    /// View covering the entire HUD area, placed behind bezelView.
    fileprivate(set) lazy var backgroundView: BackgroundView = {
        let backgroundView = BackgroundView.init(frame: self.bounds)
        backgroundView.style = .solidColor
        backgroundView.backgroundColor = UIColor.clear
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.alpha = 0
        return backgroundView
    }()
    
    /// The UIView (e.g., a UIImageView) to be shown when the HUD is in MBProgressHUDModeCustomView. The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
    public var customView: UIView? {
        didSet {
            if oldValue != customView && self.mode == .customView {
                self.updateIndicators()
            }
        }
    }
    
    /// A label that holds an optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    fileprivate(set) lazy var label: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = .center
        label.textColor = self.contentColor
        label.font = UIFont.boldSystemFont(ofSize: DefaultLabelFontSize)
        label.isOpaque = false
        label.backgroundColor = UIColor.clear
        return label
    }()
    
    /// A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines.
    fileprivate(set) lazy var detailsLabel: UILabel = {
        let detailsLabel = UILabel(frame: CGRect.zero)
        detailsLabel.adjustsFontSizeToFitWidth = false
        detailsLabel.textAlignment = .center
        detailsLabel.textColor = self.contentColor
        detailsLabel.numberOfLines = 0
        detailsLabel.font = UIFont.boldSystemFont(ofSize: DefaultDetailsLabelFontSize)
        detailsLabel.isOpaque = false
        detailsLabel.backgroundColor = UIColor.clear
        return detailsLabel
    }()
    
    /// A button that is placed below the labels. Visible only if a target / action is added.
    fileprivate(set) lazy var button: UIButton = {
        let button = RoundedButton(frame: CGRect.zero)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: DefaultDetailsLabelFontSize)
        button.setTitleColor(self.contentColor, for: .normal)
        return button
    }()
    
    fileprivate var useAnimation: Bool = false
    fileprivate var finished: Bool = false
    fileprivate var indicator: UIView?
    fileprivate var showStarted: Date?
    fileprivate var paddingConstraints: [NSLayoutConstraint] = []
    fileprivate var bezelConstraints: [NSLayoutConstraint]?
    
    fileprivate lazy var topSpacer: UIView = {
        let topSpacer = UIView(frame: CGRect.zero)
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        topSpacer.isHidden = true
        return topSpacer
    }()
    
    fileprivate lazy var bottomSpacer: UIView = {
        let bottomSpacer = UIView(frame: CGRect.zero)
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.isHidden = true
        return bottomSpacer
    }()
    
    fileprivate weak var graceTimer: Timer?
    fileprivate weak var minShowTimer: Timer?
    fileprivate weak var hideDelayTimer: Timer?
    fileprivate weak var progressObjectDisplayLink: CADisplayLink? {
        willSet {
            if progressObjectDisplayLink != newValue {
                progressObjectDisplayLink?.invalidate()
                newValue?.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
            }
        }
    }
    
}



extension ProgressHUD {
    override public func updateConstraints() {
        
        var bezelConstraints: [NSLayoutConstraint] = []
        let metrics = ["margin":self.margin]
        
        var subviews: [UIView] = [self.topSpacer, self.label, self.detailsLabel, self.button, self.bottomSpacer]
        if self.indicator != nil {
            subviews.insert(self.indicator!, at: 1)
        }
        
        self.removeConstraints(self.constraints)
        self.topSpacer.removeConstraints(self.topSpacer.constraints)
        self.bottomSpacer.removeConstraints(self.bottomSpacer.constraints)
        if self.bezelConstraints != nil {
            self.bezelView.removeConstraints(self.bezelConstraints!)
            self.bezelConstraints = nil
        }
        
        var centeringConstraints: [NSLayoutConstraint] = []
        centeringConstraints.append(NSLayoutConstraint(item: self.bezelView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: self.offset.x))
        centeringConstraints.append(NSLayoutConstraint(item: self.bezelView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: self.offset.y))
        self.applyPriority(998, to: centeringConstraints)
        self.addConstraints(centeringConstraints)
        
        var sideConstraints: [NSLayoutConstraint] = []
        sideConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[bezelView]-(>=margin)-|", options: .init(rawValue: 0), metrics: metrics, views: ["bezelView" : self.bezelView]))
        sideConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=margin)-[bezelView]-(>=margin)-|", options: .init(rawValue: 0), metrics: metrics, views: ["bezelView":self.bezelView]))
        self.applyPriority(999, to: sideConstraints)
        self.addConstraints(sideConstraints)
        
        if !self.minSize.equalTo(CGSize.zero) {
            var minSizeConstraints: [NSLayoutConstraint] = []
            minSizeConstraints.append(NSLayoutConstraint(item: self.bezelView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.minSize.width))
            minSizeConstraints.append(NSLayoutConstraint(item: self.bezelView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.minSize.height))
            self.applyPriority(997, to: minSizeConstraints)
            bezelConstraints.append(contentsOf: minSizeConstraints)
        }
        
        if self.square {
            let square = NSLayoutConstraint(item: self.bezelView, attribute: .height, relatedBy: .equal, toItem: self.bezelView, attribute: .width, multiplier: 1, constant: 0)
            square.priority = 997
            bezelConstraints.append(square)
        }
        
        self.topSpacer.addConstraint(NSLayoutConstraint(item: self.topSpacer, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.margin))
        self.bottomSpacer.addConstraint(NSLayoutConstraint(item: self.bottomSpacer, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.margin))
        bezelConstraints.append(NSLayoutConstraint(item: self.topSpacer, attribute: .height, relatedBy: .equal, toItem: self.bottomSpacer, attribute: .height, multiplier: 1, constant: 0))
        
        var paddingConstraints: [NSLayoutConstraint] = []
        for (idx, view) in subviews.enumerated() {
            bezelConstraints.append(NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: self.bezelView, attribute: .centerX, multiplier: 1, constant: 0))
            bezelConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[view]-(>=margin)-|", options: .init(rawValue: 0), metrics: metrics, views: ["view":view]))
            if idx == 0 {
                bezelConstraints.append(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self.bezelView, attribute: .top, multiplier: 1, constant: 0))
            }else if idx == subviews.count - 1 {
                bezelConstraints.append(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self.bezelView, attribute: .bottom, multiplier: 1, constant: 0))
            }
            if (idx > 0) {
                let padding = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: subviews[idx-1], attribute: .bottom, multiplier: 1, constant: 0)
                bezelConstraints.append(padding)
                paddingConstraints.append(padding)
            }
        }
        
        self.bezelView.addConstraints(bezelConstraints)
        self.bezelConstraints = bezelConstraints
        self.paddingConstraints = paddingConstraints
        self.updatePaddingConstraints()
        super.updateConstraints()
    }
    
    
    func updatePaddingConstraints() {
        
        var hasVisibleAncestors = false
        
        self.paddingConstraints.forEach { (padding) in
            let firstView = padding.firstItem as? UIView
            let secondView = padding.secondItem as? UIView
            let firstVisible: Bool = firstView == nil ? false : (!(firstView!.isHidden) && !(firstView!.intrinsicContentSize.equalTo(CGSize.zero)))
            let secondVisible: Bool = secondView == nil ? false : (!(secondView!.isHidden) && !(secondView!.intrinsicContentSize.equalTo(CGSize.zero)))
            padding.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? DefaultPadding : 0
            hasVisibleAncestors = (hasVisibleAncestors || secondVisible)
        }
    }
    
    override public func layoutSubviews() {
        if !self.needsUpdateConstraints() {
            self.updatePaddingConstraints()
        }
        super.layoutSubviews()
    }
    
    func applyPriority(_ priority: UILayoutPriority, to constraints:[NSLayoutConstraint]) {
        for constraint in constraints {
            constraint.priority = priority
        }
    }
    
}



// MARK: public instance function
extension ProgressHUD {
    /// 显示HUD，只能在主线程调用
    ///
    /// - Parameters:
    ///   - animated: 是否需要动画
    public func show(animated:Bool) {
        assert(Thread.isMainThread, "必需在主线程")
        self.minShowTimer?.invalidate()
        self.useAnimation = animated
        self.finished = false
        
        if self.graceTime > 0 {
            let timer = Timer(timeInterval: self.graceTime, target: self, selector: #selector(handleGraceTimer(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .commonModes)
            self.graceTimer = timer
        }else{
            self.showUsingAnimation(animation: useAnimation)
        }
    }
    
    
    /// 隐藏HUD，只能在主线程调用
    ///
    /// - Parameters:
    ///   - animated: 是否需要动画
    public func hide(animated:Bool) {
        assert(Thread.isMainThread, "必需在主线程")
        self.graceTimer?.invalidate()
        self.useAnimation = animated
        self.finished = true
        
        if self.minShowTime > 0 && self.showStarted != nil {
            let interval = Date().timeIntervalSince(self.showStarted!)
            if interval < self.minShowTime {
                let timer = Timer(timeInterval: self.minShowTime - interval, target: self, selector: #selector(handleMinShowTimer(_:)), userInfo: nil, repeats: false)
                RunLoop.current.add(timer, forMode: .commonModes)
                self.minShowTimer = timer
                return
            }
        }
        
        self.hideUsingAnimation(animation: self.useAnimation)
    }
    
    /// 延迟隐藏HUD，只能在主线程调用
    ///
    /// - Parameters:
    ///   - animated: 是否需要动画
    ///   - afterDelay: 延迟多少秒
    public func hide(animated:Bool, afterDelay:TimeInterval) {
        let timer = Timer(timeInterval: afterDelay, target: self, selector: #selector(handleHideTimer(_:)), userInfo: animated, repeats: false)
        RunLoop.current.add(timer, forMode: .commonModes)
        self.hideDelayTimer = timer
    }
    
}

// MARK: private instance function
extension ProgressHUD {
    
    fileprivate func showUsingAnimation(animation:Bool) {
        
        self.bezelView.layer.removeAllAnimations()
        self.backgroundView.layer.removeAllAnimations()
        
        self.hideDelayTimer?.invalidate()
        
        self.showStarted = Date()
        self.alpha = 1
        
        self.setProgressDisplayLinkEnable(enable: true)
        
        if animation {
            self.animate(in: true, with: self.animation, completion: nil)
        }else{
            self.bezelView.alpha = 1
            self.backgroundView.alpha = 1
        }
    }
    
    fileprivate func hideUsingAnimation(animation:Bool) {
        if animation && self.showStarted != nil {
            self.showStarted = nil
            self.animate(in: false, with: self.animation, completion: { (_) in
                self.done()
            })
        }else{
            self.showStarted = nil
            self.bezelView.alpha = 0
            self.backgroundView.alpha = 1
            self.done()
        }
    }

    fileprivate func animate(`in`: Bool, with type: Animation, completion:((Bool)->())?) {
        
        var innerType = type
        
        if case .zoom = innerType {
            innerType = `in` ? .zoomIn : .zoomOut
        }
        
        let small: CGAffineTransform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let large: CGAffineTransform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        let view = self.bezelView
        if `in` && view.alpha == 0 && innerType == .zoomIn {
            view.transform = small
        }else if `in` && view.alpha == 0 && innerType == .zoomOut {
            view.transform = large
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .beginFromCurrentState, animations: { 
            if `in` {
                view.transform = .identity
            }else if !`in` && innerType == .zoomIn {
                view.transform = large
            }else if !`in` && innerType == .zoomOut {
                view.transform = small
            }
            self.bezelView.alpha = `in` ? 1 : 0
            self.backgroundView.alpha = `in` ? 1 : 0
        }, completion: completion)
    }
    
    fileprivate func done() {
        self.hideDelayTimer?.invalidate()
        self.setProgressDisplayLinkEnable(enable: false)
        
        if self.finished {
            self.alpha = 0
            if self.removeFromSuperViewOnHide {
                self.removeFromSuperview()
            }
        }
        
        self.completionHandler?()
        
        if let _ = self.delegate, self.delegate!.responds(to: #selector(ProgressHUDDelegate.hudHidden(progressHUD:))) {
            self.delegate!.perform(#selector(ProgressHUDDelegate.hudHidden(progressHUD:)), with: self)
        }
    }
    
    @objc fileprivate func handleGraceTimer(_ timer: Timer) {
        if !self.finished {
            self.showUsingAnimation(animation: self.useAnimation)
        }
    }
    
    @objc fileprivate func handleMinShowTimer(_ timer: Timer) {
        self.hideUsingAnimation(animation: self.useAnimation)
    }
    
    @objc fileprivate func handleHideTimer(_ timer: Timer) {
        if let animation = timer.userInfo as? Bool {
            self.hide(animated: animation)
        }else{
            self.hide(animated: false)
        }
    }
    
    fileprivate func commonInit() {
        
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
        self.alpha = 0
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.layer.allowsGroupOpacity = false
        self.setupViews()
        self.updateIndicators()
        self.registerNotifications()
    }
    
    fileprivate func setupViews() {
        
        self.addSubview(self.backgroundView)
        self.addSubview(self.bezelView)
        self.updateBezelMotionEffects()
        
        for view in [self.label, self.detailsLabel, self.button] as [UIView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setContentCompressionResistancePriority(998, for: .horizontal)
            view.setContentCompressionResistancePriority(998, for: .vertical)
            bezelView.addSubview(view)
        }
        
        bezelView.addSubview(self.topSpacer)
        bezelView.addSubview(self.bottomSpacer)
    }
    
    fileprivate func updateIndicators() {
        var indicator: UIView? = self.indicator
        let isActivityIndicator = indicator is UIActivityIndicatorView
        let isRoundIndicator = indicator is RoundProgressView
        
        switch self.mode {
        case .indicator:
            if !isActivityIndicator {
                indicator?.removeFromSuperview()
                indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
                (indicator as! UIActivityIndicatorView).startAnimating()
                self.bezelView.addSubview(indicator!)
            }
        case .horizontalBar:
            indicator?.removeFromSuperview()
            indicator = BarProgressView(frame: CGRect.zero)
            self.bezelView.addSubview(indicator!)
        case .pieChart:
            if !isRoundIndicator {
                indicator?.removeFromSuperview()
                indicator = RoundProgressView(frame: CGRect.zero)
                self.bezelView.addSubview(indicator!)
            }
            
        case .annular:
            if !isRoundIndicator {
                indicator?.removeFromSuperview()
                indicator = RoundProgressView(frame: CGRect.zero)
                self.bezelView.addSubview(indicator!)
                (indicator as! RoundProgressView).annular = true
            }
        case .customView:
            guard let _ = self.customView, self.customView! != indicator else {
                return
            }
            indicator?.removeFromSuperview()
            indicator = self.customView!
            self.bezelView.addSubview(indicator!)
        case .text:
            indicator?.removeFromSuperview()
            indicator = nil
        }
        
        self.indicator = indicator
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        
        if let _ = indicator, indicator!.responds(to: #selector(setter: progress)) {
            let _ = indicator?.perform(#selector(setter: progress), with: self.progress)
            indicator!.setContentCompressionResistancePriority(998, for: .horizontal)
            indicator!.setContentCompressionResistancePriority(998, for: .vertical)
        }
        self.updateViews(forColor: self.contentColor)
        self.setNeedsUpdateConstraints()
    }
    
    fileprivate func updateViews(forColor: UIColor) {
        assert(ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)), "版本小于9,不支持")
        self.label.textColor = forColor
        self.detailsLabel.textColor = forColor
        self.button.setTitleColor(forColor, for: .normal)
        
        guard let indicator = self.indicator else {
            return
        }
        
        if indicator is UIActivityIndicatorView {
            (indicator as! UIActivityIndicatorView).color = forColor
        } else if indicator is RoundProgressView {
            (indicator as! RoundProgressView).progressTintColor = forColor
            (indicator as! RoundProgressView).progressTintColor = forColor.withAlphaComponent(0.1)
        } else if indicator is BarProgressView {
            (indicator as! BarProgressView).progressColor = forColor
            (indicator as! BarProgressView).lineColor = forColor
        }else {
            if indicator.responds(to: #selector(setter: tintColor)) {
                indicator.tintColor = forColor
            }
        }
    }
    
    fileprivate func updateBezelMotionEffects() {
        
        if !bezelView.responds(to: #selector(addMotionEffect)) {return}
        
        if self.defaultMotionEffectsEnabled {
            let effectOffset: CGFloat = 10
            let effectX: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            effectX.maximumRelativeValue = effectOffset
            effectX.minimumRelativeValue = -effectOffset
            let effectY: UIInterpolatingMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            effectY.maximumRelativeValue = effectOffset
            effectY.minimumRelativeValue = -effectOffset
            let group: UIMotionEffectGroup = UIMotionEffectGroup()
            group.motionEffects = [effectX, effectY];
            bezelView.addMotionEffect(group)
        }else{
            let effects = bezelView.motionEffects
            for effect in effects {
                bezelView.removeMotionEffect(effect)
            }
        }
    }
    
    
    
    // MARK: Notification about
    fileprivate func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationDidChange(notification:)), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    fileprivate func unregisterNofications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    @objc fileprivate func statusBarOrientationDidChange(notification:NSNotification) {
        guard let _ = self.superview else {
            return
        }
        self.updateForCurrentOrientation(animated: true)
    }
    
    fileprivate func updateForCurrentOrientation(animated: Bool) {
        if let _ = self.superview {
            self.frame = self.superview!.bounds
        }
    }
    
    override public func didMoveToSuperview() {
        self.updateForCurrentOrientation(animated: false)
    }
    
    fileprivate func setProgressDisplayLinkEnable(enable: Bool) {
        if enable && self.progressObject != nil {
            if self.progressObjectDisplayLink == nil {
                self.progressObjectDisplayLink = CADisplayLink(target: self, selector: #selector(updateProgressFromProgressObject))
            }
        }else{
            self.progressObjectDisplayLink = nil
        }
    }
    
    @objc fileprivate func updateProgressFromProgressObject() {
        guard let _ = self.progressObject else {
            return
        }
        self.progress = CGFloat(self.progressObject!.fractionCompleted)
    }

    
}

// MARK: class function
extension ProgressHUD {
    /// 显示HUD到指定的view
    ///
    /// - Parameters:
    ///   - view: 显示HUD的view
    ///   - animated: 是否需要动画
    /// - Returns: 显示的HUD
    static public func showHUD(toView view:UIView, animated:Bool) -> ProgressHUD {
        let hud = ProgressHUD(view: view)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud
    }
    
    /// 隐藏指定view的HUD
    ///
    /// - Parameters:
    ///   - view: 需要隐藏HUD的view
    ///   - animated: 是否需要动画
    /// - Returns: 如果找到了需要隐藏的HUD,返回*true*;否则,返回*false*
    static public func hideHUD(forView view:UIView, animated:Bool) -> Bool {
        guard let hud = self.HUD(forview: view) else {
            return false
        }
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: animated)
        return true
    }
    
    /// 找出指定view最顶端的HUD
    ///
    /// - Parameters:
    ///   - view: 被查找view
    /// - Returns: 返回找到了HUD或者nil
    static public func HUD(forview view:UIView) -> ProgressHUD? {
        for subview: UIView in view.subviews.reversed() {
            if subview is ProgressHUD {
                return (subview as! ProgressHUD)
            }
        }
        return nil
    }
}

extension ProgressHUD {
    
    class func show(text:String, icon:String, to view:UIView) {
        let hud = ProgressHUD(view: view)
        hud.mode = .customView
        hud.label.text = text
        hud.customView = UIImageView(image: UIImage(named: "icon"))
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: true)
        hud.hide(animated: true, afterDelay: 0.7)
    }
    
    class public func showError(_ error: String, to view: UIView) {
        self.show(text: error, icon: "ProgressHUD_error.png", to: view)
    }
    
    class public func showSuccess(_ success: String, to view: UIView) {
        self.show(text: success, icon: "ProgressHUD_success.png", to: view)
    }
    
    class public func showMessage(_ message: String, to view: UIView) -> ProgressHUD {
        let hud = ProgressHUD(view: view)
        hud.mode = .text
        hud.label.text = message
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: true)
        return hud
    }
    
    class public func loading(with message: String, to view: UIView) -> ProgressHUD {
        let hud = ProgressHUD(view: view)
        hud.mode = .indicator
        hud.label.text = message
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: true)
        return hud
    }
    
}

