//
//  RSDCountdownStepViewController.swift
//  ResearchSuiteUI
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit

/**
 `RSDCountdownStepViewController` is a simple countdown timer for displaying a short duration (5-4-3-2-1) countdown.
 */
open class RSDCountdownStepViewController: RSDStepViewController {
    
    @IBOutlet open var countdownLabel: UILabel?
    @IBOutlet open var pauseButton: UIButton?
    
    open override var countdown: Int {
        didSet {
            countdownLabel?.text = "\(countdown)"
        }
    }
    
    @IBAction open func pauseTimer() {
        if self.pauseUptime == nil {
            self.pause()
            self.pauseButton?.setTitle(Localization.buttonPause(), for: .normal)
        }
        else {
            self.resume()
            self.pauseButton?.setTitle(Localization.buttonResume(), for: .normal)
        }
    }
    
    // MARK: Initialization
    
    open class var nibName: String {
        return String(describing: RSDCountdownStepViewController.self)
    }
    
    open class var bundle: Bundle {
        return Bundle(for: RSDCountdownStepViewController.self)
    }
    
    public override init(step: RSDStep) {
        super.init(nibName: type(of: self).nibName, bundle: type(of: self).bundle)
        self.step = step
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
