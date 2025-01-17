//
//  Information.swift
//  NeighborhoodTV
//
//  Created by fulldev on 1/27/23.
//

import Foundation
import SwiftUI

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


struct TextView: UIViewRepresentable {
    
    @Binding var text: String
    @Binding var textStyle: UIFont.TextStyle
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        let range = NSRange(location: textView.text.count - 1, length: 0)
        
        textView.font = UIFont.preferredFont(forTextStyle: textStyle)
        textView.clipsToBounds = false
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        textView.scrollRangeToVisible(range)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        uiView.font = UIFont.preferredFont(forTextStyle: textStyle)
    }
}

struct Information: View {
    @State var infoCurrentTitle:String = ""
    @State var infoCurrentBody:String = ""
    @State var textStyle = UIFont.TextStyle.body
    @State var isInfoAboutUSFocus = false
    @State var isInfoPrivacyPolicyFocus = false
    @State var isInfoVisitorAgreementFocus = false
    @State var isCurrentInfoClick: Int = 1
    @State var isDividerInfo = false
    @State var isTextInfo = false
    @State var isDividerText = false
    @State var offsetX = 0
    
    @Binding var sideBarDividerFlag:Bool
    @Binding var isCollapseSideBar:Bool
    
    @FocusState private var isAbDefaultFocus:Bool
    @FocusState private var isPPDefaultFocus:Bool
    @FocusState private var isInfoDefaultFocus:Bool
    @FocusState private var textDefaultFocus:Bool
    
    
    @State private var isVisible = false
    
    let pub_default_focus = NotificationCenter.default.publisher(for: NSNotification.Name.locationDefaultFocus)
    
    var body: some View {
        HStack(spacing: 2) {
            VStack(alignment: .leading, spacing: 30) {
                Label {
                    Text("About Us").font(.custom("Arial Round MT Bold", fixedSize: 30)).frame(width: 250, alignment: .leading)
                } icon: {
                    Image(systemName: "person.3").resizable().frame(width: 40, height: 25)
                }
                .padding(20)
                .background(isInfoAboutUSFocus ? Color.infoFocusColor : Color.infoMenuColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((isCurrentInfoClick == 1 ? Color.white : Color.infoMenuColor), lineWidth: 1)
                )
                .focusable(isCollapseSideBar ? false : true) {newState in isInfoAboutUSFocus = newState }
                .focused($isAbDefaultFocus)
                .onLongPressGesture(minimumDuration: 0.001, perform: {isCurrentInfoClick = 1; getCurrentInfo()})
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        self.isAbDefaultFocus = true
                        sideBarDividerFlag = false
                        
                    }
                    
                }
                .onReceive(pub_default_focus) { (out_location_default) in
                    guard let _out_location_default = out_location_default.object as? Bool else {
                        print("Invalid URL")
                        return
                    }
                    onDefaultFocus()
                }
                
                Label {
                    Text("Privacy Policy").font(.custom("Arial Round MT Bold", fixedSize: 30)).frame(width: 250, alignment: .leading)
                } icon: {
                    Image(systemName: "exclamationmark.shield").resizable().frame(width: 40, height: 40)
                }
                .padding(20)
                .background(isInfoPrivacyPolicyFocus ? Color.infoFocusColor : Color.infoMenuColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((isCurrentInfoClick == 2 ? Color.white : Color.infoMenuColor), lineWidth: 1)
                )
                .focusable(isCollapseSideBar ? false : true) {newState in isInfoPrivacyPolicyFocus = newState }
                .focused($isPPDefaultFocus)
                .onReceive(pub_default_focus) { (out_location_default) in
                    guard let _out_location_default = out_location_default.object as? Bool else {
                        print("Invalid URL")
                        return
                    }
                    onDefaultFocus()
                }
                .onLongPressGesture(minimumDuration: 0.001, perform: {isCurrentInfoClick = 2; getCurrentInfo()})
                
                Label {
                    Text("Visitor Agreement").font(.custom("Arial Round MT Bold", fixedSize: 30)).frame(width: 250, alignment: .leading)
                } icon: {
                    Image(systemName: "printer").resizable().frame(width: 40, height: 40)
                }
                .padding(20)
                .background(isInfoVisitorAgreementFocus ? Color.infoFocusColor : Color.infoMenuColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((isCurrentInfoClick == 3 ? Color.white : Color.infoMenuColor), lineWidth: 1)
                )
                .focusable(isCollapseSideBar ? false : true) {newState in isInfoVisitorAgreementFocus = newState }
                .focused($isInfoDefaultFocus)
                .onReceive(pub_default_focus) { (out_location_default) in
                    guard let _out_location_default = out_location_default.object as? Bool else {
                        print("Invalid URL")
                        return
                    }
                    onDefaultFocus()
                }
                .onLongPressGesture(minimumDuration: 0.001, perform: {isCurrentInfoClick = 3; getCurrentInfo()})
                Spacer()
            }
            .frame(width: 450)
            .padding(.leading, 50)
            .padding(.top, 50)
            .background(Color.infoMenuColor)
            
            Divider().focusable(textDefaultFocus ? true : false) { newState in isDividerInfo = newState; onDefaultFocus()}
            
            VStack(alignment: .center, spacing: 30) {
                Text("\(infoCurrentTitle)").font(.custom("Arial Round MT Bold", fixedSize: 40)).focusable(true) { isFo in isDividerText = isFo; onUpScrollText() }
                
                VStack {
                    List {
                        TextView(text: $infoCurrentBody, textStyle:$textStyle)
                            .offset(x: 0, y: CGFloat(offsetX))
                            .frame(height: 800)
                    }
                    .focusable(true){newState in isTextInfo = newState; textDefaultFocus = true}
                    .focused($textDefaultFocus)
                    .padding(.leading, 100)
                }
                
                
                Spacer()
                Divider().padding(.leading, 100).focusable(true){ isFo in isDividerText = isFo; onDownScrollText()}
            }
            .onAppear() {
                PlayerInstance.shared.stopPlayer()

                getCurrentInfo()
            }
            .frame(height: 900)
            
            Spacer()
        }
        
    }
    
    func onUpScrollText() {
        if textDefaultFocus {
            offsetX -= 50;
            textDefaultFocus = true
        } else {
            textDefaultFocus = true
        }
    }
    
    func onDownScrollText() {
        if textDefaultFocus {
            offsetX += 50;
            textDefaultFocus = true
        } else {
            textDefaultFocus = true
        }
    }
    
    func onDefaultFocus() {
        switch isCurrentInfoClick {
        case 1:
            isAbDefaultFocus = true
        case 2:
            isPPDefaultFocus = true
        default:
            isInfoDefaultFocus = true
            
        }
    }
    
    func getCurrentInfo() {
        offsetX = 0
        switch isCurrentInfoClick {
        case 2:
            guard let _title_privacy_policy = UserDefaults.standard.object(forKey: "privacy_policy_seo_title") as? String else {
                print("Invalid _title_about_us")
                return
            }
            
            guard let _body_privacy_policy = UserDefaults.standard.object(forKey: "privacy_policy_page_body") as? String else {
                print("Invalid _title_about_us")
                return
            }
            
            infoCurrentTitle = _title_privacy_policy
            let htmlData = NSString(string: _body_privacy_policy).data(using: String.Encoding.unicode.rawValue)
            let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html]
            let attributedString  = try! NSAttributedString(data: htmlData!, options: options, documentAttributes: nil)
            infoCurrentBody = attributedString.string
        case 3:
            guard let _title_visitor_agreement = UserDefaults.standard.object(forKey: "visitor_agreement_seo_title") as? String else {
                print("Invalid _title_about_us")
                return
            }
            
            guard let _body_visitor_agreement = UserDefaults.standard.object(forKey: "visitor_agreement_page_body") as? String else {
                print("Invalid _title_about_us")
                return
            }
            
            infoCurrentTitle = _title_visitor_agreement
            let htmlData = NSString(string: _body_visitor_agreement).data(using: String.Encoding.unicode.rawValue)
            let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html]
            let attributedString  = try! NSAttributedString(data: htmlData!, options: options, documentAttributes: nil)
            infoCurrentBody = attributedString.string
        default:
            guard let _title_about_us = UserDefaults.standard.object(forKey: "about_us_seo_title") as? String else {
                print("Invalid _title_about_us")
                return
            }
            
            guard let _body_about_us = UserDefaults.standard.object(forKey: "about_us_page_body") as? String else {
                print("Invalid _title_about_us")
                return
            }
            
            infoCurrentTitle = _title_about_us
            let htmlData = NSString(string: _body_about_us).data(using: String.Encoding.unicode.rawValue)
            let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html]
            let attributedString  = try! NSAttributedString(data: htmlData!, options: options, documentAttributes: nil)
            infoCurrentBody = attributedString.string
        }
    }
}
